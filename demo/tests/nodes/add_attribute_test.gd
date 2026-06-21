# add_attribute_test.gd
class_name AddAttributeTest extends GdUnitTestSuite

const FlowDataScript = preload("res://addons/flow_nodes_editor/flow_data.gd")
const AddAttributeNode = preload("res://addons/flow_nodes_editor/nodes/add_attribute.gd")
const AddAttributeSettings = preload("res://addons/flow_nodes_editor/nodes/add_attribute_settings.gd")

func _make_data(stream_name: String, values, dtype: int) -> FlowData.Data:
	var d := FlowDataScript.Data.new()
	d.registerStream(stream_name, values, dtype)
	return d

func _run(inputs: Array, settings) -> AddAttributeNode:
	var node = AddAttributeNode.new()
	node.name = "test_add_attribute"
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

func test_add_float_attribute_no_input() -> void:
	var s = AddAttributeSettings.new()
	s.name = "density"
	s.data_type = FlowDataScript.DataType.Float
	s.cte_float = 3.14
	s.domain = AddAttributeSettings.eDomain.PerPoint
	var node = _run([null], s)
	assert_str(node.err).is_empty()
	var out = _output(node)
	assert_object(out).is_not_null()
	var stream = out.findStream("density")
	assert_object(stream).is_not_null()
	assert_int(stream.container.size()).is_equal(1)
	assert_float(stream.container[0]).is_equal_approx(3.14, 0.001)
	node.free()

func test_add_float_attribute_with_input() -> void:
	var s = AddAttributeSettings.new()
	s.name = "weight"
	s.data_type = FlowDataScript.DataType.Float
	s.cte_float = 0.5
	s.domain = AddAttributeSettings.eDomain.PerPoint
	var in_data = _make_data("position", PackedVector3Array([Vector3.ZERO, Vector3.ONE, Vector3(2,0,0)]), FlowDataScript.DataType.Vector)
	var node = _run([in_data], s)
	assert_str(node.err).is_empty()
	var out = _output(node)
	assert_object(out).is_not_null()
	var stream = out.findStream("weight")
	assert_object(stream).is_not_null()
	assert_int(stream.container.size()).is_equal(3)
	assert_float(stream.container[0]).is_equal_approx(0.5, 0.001)
	assert_float(stream.container[2]).is_equal_approx(0.5, 0.001)
	node.free()

func test_add_int_attribute() -> void:
	var s = AddAttributeSettings.new()
	s.name = "my_int"
	s.data_type = FlowDataScript.DataType.Int
	s.cte_int = 42
	s.domain = AddAttributeSettings.eDomain.PerPoint
	var in_data = _make_data("position", PackedVector3Array([Vector3.ZERO, Vector3.ONE]), FlowDataScript.DataType.Vector)
	var node = _run([in_data], s)
	assert_str(node.err).is_empty()
	var out = _output(node)
	assert_object(out).is_not_null()
	var stream = out.findStream("my_int")
	assert_object(stream).is_not_null()
	assert_int(stream.container.size()).is_equal(2)
	assert_int(stream.container[0]).is_equal(42)
	assert_int(stream.container[1]).is_equal(42)
	node.free()

func test_add_vector_attribute() -> void:
	var s = AddAttributeSettings.new()
	s.name = "my_vec"
	s.data_type = FlowDataScript.DataType.Vector
	s.cte_vector = Vector3(1.0, 2.0, 3.0)
	s.domain = AddAttributeSettings.eDomain.PerPoint
	var in_data = _make_data("position", PackedVector3Array([Vector3.ZERO, Vector3.ONE]), FlowDataScript.DataType.Vector)
	var node = _run([in_data], s)
	assert_str(node.err).is_empty()
	var out = _output(node)
	assert_object(out).is_not_null()
	var stream = out.findStream("my_vec")
	assert_object(stream).is_not_null()
	assert_int(stream.container.size()).is_equal(2)
	assert_bool(stream.container[0].is_equal_approx(Vector3(1.0, 2.0, 3.0))).is_true()
	node.free()

