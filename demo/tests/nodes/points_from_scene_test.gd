# points_from_scene_test.gd
class_name PointsFromSceneTest extends GdUnitTestSuite

const FlowDataScript = preload("res://addons/flow_nodes_editor/flow_data.gd")
const PointsFromSceneNode = preload("res://addons/flow_nodes_editor/nodes/points_from_scene.gd")
const PointsFromSceneSettings = preload("res://addons/flow_nodes_editor/nodes/points_from_scene_settings.gd")

func _run(settings) -> PointsFromSceneNode:
	var node = PointsFromSceneNode.new()
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

func test_null_owner_does_not_crash() -> void:
	var s = PointsFromSceneSettings.new()
	var node = PointsFromSceneNode.new()
	node.name = "test_node"
	node.settings = s
	node.inputs = []
	var ctx = FlowDataScript.EvaluationContext.new()
	ctx.owner = null
	node.preExecute(ctx)
	node.execute(ctx)
	assert_str(node.err).is_empty()
	node.free()

func test_empty_scene_produces_zero_points() -> void:
	var s = PointsFromSceneSettings.new()
	var node = _run(s)
	assert_str(node.err).is_empty()
	assert_bool(node.generated_bulks.is_empty()).is_false()
	var bulk = node.generated_bulks[0]
	assert_bool(bulk.is_empty()).is_false()
	var out : FlowData.Data = bulk[0]
	assert_object(out).is_not_null()
	var pos_stream = out.findStream(FlowData.AttrPosition)
	assert_object(pos_stream).is_not_null()
	assert_int(pos_stream.container.size()).is_equal(0)
	node.free()

func test_settings_flags_do_not_crash() -> void:
	var s = PointsFromSceneSettings.new()
	s.recursive = false
	s.import_metadata = true
	s.size_to_bounds = true
	var node = _run(s)
	assert_str(node.err).is_empty()
	node.free()
