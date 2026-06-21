# point_from_player_pawn_test.gd
class_name PointFromPlayerPawnTest extends GdUnitTestSuite

const FlowDataScript = preload("res://addons/flow_nodes_editor/flow_data.gd")
const PointFromPlayerPawnNode = preload("res://addons/flow_nodes_editor/nodes/point_from_player_pawn.gd")
const PointFromPlayerPawnSettings = preload("res://addons/flow_nodes_editor/nodes/point_from_player_pawn_settings.gd")

func _run(settings) -> PointFromPlayerPawnNode:
	var node = PointFromPlayerPawnNode.new()
	node.name = "test_node"
	node.settings = settings
	node.inputs = []
	var ctx = FlowDataScript.EvaluationContext.new()
	var dummy = FlowGraphNode3D.new()
	ctx.owner = dummy
	node.preExecute(ctx)
	node.execute(ctx)
	dummy.free()
	return node

func test_no_scene_sets_error() -> void:
	var s = PointFromPlayerPawnSettings.new()
	var node = _run(s)
	assert_str(node.err).is_not_empty()
	node.free()

func test_fallback_camera_enabled_still_errors_headless() -> void:
	var s = PointFromPlayerPawnSettings.new()
	s.fallback_to_current_camera = true
	var node = _run(s)
	assert_str(node.err).is_not_empty()
	node.free()

func test_include_node_ref_false_still_errors_headless() -> void:
	var s = PointFromPlayerPawnSettings.new()
	s.include_node_ref = false
	var node = _run(s)
	assert_str(node.err).is_not_empty()
	node.free()
