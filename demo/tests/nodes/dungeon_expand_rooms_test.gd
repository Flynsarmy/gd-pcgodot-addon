# dungeon_expand_rooms_test.gd
class_name DungeonExpandRoomsTest extends GdUnitTestSuite

const FlowDataScript = preload("res://addons/flow_nodes_editor/flow_data.gd")
const DungeonExpandRoomsNode = preload("res://addons/flow_nodes_editor/nodes/dungeon_expand_rooms.gd")
const DungeonExpandRoomsSettings = preload("res://addons/flow_nodes_editor/nodes/dungeon_expand_rooms_settings.gd")

func _make_room_data(centers: PackedVector3Array, widths: PackedInt32Array, heights: PackedInt32Array, room_ids: PackedInt32Array) -> FlowData.Data:
	var d := FlowDataScript.Data.new()
	var n := centers.size()
	d.addCommonStreams(n)
	var spos := d.getVector3Container(FlowDataScript.AttrPosition)
	for i in range(n):
		spos[i] = centers[i]
	d.registerStream("RoomWidth", widths, FlowDataScript.DataType.Int)
	d.registerStream("RoomHeight", heights, FlowDataScript.DataType.Int)
	d.registerStream("RoomID", room_ids, FlowDataScript.DataType.Int)
	return d

func _run(inputs: Array, settings) -> DungeonExpandRoomsNode:
	var node = DungeonExpandRoomsNode.new()
	node.name = "test_node"
	node.settings = settings
	node.inputs = inputs
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

func test_single_room_expands_to_correct_tile_count() -> void:
	var s := DungeonExpandRoomsSettings.new()
	s.cell_size = 2.0
	var centers := PackedVector3Array([Vector3(0, 0, 0)])
	var widths := PackedInt32Array([3])
	var heights := PackedInt32Array([2])
	var ids := PackedInt32Array([1])
	var node := _run([_make_room_data(centers, widths, heights, ids)], s)
	assert_str(node.err).is_empty()
	var out := _output(node)
	assert_object(out).is_not_null()
	assert_int(out.size()).is_equal(6)
	node.free()

func test_single_room_tile_positions_correct() -> void:
	var s := DungeonExpandRoomsSettings.new()
	s.cell_size = 2.0
	var centers := PackedVector3Array([Vector3(0, 0, 0)])
	var widths := PackedInt32Array([2])
	var heights := PackedInt32Array([2])
	var ids := PackedInt32Array([42])
	var node := _run([_make_room_data(centers, widths, heights, ids)], s)
	assert_str(node.err).is_empty()
	var out := _output(node)
	assert_object(out).is_not_null()
	assert_int(out.size()).is_equal(4)
	var spos := out.getVector3Container(FlowDataScript.AttrPosition)
	var expected := PackedVector3Array([
		Vector3(-2.0, 0, -2.0),
		Vector3(0.0, 0, -2.0),
		Vector3(-2.0, 0, 0.0),
		Vector3(0.0, 0, 0.0),
	])
	assert_array(spos).is_equal(expected)
	node.free()

func test_room_id_and_cell_type_streams_populated() -> void:
	var s := DungeonExpandRoomsSettings.new()
	s.cell_size = 2.0
	var centers := PackedVector3Array([Vector3(0, 0, 0)])
	var widths := PackedInt32Array([2])
	var heights := PackedInt32Array([2])
	var ids := PackedInt32Array([7])
	var node := _run([_make_room_data(centers, widths, heights, ids)], s)
	assert_str(node.err).is_empty()
	var out := _output(node)
	assert_object(out).is_not_null()
	var s_rid := out.findStream("RoomID")
	assert_object(s_rid).is_not_null()
	assert_int(int(s_rid.container[0])).is_equal(7)
	assert_int(int(s_rid.container[3])).is_equal(7)
	var s_ct := out.findStream("CellType")
	assert_object(s_ct).is_not_null()
	assert_str(s_ct.container[0]).is_equal("Room")
	assert_str(s_ct.container[3]).is_equal("Room")
	node.free()

func test_multiple_rooms_tile_count_sum() -> void:
	var s := DungeonExpandRoomsSettings.new()
	s.cell_size = 2.0
	var centers := PackedVector3Array([Vector3(0, 0, 0), Vector3(20, 0, 20)])
	var widths := PackedInt32Array([3, 4])
	var heights := PackedInt32Array([3, 2])
	var ids := PackedInt32Array([1, 2])
	var node := _run([_make_room_data(centers, widths, heights, ids)], s)
	assert_str(node.err).is_empty()
	var out := _output(node)
	assert_object(out).is_not_null()
	assert_int(out.size()).is_equal(17)
	node.free()

func test_custom_cell_size() -> void:
	var s := DungeonExpandRoomsSettings.new()
	s.cell_size = 4.0
	var centers := PackedVector3Array([Vector3(0, 0, 0)])
	var widths := PackedInt32Array([2])
	var heights := PackedInt32Array([2])
	var ids := PackedInt32Array([1])
	var node := _run([_make_room_data(centers, widths, heights, ids)], s)
	assert_str(node.err).is_empty()
	var out := _output(node)
	assert_object(out).is_not_null()
	assert_int(out.size()).is_equal(4)
	var spos := out.getVector3Container(FlowDataScript.AttrPosition)
	assert_float(spos[1].x - spos[0].x).is_equal_approx(4.0, 0.001)
	var ssz := out.getVector3Container(FlowDataScript.AttrSize)
	assert_float(ssz[0].x).is_equal_approx(4.0, 0.001)
	assert_float(ssz[0].z).is_equal_approx(4.0, 0.001)
	node.free()

func test_empty_input_returns_empty_output() -> void:
	var s := DungeonExpandRoomsSettings.new()
	s.cell_size = 2.0
	var d := FlowDataScript.Data.new()
	var node := _run([d], s)
	assert_str(node.err).is_empty()
	var out := _output(node)
	assert_object(out).is_not_null()
	assert_int(out.size()).is_equal(0)
	node.free()

func test_missing_room_streams_sets_error() -> void:
	var s := DungeonExpandRoomsSettings.new()
	s.cell_size = 2.0
	var d := FlowDataScript.Data.new()
	d.addCommonStreams(1)
	var node := _run([d], s)
	assert_str(node.err).is_not_empty()
	node.free()

func test_missing_input_sets_error() -> void:
	var s := DungeonExpandRoomsSettings.new()
	s.cell_size = 2.0
	var node := _run([null], s)
	assert_str(node.err).is_not_empty()
	node.free()

func test_output_has_type_stream_filled_with_zeros() -> void:
	var s := DungeonExpandRoomsSettings.new()
	s.cell_size = 2.0
	var centers := PackedVector3Array([Vector3(0, 0, 0)])
	var widths := PackedInt32Array([2])
	var heights := PackedInt32Array([2])
	var ids := PackedInt32Array([1])
	var node := _run([_make_room_data(centers, widths, heights, ids)], s)
	assert_str(node.err).is_empty()
	var out := _output(node)
	assert_object(out).is_not_null()
	var s_type := out.findStream("type")
	assert_object(s_type).is_not_null()
	assert_int(s_type.container.size()).is_equal(4)
	assert_float(float(s_type.container[0])).is_equal_approx(0.0, 0.001)
	node.free()
