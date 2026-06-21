# point_from_mesh_test.gd
class_name PointFromMeshTest extends GdUnitTestSuite

const FlowDataScript = preload("res://addons/flow_nodes_editor/flow_data.gd")
const PointFromMeshNode = preload("res://addons/flow_nodes_editor/nodes/point_from_mesh.gd")
const PointFromMeshSettings = preload("res://addons/flow_nodes_editor/nodes/point_from_mesh_settings.gd")

func _run(inputs: Array, settings) -> PointFromMeshNode:
	var node = PointFromMeshNode.new()
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
	var s = PointFromMeshSettings.new()
	var node = _run([null], s)
	assert_str(node.err).is_not_empty()
	node.free()

func test_missing_node_mesh_stream_sets_error() -> void:
	var s = PointFromMeshSettings.new()
	s.source_stream_name = "node"
	var d := FlowDataScript.Data.new()
	d.registerStream("positions", PackedVector3Array([Vector3.ZERO]), FlowDataScript.DataType.Vector)
	var node = _run([d], s)
	assert_str(node.err).is_not_empty()
	node.free()

func test_settings_toggle_does_not_crash_with_empty_input() -> void:
	var s = PointFromMeshSettings.new()
	s.include_mesh_attribute = false
	s.use_world_scale_for_bounds = false
	var node = _run([null], s)
	assert_str(node.err).is_not_empty()
	node.free()
