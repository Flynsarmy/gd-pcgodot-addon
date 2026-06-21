# surface_sampler_test.gd
class_name SurfaceSamplerTest extends GdUnitTestSuite

const FlowDataScript = preload("res://addons/flow_nodes_editor/flow_data.gd")
const SurfaceSamplerNode = preload("res://addons/flow_nodes_editor/nodes/surface_sampler.gd")
const SurfaceSamplerSettings = preload("res://addons/flow_nodes_editor/nodes/surface_sampler_settings.gd")

func _run(inputs: Array, settings) -> SurfaceSamplerNode:
	var node = SurfaceSamplerNode.new()
	node.name = "test_surface_sampler"
	node.settings = settings
	node.inputs = inputs
	var ctx = FlowDataScript.EvaluationContext.new()
	var dummy = FlowGraphNode3D.new()
	ctx.owner = dummy
	node.preExecute(ctx)
	node.execute(ctx)
	dummy.free()
	return node

func _output(node: SurfaceSamplerNode) -> FlowData.Data:
	if node.generated_bulks.is_empty():
		return null
	var bulk = node.generated_bulks[0]
	if bulk.is_empty():
		return null
	return bulk[0]

func test_null_input_sets_error() -> void:
	var s = SurfaceSamplerSettings.new()
	var node = _run([null], s)
	assert_str(node.err).is_not_empty()
	node.free()

func test_empty_input_returns_empty_output() -> void:
	var in_data := FlowDataScript.Data.new()
	var s = SurfaceSamplerSettings.new()
	var node = _run([in_data], s)
	assert_str(node.err).is_empty()
	var out = _output(node)
	assert_object(out).is_not_null()
	assert_int(out.size()).is_equal(0)
	node.free()

func test_trs_input_produces_points() -> void:
	var in_data := FlowDataScript.Data.new()
	in_data.registerStream(FlowDataScript.AttrPosition, PackedVector3Array([Vector3.ZERO]), FlowDataScript.DataType.Vector)
	in_data.registerStream(FlowDataScript.AttrRotation, PackedVector3Array([Vector3.ZERO]), FlowDataScript.DataType.Vector)
	in_data.registerStream(FlowDataScript.AttrSize, PackedVector3Array([Vector3(10.0, 10.0, 10.0)]), FlowDataScript.DataType.Vector)
	var s = SurfaceSamplerSettings.new()
	s.num_points = 5
	s.point_size = Vector3.ONE
	var node = _run([in_data], s)
	assert_str(node.err).is_empty()
	var out = _output(node)
	assert_object(out).is_not_null()
	var positions = out.getVector3Container(FlowDataScript.AttrPosition)
	assert_int(positions.size()).is_equal(5)
	assert_object(out.findStream(FlowDataScript.AttrDensity)).is_not_null()
	assert_object(out.findStream(FlowDataScript.AttrSeed)).is_not_null()
	node.free()
