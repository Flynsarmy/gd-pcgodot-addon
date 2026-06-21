# merge_points_test.gd
class_name MergePointsTest extends GdUnitTestSuite

const FlowDataScript = preload("res://addons/flow_nodes_editor/flow_data.gd")
const MergePointsNode = preload("res://addons/flow_nodes_editor/nodes/merge_points.gd")
const MergeNodeSettings = preload("res://addons/flow_nodes_editor/nodes/merge_settings.gd")

func _make_data(streams: Dictionary) -> FlowData.Data:
	var d := FlowDataScript.Data.new()
	for stream_name in streams:
		var info = streams[stream_name]
		d.registerStream(stream_name, info[0], info[1])
	return d

# Create a minimal FlowNodeBase acting as a source with a single pre-baked output bulk.
func _make_source(data: FlowData.Data) -> FlowNodeBase:
	var src := FlowNodeBase.new()
	src.name = "source"
	src.generated_bulks = [[data]]
	src.num_generated_bulks = 1
	return src

func _run(data_inputs: Array) -> MergePointsNode:
	var node := MergePointsNode.new()
	node.name = "test_merge_points"
	node.settings = MergeNodeSettings.new()

	var ctx := FlowDataScript.EvaluationContext.new()
	var dummy := FlowGraphNode3D.new()
	ctx.owner = dummy
	ctx.gedit_nodes_by_name = {}

	node.deps = []
	var src_nodes := []
	for i in data_inputs.size():
		if data_inputs[i] == null:
			continue
		var src_name := "source_%d" % i
		var src := _make_source(data_inputs[i])
		src_nodes.append(src)
		ctx.gedit_nodes_by_name[src_name] = src
		node.deps.append({
			"from_node": src_name,
			"from_port": 0,
			"to_port": 0,
			"virtual_variable": false,
		})

	node.preExecute(ctx)
	node.run(ctx)
	dummy.free()
	for src in src_nodes:
		src.free()
	return node

func _output(node: MergePointsNode) -> FlowData.Data:
	if node.generated_bulks.is_empty():
		return null
	var bulk = node.generated_bulks[0]
	if bulk.is_empty():
		return null
	return bulk[0]

func test_no_inputs_produces_empty_output() -> void:
	var node := _run([])
	assert_str(node.err).is_empty()
	var out := _output(node)
	assert_object(out).is_not_null()
	assert_int(out.size()).is_equal(0)
	node.free()

func test_single_float_stream_passthrough() -> void:
	var data := _make_data({
		"value": [PackedFloat32Array([1.0, 2.0, 3.0]), FlowDataScript.DataType.Float]
	})
	var node := _run([data])
	assert_str(node.err).is_empty()
	var out := _output(node)
	assert_object(out).is_not_null()
	var stream := out.findStream("value")
	assert_object(stream).is_not_null()
	assert_array(stream.container).is_equal(PackedFloat32Array([1.0, 2.0, 3.0]))
	node.free()

func test_two_float_streams_concatenated() -> void:
	var data_a := _make_data({
		"value": [PackedFloat32Array([1.0, 2.0]), FlowDataScript.DataType.Float]
	})
	var data_b := _make_data({
		"value": [PackedFloat32Array([3.0, 4.0]), FlowDataScript.DataType.Float]
	})
	var node := _run([data_a, data_b])
	assert_str(node.err).is_empty()
	var out := _output(node)
	assert_object(out).is_not_null()
	assert_int(out.size()).is_equal(4)
	var stream := out.findStream("value")
	assert_object(stream).is_not_null()
	assert_array(stream.container).is_equal(PackedFloat32Array([1.0, 2.0, 3.0, 4.0]))
	node.free()

func test_two_vector_streams_concatenated() -> void:
	var data_a := _make_data({
		"position": [PackedVector3Array([Vector3(1.0, 0.0, 0.0), Vector3(2.0, 0.0, 0.0)]), FlowDataScript.DataType.Vector]
	})
	var data_b := _make_data({
		"position": [PackedVector3Array([Vector3(3.0, 0.0, 0.0)]), FlowDataScript.DataType.Vector]
	})
	var node := _run([data_a, data_b])
	assert_str(node.err).is_empty()
	var out := _output(node)
	assert_object(out).is_not_null()
	assert_int(out.size()).is_equal(3)
	var stream := out.findStream("position")
	assert_object(stream).is_not_null()
	assert_array(stream.container).is_equal(PackedVector3Array([
		Vector3(1.0, 0.0, 0.0), Vector3(2.0, 0.0, 0.0), Vector3(3.0, 0.0, 0.0)
	]))
	node.free()

