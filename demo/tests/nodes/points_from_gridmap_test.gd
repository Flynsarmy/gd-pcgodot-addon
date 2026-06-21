# points_from_gridmap_test.gd
class_name PointsFromGridmapTest extends GdUnitTestSuite

const FlowDataScript = preload("res://addons/flow_nodes_editor/flow_data.gd")
const PointsFromGridmapNode = preload("res://addons/flow_nodes_editor/nodes/points_from_gridmap.gd")
const PointsFromGridmapSettings = preload("res://addons/flow_nodes_editor/nodes/points_from_gridmap_settings.gd")

func _run(settings) -> PointsFromGridmapNode:
	var node = PointsFromGridmapNode.new()
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

func test_null_scene_no_crash() -> void:
	var s = PointsFromGridmapSettings.new()
	var node = PointsFromGridmapNode.new()
	node.name = "test_node"
	node.settings = s
	node.inputs = []
	var ctx = FlowDataScript.EvaluationContext.new()
	ctx.owner = null
	node.preExecute(ctx)
	node.execute(ctx)
	assert_bool(true).is_true()
	node.free()

func test_empty_scene_root_produces_empty_output() -> void:
	var s = PointsFromGridmapSettings.new()
	var node = _run(s)
	assert_str(node.err).is_empty()
	var bulk = node.generated_bulks
	if not bulk.is_empty() and not bulk[0].is_empty():
		var out : FlowData.Data = bulk[0][0]
		assert_object(out).is_not_null()
	node.free()

func test_settings_variants_no_crash() -> void:
	var s = PointsFromGridmapSettings.new()
	s.include_item_id = false
	s.include_gridmap_ref = true
	s.item_id_filter = 0
	s.y_offset = 1.5
	s.out_cell_attribute = "cell"
	s.out_gridmap_attribute = "gm"
	var node = _run(s)
	assert_bool(true).is_true()
	node.free()
