# navigation_region_sampler_test.gd
class_name NavigationRegionSamplerTest extends GdUnitTestSuite

const FlowDataScript = preload("res://addons/flow_nodes_editor/flow_data.gd")
const NavigationRegionSamplerNode = preload("res://addons/flow_nodes_editor/nodes/navigation_region_sampler.gd")
const NavigationRegionSamplerSettings = preload("res://addons/flow_nodes_editor/nodes/navigation_region_sampler_settings.gd")

func _run(settings) -> NavigationRegionSamplerNode:
	var node = NavigationRegionSamplerNode.new()
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

func test_null_scene_produces_no_error() -> void:
	var s = NavigationRegionSamplerSettings.new()
	var node = _run(s)
	assert_str(node.err).is_empty()
	node.free()

func test_null_scene_produces_empty_output() -> void:
	var s = NavigationRegionSamplerSettings.new()
	var node = _run(s)
	assert_str(node.err).is_empty()
	assert_bool(node.generated_bulks.is_empty() or node.generated_bulks[0].is_empty() or node.generated_bulks[0][0] == null or node.generated_bulks[0][0].size() == 0).is_true()
	node.free()

func test_vertices_mode_does_not_crash_with_empty_scene() -> void:
	var s = NavigationRegionSamplerSettings.new()
	s.sample_mode = NavigationRegionSamplerSettings.eSampleMode.Vertices
	var node = _run(s)
	assert_str(node.err).is_empty()
	node.free()
