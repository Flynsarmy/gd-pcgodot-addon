@tool
extends ColorRect

var gedit: GraphEdit
var last_scroll_offset := Vector2.INF
var last_zoom := INF

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	show_behind_parent = true
	# Setup anchors to cover the full parent rect
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_right = 0.0
	offset_bottom = 0.0
	
	# Load and assign shader
	var shader = load("res://addons/flow_nodes_editor/custom_grid_shader.gdshader")
	if shader:
		var mat = ShaderMaterial.new()
		mat.shader = shader
		material = mat

func _process(_delta):
	if gedit and material:
		if gedit.scroll_offset != last_scroll_offset:
			last_scroll_offset = gedit.scroll_offset
			material.set_shader_parameter("scroll_offset", last_scroll_offset)
		if not is_equal_approx(gedit.zoom, last_zoom):
			last_zoom = gedit.zoom
			material.set_shader_parameter("zoom", last_zoom)