func test_missing_stream_in_second_input_zero_padded() -> void:
	var data_a := _make_data({
		"x": [PackedFloat32Array([1.0, 2.0]), FlowDataScript.DataType.Float],
		"y": [PackedFloat32Array([10.0, 20.0]), FlowDataScript.DataType.Float]
	})
	var data_b := _make_data({
		"x": [PackedFloat32Array([3.0]), FlowDataScript.DataType.Float]
	})
	var node := _run([data_a, data_b])
	assert_str(node.err).is_empty()
	var out := _output(node)
	assert_object(out).is_not_null()
	assert_int(out.size()).is_equal(3)
	var x_stream := out.findStream("x")
	assert_object(x_stream).is_not_null()
	assert_array(x_stream.container).is_equal(PackedFloat32Array([1.0, 2.0, 3.0]))
	var y_stream := out.findStream("y")
	assert_object(y_stream).is_not_null()
	assert_int(y_stream.container.size()).is_equal(3)
	assert_float(y_stream.container[0]).is_equal(10.0)
	assert_float(y_stream.container[1]).is_equal(20.0)
	node.free()

func test_extra_stream_in_second_input_zero_padded_at_start() -> void:
	var data_a := _make_data({
		"x": [PackedFloat32Array([1.0]), FlowDataScript.DataType.Float]
	})
	var data_b := _make_data({
		"x": [PackedFloat32Array([2.0]), FlowDataScript.DataType.Float],
		"extra": [PackedFloat32Array([99.0]), FlowDataScript.DataType.Float]
	})
	var node := _run([data_a, data_b])
	assert_str(node.err).is_empty()
	var out := _output(node)
	assert_object(out).is_not_null()
	assert_int(out.size()).is_equal(2)
	var x_stream := out.findStream("x")
	assert_object(x_stream).is_not_null()
	assert_array(x_stream.container).is_equal(PackedFloat32Array([1.0, 2.0]))
	var extra_stream := out.findStream("extra")
	assert_object(extra_stream).is_not_null()
	assert_int(extra_stream.container.size()).is_equal(2)
	assert_float(extra_stream.container[0]).is_equal(0.0)
	assert_float(extra_stream.container[1]).is_equal(99.0)
	node.free()

func test_color_streams_concatenated() -> void:
	var data_a := _make_data({
		"color": [PackedColorArray([Color(1.0, 0.0, 0.0), Color(0.0, 1.0, 0.0)]), FlowDataScript.DataType.Color]
	})
	var data_b := _make_data({
		"color": [PackedColorArray([Color(0.0, 0.0, 1.0)]), FlowDataScript.DataType.Color]
	})
	var node := _run([data_a, data_b])
	assert_str(node.err).is_empty()
	var out := _output(node)
	assert_object(out).is_not_null()
	assert_int(out.size()).is_equal(3)
	var stream := out.findStream("color")
	assert_object(stream).is_not_null()
	assert_array(stream.container).is_equal(PackedColorArray([Color(1.0, 0.0, 0.0), Color(0.0, 1.0, 0.0), Color(0.0, 0.0, 1.0)]))
	node.free()

func test_multiple_streams_multiple_inputs_merged() -> void:
	var data_a := _make_data({
		"position": [PackedVector3Array([Vector3(0.0, 0.0, 0.0)]), FlowDataScript.DataType.Vector],
		"density": [PackedFloat32Array([1.0]), FlowDataScript.DataType.Float]
	})
	var data_b := _make_data({
		"position": [PackedVector3Array([Vector3(1.0, 1.0, 1.0), Vector3(2.0, 2.0, 2.0)]), FlowDataScript.DataType.Vector],
		"density": [PackedFloat32Array([0.5, 0.25]), FlowDataScript.DataType.Float]
	})
	var node := _run([data_a, data_b])
	assert_str(node.err).is_empty()
	var out := _output(node)
	assert_object(out).is_not_null()
	assert_int(out.size()).is_equal(3)
	var pos_stream := out.findStream("position")
	assert_object(pos_stream).is_not_null()
	assert_array(pos_stream.container).is_equal(PackedVector3Array([
		Vector3(0.0, 0.0, 0.0), Vector3(1.0, 1.0, 1.0), Vector3(2.0, 2.0, 2.0)
	]))
	var density_stream := out.findStream("density")
	assert_object(density_stream).is_not_null()
	assert_array(density_stream.container).is_equal(PackedFloat32Array([1.0, 0.5, 0.25]))
	node.free()

func test_single_element_input() -> void:
	var data := _make_data({
		"value": [PackedFloat32Array([42.0]), FlowDataScript.DataType.Float]
	})
	var node := _run([data])
	assert_str(node.err).is_empty()
	var out := _output(node)
	assert_object(out).is_not_null()
	assert_int(out.size()).is_equal(1)
	var stream := out.findStream("value")
	assert_object(stream).is_not_null()
	assert_array(stream.container).is_equal(PackedFloat32Array([42.0]))
	node.free()