func test_add_color_attribute() -> void:
	var s = AddAttributeSettings.new()
	s.name = "tint"
	s.data_type = FlowDataScript.DataType.Color
	s.cte_color = Color(1.0, 0.0, 0.5, 1.0)
	s.domain = AddAttributeSettings.eDomain.PerPoint
	var in_data = _make_data("position", PackedVector3Array([Vector3.ZERO, Vector3.ONE, Vector3(5,0,0)]), FlowDataScript.DataType.Vector)
	var node = _run([in_data], s)
	assert_str(node.err).is_empty()
	var out = _output(node)
	assert_object(out).is_not_null()
	var stream = out.findStream("tint")
	assert_object(stream).is_not_null()
	assert_int(stream.container.size()).is_equal(3)
	assert_bool(stream.container[0].is_equal_approx(Color(1.0, 0.0, 0.5, 1.0))).is_true()
	node.free()

func test_add_bool_attribute() -> void:
	var s = AddAttributeSettings.new()
	s.name = "active"
	s.data_type = FlowDataScript.DataType.Bool
	s.cte_bool = true
	s.domain = AddAttributeSettings.eDomain.PerPoint
	var in_data = _make_data("position", PackedVector3Array([Vector3.ZERO, Vector3.ONE]), FlowDataScript.DataType.Vector)
	var node = _run([in_data], s)
	assert_str(node.err).is_empty()
	var out = _output(node)
	assert_object(out).is_not_null()
	var stream = out.findStream("active")
	assert_object(stream).is_not_null()
	assert_int(stream.container.size()).is_equal(2)
	assert_int(stream.container[0]).is_equal(1)
	node.free()

func test_per_data_domain_creates_single_entry() -> void:
	var s = AddAttributeSettings.new()
	s.name = "meta_val"
	s.data_type = FlowDataScript.DataType.Float
	s.cte_float = 99.0
	s.domain = AddAttributeSettings.eDomain.PerData
	var in_data = _make_data("position", PackedVector3Array([Vector3.ZERO, Vector3.ONE, Vector3(2,0,0)]), FlowDataScript.DataType.Vector)
	var node = _run([in_data], s)
	assert_str(node.err).is_empty()
	var out = _output(node)
	assert_object(out).is_not_null()
	var target_name = FlowDataScript.DataAttrPrefix + "meta_val"
	var stream = out.findStream(target_name)
	assert_object(stream).is_not_null()
	assert_int(stream.container.size()).is_equal(1)
	assert_float(stream.container[0]).is_equal_approx(99.0, 0.001)
	node.free()

func test_empty_attribute_name_produces_error() -> void:
	var s = AddAttributeSettings.new()
	s.name = ""
	s.data_type = FlowDataScript.DataType.Float
	s.cte_float = 1.0
	s.domain = AddAttributeSettings.eDomain.PerPoint
	var node = _run([null], s)
	assert_str(node.err).is_not_empty()
	node.free()

func test_input_streams_are_preserved() -> void:
	var s = AddAttributeSettings.new()
	s.name = "extra"
	s.data_type = FlowDataScript.DataType.Int
	s.cte_int = 7
	s.domain = AddAttributeSettings.eDomain.PerPoint
	var in_data := FlowDataScript.Data.new()
	in_data.registerStream("position", PackedVector3Array([Vector3.ZERO, Vector3.ONE]), FlowDataScript.DataType.Vector)
	in_data.registerStream("density", PackedFloat32Array([0.1, 0.9]), FlowDataScript.DataType.Float)
	var node = _run([in_data], s)
	assert_str(node.err).is_empty()
	var out = _output(node)
	assert_object(out).is_not_null()
	assert_object(out.findStream("position")).is_not_null()
	assert_object(out.findStream("density")).is_not_null()
	assert_object(out.findStream("extra")).is_not_null()
	node.free()
