# points_from_tilemap_test.gd
class_name PointsFromTilemapTest extends GdUnitTestSuite

const FlowDataScript = preload("res://addons/flow_nodes_editor/flow_data.gd")
const PointsFromTilemapNode = preload("res://addons/flow_nodes_editor/nodes/points_from_tilemap.gd")
const PointsFromTilemapSettings = preload("res://addons/flow_nodes_editor/nodes/points_from_tilemap_settings.gd")

func _run(settings) -> PointsFromTilemapNode:
	var node = PointsFromTilemapNode.new()
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

func test_null_owner_returns_empty_without_error() -> void:
	var s = PointsFromTilemapSettings.new()
	var node = PointsFromTilemapNode.new()
	node.name = "test_node"
	node.settings = s
	node.inputs = []
	var ctx = FlowDataScript.EvaluationContext.new()
	ctx.owner = null
	node.preExecute(ctx)
	node.execute(ctx)
	assert_str(node.err).is_empty()
	var out = _output(node)
	assert_object(out).is_not_null()
	node.free()

func test_node_with_invalid_tilemap_path_sets_error() -> void:
	var s = PointsFromTilemapSettings.new()
	s.tilemap_path = "NonExistentPath/TileMapLayer"
	var node = _run(s)
	assert_str(node.err).is_not_empty()
	node.free()

func test_node_with_no_tilemaps_in_scene_returns_empty_data() -> void:
	var s = PointsFromTilemapSettings.new()
	s.include_tile_ids = false
	s.include_layer_ref = false
	var node = _run(s)
	assert_str(node.err).is_empty()
	var out = _output(node)
	assert_object(out).is_not_null()
	node.free()
