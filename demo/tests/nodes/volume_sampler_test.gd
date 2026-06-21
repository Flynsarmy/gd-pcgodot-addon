# volume_sampler_test.gd
class_name VolumeSamplerTest extends GdUnitTestSuite

const FlowDataScript = preload("res://addons/flow_nodes_editor/flow_data.gd")
const VolumeSamplerNode = preload("res://addons/flow_nodes_editor/nodes/volume_sampler.gd")
const VolumeSamplerSettings = preload("res://addons/flow_nodes_editor/nodes/volume_sampler_settings.gd")

func _run(inputs: Array, settings) -> VolumeSamplerNode:
	var node = VolumeSamplerNode.new()
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

func test_null_input_sets_error() -> void:
	var s = VolumeSamplerSettings.new()
	var node = _run([null], s)
	assert_str(node.err).is_not_empty()
	node.free()

func test_input_without_position_stream_sets_error() -> void:
	var s = VolumeSamplerSettings.new()
	s.distribution = SamplePointsNodeSettings.eDistribution.UniformGrid
	var d = FlowDataScript.Data.new()
	d.registerStream("density", PackedFloat32Array([1.0, 1.0]), FlowDataScript.DataType.Float)
	var node = _run([d], s)
	assert_str(node.err).is_not_empty()
	node.free()

func test_changing_distribution_mode_does_not_crash_with_null_input() -> void:
	for dist in [
		SamplePointsNodeSettings.eDistribution.UniformGrid,
		SamplePointsNodeSettings.eDistribution.QuasiRandom2D,
		SamplePointsNodeSettings.eDistribution.QuasiRandom3D,
	]:
		var s = VolumeSamplerSettings.new()
		s.distribution = dist
		var node = _run([null], s)
		assert_str(node.err).is_not_empty()
		node.free()
