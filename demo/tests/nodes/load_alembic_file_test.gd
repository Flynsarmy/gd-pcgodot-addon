# load_alembic_file_test.gd
class_name LoadAlembicFileTest extends GdUnitTestSuite

const FlowDataScript = preload("res://addons/flow_nodes_editor/flow_data.gd")
const LoadAlembicFileNode = preload("res://addons/flow_nodes_editor/nodes/load_alembic_file.gd")
const LoadAlembicFileSettings = preload("res://addons/flow_nodes_editor/nodes/points_from_imported_scene_settings.gd")

func _run(settings) -> LoadAlembicFileNode:
	var node = LoadAlembicFileNode.new()
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
	var s = LoadAlembicFileSettings.new()
	s.asset_path = ""
	var node = _run(s)
	assert_str(node.err).is_not_empty()
	node.free()

func test_nonexistent_asset_path_sets_error() -> void:
	var s = LoadAlembicFileSettings.new()
	s.asset_path = "res://nonexistent_file_that_does_not_exist.abc"
	var node = _run(s)
	assert_str(node.err).is_not_empty()
	node.free()

func test_toggle_optional_streams_no_crash() -> void:
	var s = LoadAlembicFileSettings.new()
	s.asset_path = ""
	s.include_mesh_resource = false
	s.include_source_name = false
	s.include_source_path = false
	var node = _run(s)
	assert_str(node.err).is_not_empty()
	node.free()
