# load_pcg_data_asset_test.gd
class_name LoadPcgDataAssetTest extends GdUnitTestSuite

const FlowDataScript = preload("res://addons/flow_nodes_editor/flow_data.gd")
const LoadPcgDataAssetNode = preload("res://addons/flow_nodes_editor/nodes/load_pcg_data_asset.gd")
const LoadPcgDataAssetSettings = preload("res://addons/flow_nodes_editor/nodes/load_pcg_data_asset_settings.gd")

func _run(settings) -> LoadPcgDataAssetNode:
	var node = LoadPcgDataAssetNode.new()
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

func test_empty_path_produces_no_error() -> void:
	var s = LoadPcgDataAssetSettings.new()
	s.asset_path = ""
	var node = _run(s)
	assert_str(node.err).is_empty()
	node.free()

func test_missing_file_sets_error() -> void:
	var s = LoadPcgDataAssetSettings.new()
	s.asset_path = "res://nonexistent_file_that_does_not_exist.json"
	var node = _run(s)
	assert_str(node.err).is_not_empty()
	node.free()

func test_format_modes_with_missing_file_set_error() -> void:
	for fmt in [LoadPcgDataAssetSettings.eAssetFormat.Json, LoadPcgDataAssetSettings.eAssetFormat.Resource]:
		var s = LoadPcgDataAssetSettings.new()
		s.asset_path = "res://nonexistent_file.json"
		s.asset_format = fmt
		var node = _run(s)
		assert_str(node.err).is_not_empty()
		node.free()
