# scan_nodes_test.gd
class_name ScanNodesTest extends GdUnitTestSuite

const FlowDataScript = preload("res://addons/flow_nodes_editor/flow_data.gd")
const ScanNodesNode = preload("res://addons/flow_nodes_editor/nodes/scan_nodes.gd")
const ScanNodesSettings = preload("res://addons/flow_nodes_editor/nodes/scan_nodes_settings.gd")

func _run(settings) -> ScanNodesNode:
	var node = ScanNodesNode.new()
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

func _output(node) -> FlowData.Data:
	if node.generated_bulks.is_empty(): return null
	var bulk = node.generated_bulks[0]
	if bulk.is_empty(): return null
	return bulk[0]

func test_null_owner_does_not_crash() -> void:
	var s = ScanNodesSettings.new()
	var node = ScanNodesNode.new()
	node.name = "test_node"
	node.settings = s
	node.inputs = []
	var ctx = FlowDataScript.EvaluationContext.new()
	ctx.owner = null
	node.preExecute(ctx)
	node.execute(ctx)
	var out = _output(node)
	assert_object(out).is_not_null()
	node.free()

func test_empty_scene_no_error() -> void:
	var s = ScanNodesSettings.new()
	var node = _run(s)
	assert_str(node.err).is_empty()
	var out = _output(node)
	assert_object(out).is_not_null()
	node.free()

func test_extra_settings_do_not_crash() -> void:
	var s = ScanNodesSettings.new()
	s.import_metadata = true
	s.size_to_bounds = true
	s.filter_by_name = "*"
	s.filter_by_class_name = "Node3D"
	s.recursive = true
	var node = _run(s)
	assert_str(node.err).is_empty()
	node.free()
