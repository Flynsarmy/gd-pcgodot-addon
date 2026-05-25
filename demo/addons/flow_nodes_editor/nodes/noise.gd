@tool
extends FlowNodeBase

func _init():
	meta_node = {
		"title" : "Noise",
		"settings" : NoiseNodeSettings,
		"ins" : [{ "label" : "In" }],
		"outs" : [{ "label" : "Out" }],
		"tooltip" : "Outputs an attribute with Noise values",
	}

func execute( _ctx : FlowData.EvaluationContext ):
	var in_data : FlowData.Data = get_input(0)
	var out_data : FlowData.Data = in_data.duplicate()
		
	var ipos : PackedVector3Array = out_data.getContainerChecked( FlowData.AttrPosition, FlowData.DataType.Vector )
	if ipos == null:
		return
		
	var noise := FastNoiseLite.new()
	noise.seed = settings.random_seed
	noise.noise_type = FastNoiseLite.NoiseType.TYPE_VALUE
	#noise.cellular_distance_function = FastNoiseLite.CellularDistanceFunction.DISTANCE_EUCLIDEAN
	#noise.cellular_return_type = FastNoiseLite.CellularReturnType.RETURN_DISTANCE
	
	var in_scale : float = settings.in_scale
	var noise_bias : float = settings.noise_bias
	var noise_amplitude : float = settings.noise_amplitude
	
	var in_size := in_data.size()
	
	var target_exists := false
	var existing_stream = out_data.findStream(settings.out_name)
	if existing_stream != null and settings.mode == NoiseNodeSettings.eMode.Add:
		target_exists = true

	var out_container
	
	if settings.output_type == NoiseNodeSettings.eOutputType.Vector3:
		var sout_generated := PackedVector3Array()
		sout_generated.resize(in_size)
		for i in range(in_size):
			var pos := ipos[i] * in_scale
			var raw_x := noise.get_noise_3d(pos.x, pos.y, pos.z)
			var raw_y := noise.get_noise_3d(pos.x + 100.0, pos.y + 100.0, pos.z + 100.0)
			var raw_z := noise.get_noise_3d(pos.x + 200.0, pos.y + 200.0, pos.z + 200.0)
			
			var val_x := noise_bias + clampf((raw_x + 1.0) * 0.5, 0.0, 1.0) * noise_amplitude
			var val_y := noise_bias + clampf((raw_y + 1.0) * 0.5, 0.0, 1.0) * noise_amplitude
			var val_z := noise_bias + clampf((raw_z + 1.0) * 0.5, 0.0, 1.0) * noise_amplitude
			
			sout_generated[i] = Vector3(val_x, val_y, val_z)
			
		if target_exists:
			var existing_container = existing_stream.container
			if existing_stream.data_type == FlowData.DataType.Vector:
				var out_vec := PackedVector3Array()
				out_vec.resize(in_size)
				for i in range(in_size):
					out_vec[i] = existing_container[i] + sout_generated[i]
				out_container = out_vec
			elif existing_stream.data_type == FlowData.DataType.Float:
				var out_vec := PackedVector3Array()
				out_vec.resize(in_size)
				for i in range(in_size):
					out_vec[i] = Vector3(existing_container[i], existing_container[i], existing_container[i]) + sout_generated[i]
				out_container = out_vec
			else:
				out_container = sout_generated
		else:
			out_container = sout_generated
	else:
		var sout_generated := PackedFloat32Array()
		sout_generated.resize(in_size)
		for i in range(in_size):
			var pos := ipos[i] * in_scale
			var raw_noise := noise.get_noise_3d(pos.x, pos.y, pos.z)
			var noise_01 := (raw_noise + 1.0) * 0.5
			var nval := clampf(noise_01, 0.0, 1.0)
			sout_generated[i] = noise_bias + nval * noise_amplitude
			
		if target_exists:
			var existing_container = existing_stream.container
			if existing_stream.data_type == FlowData.DataType.Float:
				var out_floats := PackedFloat32Array()
				out_floats.resize(in_size)
				for i in range(in_size):
					out_floats[i] = existing_container[i] + sout_generated[i]
				out_container = out_floats
			elif existing_stream.data_type == FlowData.DataType.Vector:
				var out_vec := PackedVector3Array()
				out_vec.resize(in_size)
				for i in range(in_size):
					out_vec[i] = existing_container[i] + Vector3(sout_generated[i], sout_generated[i], sout_generated[i])
				out_container = out_vec
			else:
				out_container = sout_generated
		else:
			out_container = sout_generated
			
	var err = out_data.registerStream(settings.out_name, out_container)
	if err:
		setError(err)
		return
		
	set_output(0, out_data)
