# attribute_noise_test.gd
class_name AttributeNoiseTest extends GdUnitTestSuite

const FlowDataScript = preload("res://addons/flow_nodes_editor/flow_data.gd")
const AttributeNoiseNode = preload("res://addons/flow_nodes_editor/nodes/attribute_noise.gd")
const AttributeNoiseSettings = preload("res://addons/flow_nodes_editor/nodes/attribute_noise_settings.gd")

func _make_data(stream_name: String, values, dtype: int) -> FlowData.Data:
	var d := FlowDataScript.Data.new()
	d.registerStream(stream_name, values, dtype)
	return d

func _run(input: FlowData.Data, s: AttributeNoiseNodeSettings) -> AttributeNoiseNode:
	var node = AttributeNoiseNode.new()
	node.name = "test_attr_noise"
	node.settings = s
	node.inputs = [input]
	var ctx = FlowDataScript.EvaluationContext.new()
	var dummy = FlowGraphNode3D.new()
	ctx.owner = dummy
	node.preExecute(ctx)
	node.execute(ctx)
	dummy.free()
	return node

func _output(node: AttributeNoiseNode) -> FlowData.Data:
	if node.generated_bulks.is_empty():
		return null
	var bulk = node.generated_bulks[0]
	if bulk.is_empty():
		return null
	return bulk[0]

func test_set_mode_creates_attribute() -> void:
	var s = AttributeNoiseSettings.new()
	s.target_attribute = "density"
	s.mode = AttributeNoiseSettings.eMode.Set
	s.noise_min = 0.5
	s.noise_max = 0.5
	s.clamp_result = false
	var input = FlowDataScript.Data.new()
	input.registerStream("position", PackedVector3Array([Vector3.ZERO, Vector3.ONE, Vector3(2, 0, 0)]), FlowDataScript.DataType.Vector)
	var node = _run(input, s)
	assert_str(node.err).is_empty()
	var out = _output(node)
	assert_object(out).is_not_null()
	var stream = out.findStream("density")
	assert_object(stream).is_not_null()
	assert_int(stream.container.size()).is_equal(3)
	for i in range(3):
		assert_float(stream.container[i]).is_equal_approx(0.5, 0.0001)
	node.free()

func test_add_mode_with_existing_float_attribute() -> void:
	var s = AttributeNoiseSettings.new()
	s.target_attribute = "density"
	s.mode = AttributeNoiseSettings.eMode.Add
	s.noise_min = 0.1
	s.noise_max = 0.1
	s.clamp_result = false
	var input = _make_data("density", PackedFloat32Array([0.5, 0.3, 0.8]), FlowDataScript.DataType.Float)
	var node = _run(input, s)
	assert_str(node.err).is_empty()
	var out = _output(node)
	assert_object(out).is_not_null()
	var stream = out.findStream("density")
	assert_object(stream).is_not_null()
	assert_float(stream.container[0]).is_equal_approx(0.6, 0.0001)
	assert_float(stream.container[1]).is_equal_approx(0.4, 0.0001)
	assert_float(stream.container[2]).is_equal_approx(0.9, 0.0001)
	node.free()

func test_multiply_mode_with_existing_float_attribute() -> void:
	var s = AttributeNoiseSettings.new()
	s.target_attribute = "density"
	s.mode = AttributeNoiseSettings.eMode.Multiply
	s.noise_min = 0.5
	s.noise_max = 0.5
	s.clamp_result = false
	var input = _make_data("density", PackedFloat32Array([0.4, 1.0, 0.0]), FlowDataScript.DataType.Float)
	var node = _run(input, s)
	assert_str(node.err).is_empty()
	var out = _output(node)
	assert_object(out).is_not_null()
	var stream = out.findStream("density")
	assert_object(stream).is_not_null()
	assert_float(stream.container[0]).is_equal_approx(0.2, 0.0001)
	assert_float(stream.container[1]).is_equal_approx(0.5, 0.0001)
	assert_float(stream.container[2]).is_equal_approx(0.0, 0.0001)
	node.free()

