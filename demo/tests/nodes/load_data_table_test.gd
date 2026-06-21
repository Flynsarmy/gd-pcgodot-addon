# load_data_table_test.gd
class_name LoadDataTableTest extends GdUnitTestSuite

const FlowDataScript = preload("res://addons/flow_nodes_editor/flow_data.gd")
const LoadDataTableNode = preload("res://addons/flow_nodes_editor/nodes/load_data_table.gd")
const LoadDataTableSettings = preload("res://addons/flow_nodes_editor/nodes/load_data_table_settings.gd")

func _run(settings) -> LoadDataTableNode:
	var node = LoadDataTableNode.new()
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
	var s = LoadDataTableSettings.new()
	s.table_path = ""
	var node = _run(s)
	assert_str(node.err).is_empty()
	node.free()

func test_missing_file_sets_error() -> void:
	var s = LoadDataTableSettings.new()
	s.table_path = "res://this_file_does_not_exist_ever.csv"
	var node = _run(s)
	assert_str(node.err).is_not_empty()
	node.free()

func test_delimiter_modes_do_not_crash_with_empty_path() -> void:
	var s = LoadDataTableSettings.new()
	s.table_path = ""
	for delimiter in [
		LoadDataTableSettings.eDelimiter.Comma,
		LoadDataTableSettings.eDelimiter.Tab,
		LoadDataTableSettings.eDelimiter.Semicolon,
		LoadDataTableSettings.eDelimiter.Pipe,
	]:
		s.delimiter = delimiter
		var node = _run(s)
		assert_str(node.err).is_empty()
		node.free()
