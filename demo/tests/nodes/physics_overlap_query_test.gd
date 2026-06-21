# physics_overlap_query_test.gd
class_name PhysicsOverlapQueryTest extends GdUnitTestSuite

const FlowDataScript = preload("res://addons/flow_nodes_editor/flow_data.gd")
const PhysicsOverlapQueryNode = preload("res://addons/flow_nodes_editor/nodes/physics_overlap_query.gd")
const PhysicsOverlapQuerySettings = preload("res://addons/flow_nodes_editor/nodes/physics_overlap_query_settings.gd")

func _make_data(stream_name: String, values, dtype: int) -> FlowData.Data:
	var d := FlowDataScript.Data.new()
	d.registerStream(stream_name, values, dtype)
	return d

func _run(inputs: Array, settings) -> PhysicsOverlapQueryNode:
	var node = PhysicsOverlapQueryNode.new()
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

func test_no_scene_root_sets_error() -> void:
	var s = PhysicsOverlapQuerySettings.new()
	s.position_attribute = "position"
	var d := FlowDataScript.Data.new()
	d.registerStream("position", PackedVector3Array([Vector3.ZERO]), FlowDataScript.DataType.Vector)
	var node = PhysicsOverlapQueryNode.new()
	node.name = "test_node"
	node.settings = s
	node.inputs = [d]
	var ctx = FlowDataScript.EvaluationContext.new()
	ctx.owner = null
	node.preExecute(ctx)
	node.execute(ctx)
	assert_str(node.err).is_not_empty()
	node.free()

func test_missing_position_stream_sets_error() -> void:
	var s = PhysicsOverlapQuerySettings.new()
	s.position_attribute = "position"
	var d := FlowDataScript.Data.new()
	d.registerStream("other", PackedFloat32Array([1.0]), FlowDataScript.DataType.Float)
	var node = _run([d], s)
	assert_str(node.err).is_not_empty()
	node.free()

func test_box_shape_mode_missing_position_sets_error() -> void:
	var s = PhysicsOverlapQuerySettings.new()
	s.shape_type = PhysicsOverlapQuerySettings.eShapeType.Box
	s.position_attribute = "position"
	var d := FlowDataScript.Data.new()
	d.registerStream("other", PackedFloat32Array([1.0]), FlowDataScript.DataType.Float)
	var node = _run([d], s)
	assert_str(node.err).is_not_empty()
	node.free()