func test_minimum_and_maximum_modes() -> void:
	var s = AttributeNoiseSettings.new()
	s.target_attribute = "density"
	s.noise_min = 0.6
	s.noise_max = 0.6
	s.clamp_result = false
	var input = _make_data("density", PackedFloat32Array([0.3, 0.9]), FlowDataScript.DataType.Float)

	s.mode = AttributeNoiseSettings.eMode.Minimum
	var node = _run(input, s)
	assert_str(node.err).is_empty()
	var out = _output(node)
	var stream = out.findStream("density")
	assert_float(stream.container[0]).is_equal_approx(0.3, 0.0001)
	assert_float(stream.container[1]).is_equal_approx(0.6, 0.0001)
	node.free()

	s.mode = AttributeNoiseSettings.eMode.Maximum
	node = _run(input, s)
	assert_str(node.err).is_empty()
	out = _output(node)
	stream = out.findStream("density")
	assert_float(stream.container[0]).is_equal_approx(0.6, 0.0001)
	assert_float(stream.container[1]).is_equal_approx(0.9, 0.0001)
	node.free()

func test_invert_source_flag() -> void:
	var s = AttributeNoiseSettings.new()
	s.target_attribute = "density"
	s.mode = AttributeNoiseSettings.eMode.Add
	s.noise_min = 0.0
	s.noise_max = 0.0
	s.invert_source = true
	s.clamp_result = false
	var input = _make_data("density", PackedFloat32Array([0.3, 0.7]), FlowDataScript.DataType.Float)
	var node = _run(input, s)
	assert_str(node.err).is_empty()
	var out = _output(node)
	assert_object(out).is_not_null()
	var stream = out.findStream("density")
	assert_object(stream).is_not_null()
	assert_float(stream.container[0]).is_equal_approx(0.7, 0.0001)
	assert_float(stream.container[1]).is_equal_approx(0.3, 0.0001)
	node.free()

func test_clamp_result_flag() -> void:
	var s = AttributeNoiseSettings.new()
	s.target_attribute = "density"
	s.mode = AttributeNoiseSettings.eMode.Add
	s.noise_min = 0.8
	s.noise_max = 0.8
	s.clamp_result = true
	var input = _make_data("density", PackedFloat32Array([0.5, 0.1]), FlowDataScript.DataType.Float)
	var node = _run(input, s)
	assert_str(node.err).is_empty()
	var out = _output(node)
	assert_object(out).is_not_null()
	var stream = out.findStream("density")
	assert_object(stream).is_not_null()
	assert_float(stream.container[0]).is_equal_approx(1.0, 0.0001)
	assert_float(stream.container[1]).is_equal_approx(0.9, 0.0001)
	node.free()

func test_int_source_attribute_is_converted_to_float() -> void:
	var s = AttributeNoiseSettings.new()
	s.target_attribute = "my_int_attr"
	s.mode = AttributeNoiseSettings.eMode.Add
	s.noise_min = 0.0
	s.noise_max = 0.0
	s.clamp_result = false
	var input = _make_data("my_int_attr", PackedInt32Array([2, 5]), FlowDataScript.DataType.Int)
	var node = _run(input, s)
	assert_str(node.err).is_empty()
	var out = _output(node)
	assert_object(out).is_not_null()
	var stream = out.findStream("my_int_attr")
	assert_object(stream).is_not_null()
	assert_int(stream.data_type).is_equal(FlowDataScript.DataType.Float)
	assert_float(stream.container[0]).is_equal_approx(2.0, 0.0001)
	assert_float(stream.container[1]).is_equal_approx(5.0, 0.0001)
	node.free()

