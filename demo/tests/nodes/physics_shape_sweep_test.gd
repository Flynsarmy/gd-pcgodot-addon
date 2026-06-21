# physics_shape_sweep_test.gd
class_name PhysicsShapeSweepTest extends GdUnitTestSuite

const FlowDataScript = preload("res://addons/flow_nodes_editor/flow_data.gd")
const PhysicsShapeSweepNode = preload("res://addons/flow_nodes_editor/nodes/physics_shape_sweep.gd")
const PhysicsShapeSweepSettings = preload("res://addons/flow_nodes_editor/nodes/physics_shape_sweep_settings.gd")

func _run(inputs: Array, settings) -> PhysicsShapeSweepNode:
	var node = PhysicsShapeSweepNode.new()
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
	var s = PhysicsShapeSweepSettings.new()
	var node = _run([null], s)
	assert_str(node.err).is_not_empty()
	node.free()

func test_no_scene_root_sets_error() -> void:
	var s = PhysicsShapeSweepSettings.new()
	s.position_attribute = "position"
	var d := FlowDataScript.Data.new()
	d.registerStream("position", PackedVector3Array([Vector3(0, 0, 0)]), FlowDataScript.DataType.Vector)
	var node = _run([d], s)
	assert_str(node.err).is_not_empty()
	node.free()

func test_box_shape_and_from_attribute_mode_no_crash() -> void:
	var s = PhysicsShapeSweepSettings.new()
	s.shape_type = PhysicsShapeSweepSettings.eShapeType.Box
	s.direction_mode = PhysicsShapeSweepSettings.eDirectionMode.FromAttribute
	s.direction_attribute = "dir"
	s.position_attribute = "position"
	var d := FlowDataScript.Data.new()
	d.registerStream("position", PackedVector3Array([Vector3(0, 0, 0)]), FlowDataScript.DataType.Vector)
	var node = _run([d], s)
	assert_str(node.err).is_not_empty()
	node.free()
