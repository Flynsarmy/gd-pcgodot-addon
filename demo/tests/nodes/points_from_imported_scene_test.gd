# points_from_imported_scene_test.gd
class_name PointsFromImportedSceneTest extends GdUnitTestSuite

const FlowDataScript = preload("res://addons/flow_nodes_editor/flow_data.gd")
const PointsFromImportedSceneNode = preload("res://addons/flow_nodes_editor/nodes/points_from_imported_scene.gd")
const PointsFromImportedSceneSettings = preload("res://addons/flow_nodes_editor/nodes/points_from_imported_scene_settings.gd")

func _run(settings) -> PointsFromImportedSceneNode:
	var node = PointsFromImportedSceneNode.new()
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

func test_empty_asset_path_sets_error() -> void:
	var s = PointsFromImportedSceneSettings.new()
	s.asset_path = ""
	var node = _run(s)
	assert_str(node.err).is_not_empty()
	node.free()

func test_nonexistent_asset_path_sets_error() -> void:
	var s = PointsFromImportedSceneSettings.new()
	s.asset_path = "res://this_scene_does_not_exist_at_all.tscn"
	var node = _run(s)
	assert_str(node.err).is_not_empty()
	node.free()

func test_settings_flags_do_not_crash_with_empty_path() -> void:
	var s = PointsFromImportedSceneSettings.new()
	s.asset_path = ""
	s.use_mesh_bounds = false
	s.include_mesh_resource = false
	s.include_source_name = false
	s.include_source_path = false
	s.fallback_size = Vector3(2.0, 2.0, 2.0)
	var node = _run(s)
	assert_str(node.err).is_not_empty()
	node.free()
