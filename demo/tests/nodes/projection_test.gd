# projection_test.gd
class_name ProjectionTest extends GdUnitTestSuite

const FlowDataScript = preload("res://addons/flow_nodes_editor/flow_data.gd")
const ProjectionNode = preload("res://addons/flow_nodes_editor/nodes/projection.gd")
const ProjectionSettings = preload("res://addons/flow_nodes_editor/nodes/projection_settings.gd")

func _make_data(stream_name: String, values, dtype: int) -> FlowData.Data:
	var d := FlowDataScript.Data.new()
	d.registerStream(stream_name, values, dtype)
	return d

func _run(inputs: Array, settings) -> ProjectionNode:
	var node = ProjectionNode.new()
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
	var s = ProjectionSettings.new()
	var node = _run([null], s)
	assert_str(node.err).is_not_empty()
	node.free()

func test_no_world_sets_error() -> void:
	var s = ProjectionSettings.new()
	var positions = PackedVector3Array([Vector3(0, 10, 0), Vector3(5, 10, 5)])
	var in_data = _make_data(FlowData.AttrPosition, positions, FlowDataScript.DataType.Vector)
	var node = _run([in_data], s)
	assert_str(node.err).is_not_empty()
	node.free()

func test_align_to_normal_toggle_no_crash() -> void:
	var s = ProjectionSettings.new()
	s.align_to_normal = false
	s.discard_misses = true
	var positions = PackedVector3Array([Vector3(0, 10, 0)])
	var in_data = _make_data(FlowData.AttrPosition, positions, FlowDataScript.DataType.Vector)
	var node = _run([in_data], s)
	assert_str(node.err).is_not_empty()
	node.free()
