# scan_meshes_test.gd
class_name ScanMeshesTest extends GdUnitTestSuite

const FlowDataScript = preload("res://addons/flow_nodes_editor/flow_data.gd")
const ScanMeshesNode = preload("res://addons/flow_nodes_editor/nodes/scan_meshes.gd")
const ScanMeshesSettings = preload("res://addons/flow_nodes_editor/nodes/scan_meshes_settings.gd")

func _run(settings) -> ScanMeshesNode:
	var node = ScanMeshesNode.new()
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
	var s = ScanMeshesSettings.new()
	var node = ScanMeshesNode.new()
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

func test_empty_scene_produces_output_no_error() -> void:
	var s = ScanMeshesSettings.new()
	var node = _run(s)
	assert_str(node.err).is_empty()
	var out = _output(node)
	assert_object(out).is_not_null()
	var node_stream = out.findStream("node")
	assert_object(node_stream).is_not_null()
	var mesh_stream = out.findStream("mesh")
	assert_object(mesh_stream).is_not_null()
	node.free()

func test_extra_settings_do_not_crash() -> void:
	var s = ScanMeshesSettings.new()
	s.group_name = "nonexistent_group"
	s.required_meta_bool = &"some_meta"
	s.recursive = false
	var node = _run(s)
	assert_str(node.err).is_empty()
	node.free()
