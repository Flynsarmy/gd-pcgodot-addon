# assets_test.gd
class_name AssetsTest extends GdUnitTestSuite

const FlowDataScript = preload("res://addons/flow_nodes_editor/flow_data.gd")
const AssetsNode = preload("res://addons/flow_nodes_editor/nodes/assets.gd")
const AssetsSettings = preload("res://addons/flow_nodes_editor/nodes/assets_settings.gd")

func _run(settings) -> AssetsNode:
	var node = AssetsNode.new()
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

func test_empty_assets_no_crash() -> void:
	var s = AssetsSettings.new()
	s.assets = []
	var node = _run(s)
	assert_str(node.err).is_empty()
	node.free()

func test_null_asset_entries_no_crash() -> void:
	var s = AssetsSettings.new()
	s.assets = [null, null]
	var node = _run(s)
	assert_str(node.err).is_empty()
	node.free()

func test_trace_flag_does_not_crash() -> void:
	var s = AssetsSettings.new()
	s.assets = []
	s.trace = true
	var node = _run(s)
	assert_str(node.err).is_empty()
	node.free()
