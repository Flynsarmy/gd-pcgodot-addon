# ray_cast_test.gd
class_name RayCastTest extends GdUnitTestSuite

const FlowDataScript = preload("res://addons/flow_nodes_editor/flow_data.gd")
const RayCastNode = preload("res://addons/flow_nodes_editor/nodes/ray_cast.gd")
const RayCastSettings = preload("res://addons/flow_nodes_editor/nodes/ray_cast_settings.gd")

func _make_data(stream_name: String, values, dtype: int) -> FlowData.Data:
	var d := FlowDataScript.Data.new()
	d.registerStream(stream_name, values, dtype)
	return d

func _run(inputs: Array, settings) -> RayCastNode:
	var node = RayCastNode.new()
	node.name = "test_node"
	node.settings = settings
	node.inputs = inputs
	var ctx = FlowDataScript.EvaluationContext.new()
	var dummy = FlowGraphNode3D.new()
	ctx.owner = dummy
	node.preExecute(ctx)
	node.execute(ctx)
	dummy.free()
	return node

func test_null_input_sets_error() -> void:
	var s = RayCastSettings.new()
	var node = _run([null], s)
	assert_str(node.err).is_not_empty()
	node.free()

func test_missing_position_stream_sets_error() -> void:
	var s = RayCastSettings.new()
	s.from_attribute = "position"
	var d = _make_data("color", PackedFloat32Array([1.0]), FlowDataScript.DataType.Float)
	var node = _run([d], s)
	assert_str(node.err).is_not_empty()
	node.free()

func test_direction_mode_from_attribute_missing_stream_sets_error() -> void:
	var s = RayCastSettings.new()
	s.direction_mode = RayCastSettings.eDirectionMode.FromAttribute
	s.direction_attribute = "direction"
	s.from_attribute = "position"
	var d = _make_data("position", PackedVector3Array([Vector3.ZERO]), FlowDataScript.DataType.Vector)
	var node = _run([d], s)
	assert_str(node.err).is_not_empty()
	node.free()
