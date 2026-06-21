# scan_splines_test.gd
class_name ScanSplinesTest extends GdUnitTestSuite

const FlowDataScript = preload("res://addons/flow_nodes_editor/flow_data.gd")
const ScanSplinesNode = preload("res://addons/flow_nodes_editor/nodes/scan_splines.gd")
const ScanSplinesSettings = preload("res://addons/flow_nodes_editor/nodes/scan_splines_settings.gd")

func _run(settings) -> ScanSplinesNode:
	var node = ScanSplinesNode.new()
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
	var s = ScanSplinesSettings.new()
	var node = ScanSplinesNode.new()
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
	var s = ScanSplinesSettings.new()
	var node = _run(s)
	assert_str(node.err).is_empty()
	var out = _output(node)
	assert_object(out).is_not_null()
	node.free()

func test_settings_variants_do_not_crash() -> void:
	var s = ScanSplinesSettings.new()
	s.recursive = false
	s.group_name = "splines"
	s.required_meta_bool = &"pcg_spline"
	var node = _run(s)
	assert_str(node.err).is_empty()
	node.free()
