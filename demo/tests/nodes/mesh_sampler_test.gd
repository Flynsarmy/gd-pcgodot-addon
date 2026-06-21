# mesh_sampler_test.gd
class_name MeshSamplerTest extends GdUnitTestSuite

const FlowDataScript = preload("res://addons/flow_nodes_editor/flow_data.gd")
const MeshSamplerNode = preload("res://addons/flow_nodes_editor/nodes/mesh_sampler.gd")
const SampleMeshSettings = preload("res://addons/flow_nodes_editor/nodes/sample_mesh_settings.gd")

func _run(inputs: Array, settings) -> MeshSamplerNode:
	var node = MeshSamplerNode.new()
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
	var s = SampleMeshSettings.new()
	var node = _run([null], s)
	assert_str(node.err).is_not_empty()
	node.free()

func test_mode_use_num_samples_null_input_sets_error() -> void:
	var s = SampleMeshSettings.new()
	s.mode = SampleMeshSettings.eMode.UseNumSamples
	s.num_samples = 10
	var node = _run([null], s)
	assert_str(node.err).is_not_empty()
	node.free()

func test_mode_one_per_vertex_null_input_sets_error() -> void:
	var s = SampleMeshSettings.new()
	s.mode = SampleMeshSettings.eMode.OnePerVertex
	var node = _run([null], s)
	assert_str(node.err).is_not_empty()
	node.free()
