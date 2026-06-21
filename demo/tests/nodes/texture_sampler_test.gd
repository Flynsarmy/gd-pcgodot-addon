# texture_sampler_test.gd
class_name TextureSamplerTest extends GdUnitTestSuite

const FlowDataScript = preload("res://addons/flow_nodes_editor/flow_data.gd")
const TextureSamplerNode = preload("res://addons/flow_nodes_editor/nodes/texture_sampler.gd")
const TextureSamplerSettings = preload("res://addons/flow_nodes_editor/nodes/texture_sampler_settings.gd")

func _make_point_data(positions: PackedVector3Array) -> FlowData.Data:
	var d := FlowDataScript.Data.new()
	d.registerStream(FlowData.AttrPosition, positions, FlowData.DataType.Vector)
	return d

func _run(inputs: Array, settings) -> TextureSamplerNode:
	var node = TextureSamplerNode.new()
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

func test_null_input_sets_error() -> void:
	var s = TextureSamplerSettings.new()
	var node = _run([null], s)
	assert_str(node.err).is_not_empty()
	node.free()

func test_no_texture_assigned_sets_error() -> void:
	var s = TextureSamplerSettings.new()
	s.texture = null
	s.write_color_attribute = true
	s.write_value_attribute = false
	s.uv_attribute_name = "uv"
	s.use_position_if_uv_missing = false
	var positions = PackedVector3Array([Vector3(0.0, 0.0, 0.0)])
	var in_data = _make_point_data(positions)
	var node = _run([in_data], s)
	assert_str(node.err).is_not_empty()
	node.free()

func test_passthrough_when_no_outputs_enabled() -> void:
	var s = TextureSamplerSettings.new()
	s.write_color_attribute = false
	s.write_value_attribute = false
	var positions = PackedVector3Array([Vector3(1.0, 0.0, 2.0)])
	var in_data = _make_point_data(positions)
	var node = _run([in_data], s)
	assert_str(node.err).is_empty()
	assert_bool(node.generated_bulks.is_empty()).is_false()
	node.free()