func test_missing_attribute_defaults_for_density_and_custom() -> void:
	var s = AttributeNoiseSettings.new()
	s.noise_min = 0.25
	s.noise_max = 0.25
	s.clamp_result = false

	s.target_attribute = "density"
	s.mode = AttributeNoiseSettings.eMode.Add
	var input = FlowDataScript.Data.new()
	input.registerStream("position", PackedVector3Array([Vector3.ZERO, Vector3.ONE]), FlowDataScript.DataType.Vector)
	var node = _run(input, s)
	assert_str(node.err).is_empty()
	var out = _output(node)
	assert_object(out).is_not_null()
	var stream = out.findStream("density")
	assert_object(stream).is_not_null()
	assert_float(stream.container[0]).is_equal_approx(1.25, 0.0001)
	assert_float(stream.container[1]).is_equal_approx(1.25, 0.0001)
	node.free()

	s.target_attribute = "custom_attr"
	s.mode = AttributeNoiseSettings.eMode.Add
	var input2 = FlowDataScript.Data.new()
	input2.registerStream("position", PackedVector3Array([Vector3.ZERO, Vector3.ONE]), FlowDataScript.DataType.Vector)
	node = _run(input2, s)
	assert_str(node.err).is_empty()
	out = _output(node)
	assert_object(out).is_not_null()
	stream = out.findStream("custom_attr")
	assert_object(stream).is_not_null()
	assert_float(stream.container[0]).is_equal_approx(0.25, 0.0001)
	assert_float(stream.container[1]).is_equal_approx(0.25, 0.0001)
	node.free()

func test_empty_input_passes_through() -> void:
	var s = AttributeNoiseSettings.new()
	s.target_attribute = "density"
	s.mode = AttributeNoiseSettings.eMode.Set
	s.noise_min = 0.5
	s.noise_max = 0.5
	var input = FlowDataScript.Data.new()
	var node = _run(input, s)
	assert_str(node.err).is_empty()
	var out = _output(node)
	assert_object(out).is_not_null()
	node.free()

func test_missing_input_error() -> void:
	var s = AttributeNoiseSettings.new()
	s.target_attribute = "density"
	var node = AttributeNoiseNode.new()
	node.name = "test_attr_noise_missing"
	node.settings = s
	node.inputs = []
	var ctx = FlowDataScript.EvaluationContext.new()
	var dummy = FlowGraphNode3D.new()
	ctx.owner = dummy
	node.preExecute(ctx)
	node.execute(ctx)
	dummy.free()
	assert_str(node.err).is_not_empty()
	node.free()

func test_empty_target_attribute_error() -> void:
	var s = AttributeNoiseSettings.new()
	s.target_attribute = "   "
	s.mode = AttributeNoiseSettings.eMode.Set
	var input = _make_data("density", PackedFloat32Array([0.5]), FlowDataScript.DataType.Float)
	var node = _run(input, s)
	assert_str(node.err).is_not_empty()
	node.free()

func test_non_numeric_attribute_type_error() -> void:
	var s = AttributeNoiseSettings.new()
	s.target_attribute = "tag"
	s.mode = AttributeNoiseSettings.eMode.Set
	s.noise_min = 0.5
	s.noise_max = 0.5
	var input = _make_data("tag", PackedStringArray(["hello"]), FlowDataScript.DataType.String)
	var node = _run(input, s)
	assert_str(node.err).is_not_empty()
	node.free()

func test_deterministic_with_seed_stream() -> void:
	var s = AttributeNoiseSettings.new()
	s.target_attribute = "density"
	s.mode = AttributeNoiseSettings.eMode.Set
	s.noise_min = 0.0
	s.noise_max = 1.0
	s.clamp_result = false
	s.random_seed = 42

	var input1 = FlowDataScript.Data.new()
	input1.registerStream("position", PackedVector3Array([Vector3.ZERO, Vector3.ONE, Vector3(2, 0, 0)]), FlowDataScript.DataType.Vector)
	input1.registerStream(FlowData.AttrSeed, PackedInt32Array([100, 200, 300]), FlowDataScript.DataType.Int)

	var input2 = FlowDataScript.Data.new()
	input2.registerStream("position", PackedVector3Array([Vector3.ZERO, Vector3.ONE, Vector3(2, 0, 0)]), FlowDataScript.DataType.Vector)
	input2.registerStream(FlowData.AttrSeed, PackedInt32Array([100, 200, 300]), FlowDataScript.DataType.Int)

	var node1 = _run(input1, s)
	var node2 = _run(input2, s)
	assert_str(node1.err).is_empty()
	assert_str(node2.err).is_empty()
	var out1 = _output(node1)
	var out2 = _output(node2)
	var stream1 = out1.findStream("density")
	var stream2 = out2.findStream("density")
	assert_array(stream1.container).is_equal(stream2.container)
	node1.free()
	node2.free()
