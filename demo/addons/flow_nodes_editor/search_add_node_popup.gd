@tool
extends PopupMenu
class_name SearchAddNodePopup

signal node_selected(template_name: String)
signal action_selected(action_id: int)
signal input_selected(input_idx: int)
signal output_selected(output_idx: int)

const IDM_COLLAPSE_TO_SUBGRAPH = 200
const IDM_NODE_BASE: int = 1000
const IDM_INPUT_BASE: int = 200000
const IDM_OUTPUT_BASE: int = 300000

var _id_to_item: Dictionary = {}
var _submenus: Dictionary = {}

const _CATEGORY_MAP := {
	"Black Lantern": ["bl_style_lab_source", "bl_building_mass", "bl_zone_carver", "bl_room_splitter", "bl_decorator_master", "bl_tactical_decorator", "bl_floor_data_to_points", "bl_floor_data_contract_points", "bl_validate_floor_data", "bl_room_style_template", "bl_style_context_source", "bl_style_context_points", "bl_style_anchor_points", "bl_sync_grid_cell", "bl_points_to_style_spec", "bl_style_spec_to_points", "bl_style_spec_merge", "bl_style_metadata_spec", "bl_smart_prop_scatter", "bl_points_to_floor_data_props"],
	"Control Flow": ["input", "output", "subgraph", "loop", "branch", "select", "select_multi", "switch", "get_loop_index"],
	"Debug": ["debug", "print_string", "sanity_check"],
	"Density": ["curve_remap_density", "density_remap", "distance_to_density"],
	"Filter": ["filter", "filter_data_by_tag", "filter_data_by_attribute", "filter_data_by_type", "attribute_filter_range", "point_filter_range", "self_pruning", "substract", "difference", "intersection", "union"],
	"Math": ["math_op", "expression", "reduce", "boolean"],
	"Metadata": ["add_attribute", "attribute_rename", "remove_attribute", "add_tags", "delete_tags", "replace_tags", "make_vector", "compose_vector", "decompose_vector", "attribute_random", "match_and_set", "mutate_seed", "random_color", "point_to_attribute_set", "attribute_set_to_point", "load_data_table", "data_table_row_to_attribute_set", "load_pcg_data_asset"],
	"Point Ops": ["bounds_modifier", "transform", "build_rotation_from_up", "combine_points", "duplicate_point", "point_offsets", "snap_to_grid", "point_neighborhood"],
	"Sampler": ["copy", "copy_points", "sample_mesh", "point_from_mesh", "point_from_player_pawn", "points_from_scene", "points_from_tilemap", "points_from_gridmap", "select_points", "sample_spline", "surface_sampler", "volume_sampler", "texture_sampler", "points_from_imported_scene", "load_alembic_file", "navigation_region_sampler"],
	"Spatial": ["create_spline", "distance", "ray_cast", "physics_overlap_query", "physics_shape_sweep", "clip_points_by_polygon", "clip_paths", "polygon_operation", "split_splines", "create_surface_from_spline", "create_surface_from_polygon"],
	"Assets": ["assets", "spawn_meshes", "spawn_scenes", "spawn_nodes", "apply_on_actor", "points_from_imported_scene", "load_alembic_file", "load_pcg_data_asset"],
	"Generators": ["grid", "noise", "relax", "dungeon_generator", "make_bounds", "grid_fill_bounds", "grid_connect_points", "grid_boundary"],
	"Utility": ["sort", "merge", "merge_points", "partition", "scan_meshes", "scan_splines", "scan_nodes", "sequence_sample", "size", "get_points_count", "get_data_count", "get_entries_count", "transform_points"]
}

func _ready():
	id_pressed.connect(_on_id_pressed)

func setup(p_node_types: Dictionary, p_inputs: Array, p_outputs: Array, p_has_selected_nodes: bool, p_req_in: int = FlowData.DataType.Invalid, p_req_out: int = FlowData.DataType.Invalid):
	clear()
	_id_to_item.clear()
	_clear_submenus()

	var next_node_id = IDM_NODE_BASE

	if p_has_selected_nodes and p_req_in == FlowData.DataType.Invalid and p_req_out == FlowData.DataType.Invalid:
		add_item("Collapse Selected to Subgraph", IDM_COLLAPSE_TO_SUBGRAPH)
		_id_to_item[IDM_COLLAPSE_TO_SUBGRAPH] = {"type": "action", "key": IDM_COLLAPSE_TO_SUBGRAPH}

	if p_req_in == FlowData.DataType.Invalid and p_req_out == FlowData.DataType.Invalid:
		for idx in range(p_inputs.size()):
			var input_name = p_inputs[idx].name
			var input_id = IDM_INPUT_BASE + idx
			add_item("Input: %s" % input_name, input_id)
			_id_to_item[input_id] = {"type": "input", "key": idx}

		for idx in range(p_outputs.size()):
			var output_name = p_outputs[idx].name
			var output_id = IDM_OUTPUT_BASE + idx
			add_item("Output: %s" % output_name, output_id)
			_id_to_item[output_id] = {"type": "output", "key": idx}

	var templates: Array = []
	for key in p_node_types.keys():
		var meta = p_node_types[key]
		if not meta.get("auto_register", true):
			continue

		if p_req_in != FlowData.DataType.Invalid or p_req_out != FlowData.DataType.Invalid:
			var has_compatible_port = false
			var ports = meta.ins if p_req_in != FlowData.DataType.Invalid else meta.outs
			var required_type = p_req_in if p_req_in != FlowData.DataType.Invalid else p_req_out
			for port in ports:
				if port.get("data_type", 0) == required_type:
					has_compatible_port = true
					break
			if not has_compatible_port:
				continue

		templates.append(key)

	templates.sort()
	var items_by_category: Dictionary = {}

	for key in templates:
		var meta = node_types[key]
		# Prefer an explicit "category" in the node's meta, fall back to cat_map (then "Utility")
		var category = str(meta.get("category", ""))
		if category == "":
			category = get_category.call(key)
		all_items.append({
			"type": "node",
			"key": key,
			"label": meta.title,
			"category": category,
			"aliases": meta.get("aliases", []),
			"tooltip": meta.get("tooltip", "")
		})

func _notification(what: int):
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_inside_tree():
		update_localized_text()

func update_localized_text():
	if line_edit:
		line_edit.placeholder_text = FlowI18n.t("Search nodes...")
	if list_vbox:
		rebuild_list()

func _item_matches_query(item: Dictionary, query: String) -> bool:
	return _item_match_score(item, query) > 0

## Scores how well an item matches the query. Higher = better. 0 = no match.
## Supports fuzzy token-based matching: "pt neigh" matches "Point Neighborhood".
func _item_match_score(item: Dictionary, query: String) -> int:
	var label_lower = String(item.label).to_lower()
	var localized_label_lower = _localized_label(item).to_lower()
	var cat_lower = String(item.category).to_lower()
	var localized_cat_lower = _localized_category(item).to_lower()
	var full_path = cat_lower + " " + localized_cat_lower + " " + label_lower + " " + localized_label_lower

	# Exact match in label = highest score
	if label_lower == query or localized_label_lower == query:
		return 100
	# Starts with = high score
	if label_lower.begins_with(query) or localized_label_lower.begins_with(query):
		return 80
	# Contains full query = good score
	if label_lower.contains(query) or localized_label_lower.contains(query):
		return 60
	if full_path.contains(query):
		return 50
	# Check tooltip
	if item.get("tooltip", "").to_lower().contains(query):
		return 40
	# Check aliases
	for alias in item.get("aliases", []):
		if str(alias).to_lower().contains(query):
			return 40
	# Fuzzy token matching: split query into tokens, ALL must match somewhere
	var tokens = query.split(" ", false)
	if tokens.size() > 1:
		var searchable = full_path + " " + item.get("tooltip", "").to_lower()
		for alias in item.get("aliases", []):
			searchable += " " + str(alias).to_lower()
		var all_match = true
		for token in tokens:
			if not searchable.contains(token):
				all_match = false
				break
		if all_match:
			return 30
	# Subsequence fuzzy matching: query chars appear in order, e.g. "ptneigh"
	# matches "Point Neighborhood". Scores below substring/token matches.
	var compact_query = query.replace(" ", "")
	if _is_subsequence(compact_query, label_lower):
		return 20
	for alias in item.get("aliases", []):
		if _is_subsequence(compact_query, str(alias).to_lower()):
			return 15
	return 0

## True when every character of query appears in text, in order (not necessarily contiguous).
func _is_subsequence(query: String, text: String) -> bool:
	if query.is_empty():
		return false
	var qi = 0
	for i in range(text.length()):
		if text[i] == query[qi]:
			qi += 1
			if qi >= query.length():
				return true
	return false

func _localized_label(item: Dictionary) -> String:
	if item.type == "node":
		return FlowI18n.tn(String(item.label))
	return FlowI18n.t(String(item.label))

func _localized_category(item: Dictionary) -> String:
	if item.type == "node":
		return FlowI18n.tn(String(item.category))
	return FlowI18n.t(String(item.category))

func _localized_node_category(category_name: String) -> String:
	return FlowI18n.tn(category_name)

func _localized_tooltip(item: Dictionary) -> String:
	var tooltip := String(item.get("tooltip", ""))
	if item.type == "node":
		return FlowI18n.tn(tooltip)
	return FlowI18n.t(tooltip)

func _node_path_label(item: Dictionary) -> String:
	return "%s > %s" % [_localized_category(item), _localized_label(item)]

func _create_scroll_arrow_button(label: String) -> Button:
	var btn = Button.new()
	btn.text = label
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.custom_minimum_size = Vector2(MENU_WIDTH, SCROLL_ARROW_HEIGHT)
	btn.add_theme_font_size_override("font_size", 11)
	btn.add_theme_color_override("font_color", ACCENT_COLOR)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_disabled_color", Color(0.55, 0.80, 0.88, 0.62))
	var sb_normal = StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal", sb_normal)
	var sb_hover = StyleBoxFlat.new()
	sb_hover.bg_color = Color(1.0, 1.0, 1.0, 0.05)
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_stylebox_override("pressed", sb_hover)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return btn

func _on_sub_scroll_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_set_sub_scroll_value(sub_scroll_value - ROW_HEIGHT * 3)
			sub_scroll.accept_event()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_set_sub_scroll_value(sub_scroll_value + ROW_HEIGHT * 3)
			sub_scroll.accept_event()

func _set_sub_scroll_value(value: float):
	sub_scroll_value = clampf(value, 0.0, sub_scroll_max)
	if sub_list_margin:
		sub_list_margin.position.y = -sub_scroll_value
	if sub_scrollbar and absf(sub_scrollbar.value - sub_scroll_value) > 0.01:
		sub_scrollbar.value = sub_scroll_value
	_update_sub_scroll_arrows()

func _update_sub_scroll_arrows():
	if not sub_scroll_up_btn or not sub_scroll_down_btn:
		return
	if not sub_has_scroll_overflow:
		sub_scroll_up_btn.visible = false
		sub_scroll_down_btn.visible = false
		return

	sub_scroll_up_btn.visible = sub_scroll_value > 1.0
	sub_scroll_down_btn.visible = sub_scroll_value < sub_scroll_max - 1.0
	sub_scroll_up_btn.disabled = false
	sub_scroll_down_btn.disabled = false

func _make_button_style(bg_color: Color, indent: int) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.set_corner_radius_all(4)
	style.content_margin_left = indent
	style.content_margin_right = 12
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style

func _make_empty_button_style(indent: int) -> StyleBoxEmpty:
	var style = StyleBoxEmpty.new()
	style.content_margin_left = indent
	style.content_margin_right = 12
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style

func _get_menu_font(bold := false):
	if bold and has_theme_font("bold", "EditorFonts"):
		return get_theme_font("bold", "EditorFonts")
	if has_theme_font("main", "EditorFonts"):
		return get_theme_font("main", "EditorFonts")
	return null

func _style_menu_button(btn: Button, indent := 12, bold := false, base_color := Color("c8c8d4")):
	btn.alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_LEFT
	btn.flat = false
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.set_meta("menu_indent", indent)
	btn.set_meta("menu_base_color", base_color)
	btn.add_theme_font_size_override("font_size", 12 if bold else 11)
	btn.add_theme_color_override("font_color", base_color)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)

	var font_to_use = _get_menu_font(bold)
	if font_to_use:
		btn.add_theme_font_override("font", font_to_use)

	btn.add_theme_stylebox_override("normal", _make_empty_button_style(indent))

	var sb_hover = _make_button_style(HOVER_BG_COLOR, indent)
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_stylebox_override("pressed", _make_button_style(SELECTED_BG_COLOR, indent))
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

func _is_category_expanded(category_name: String) -> bool:
	return bool(expanded_categories.get(category_name, false))

func _set_category_expanded(category_name: String, expanded: bool) -> void:
	if expanded:
		expanded_categories[category_name] = true
	else:
		expanded_categories.erase(category_name)

func _toggle_category(category_name: String) -> void:
	_set_category_expanded(category_name, not _is_category_expanded(category_name))
	rebuild_list()
	_highlight_category(category_name)

func _highlight_category(category_name: String) -> void:
	for idx in range(visible_items.size()):
		var item = visible_items[idx]
		if item.type == "category" and item.key == category_name:
			_set_highlight(idx)
			return

func _make_visible_item(item: Dictionary, button_node: Button) -> Dictionary:
	var visible_item := item.duplicate()
	visible_item.button_node = button_node
	return visible_item

func _create_menu_button(item: Dictionary, item_index: int, indent := 12, bold := false, base_color := Color("c8c8d4")) -> Button:
	var btn = Button.new()
	btn.text = _localized_label(item)
	btn.tooltip_text = _localized_tooltip(item)
	_style_menu_button(btn, indent, bold, base_color)
	btn.mouse_entered.connect(func():
		_set_highlight(item_index, false)
	)
	btn.pressed.connect(func():
		_select_item(item)
	)
	return btn

func rebuild_list():
	# Clear list vbox
	for child in list_vbox.get_children():
		child.queue_free()
		list_vbox.remove_child(child)

	visible_items.clear()
	highlighted_index = -1

	var query = search_query.strip_edges().to_lower()
	if query != "":
		# Filter and score items, then sort by score descending
		var scored = []
		for item in all_items:
			var score = _item_match_score(item, query)
			if score > 0:
				scored.append({"item": item, "score": score})
		scored.sort_custom(func(a, b): return a.score > b.score)

		var item_index = 0
		for entry in scored:
			var item = entry.item
			var btn = _create_menu_button(item, item_index)
			# Show path: e.g. "Assets > Spawn Meshes"
			if item.type == "node":
				btn.text = _node_path_label(item)

			list_vbox.add_child(btn)
			visible_items.append(_make_visible_item(item, btn))
			item_index += 1
	else:
		# Empty search query -> show expandable category browsing.
		var item_index = 0
		current_category = ""
		_hide_sub_panel_immediately()

		# Render Actions, Inputs & Outputs first (flat)
		for item in all_items:
			if item.type in ["action", "input", "output"]:
				var btn = _create_menu_button(item, item_index)
				list_vbox.add_child(btn)
				visible_items.append(_make_visible_item(item, btn))
				item_index += 1

		# Render "Recently Used" section
		if recently_used.size() > 0:
			var recent_header = Label.new()
			recent_header.text = FlowI18n.t("Recently Used")
			recent_header.add_theme_font_size_override("font_size", 9)
			recent_header.add_theme_color_override("font_color", Color("6b7280"))
			var header_margin = MarginContainer.new()
			header_margin.add_theme_constant_override("margin_left", 12)
			header_margin.add_theme_constant_override("margin_top", 6)
			header_margin.add_theme_constant_override("margin_bottom", 2)
			header_margin.add_child(recent_header)
			list_vbox.add_child(header_margin)

			for template_name in recently_used:
				var recent_item = null
				for item in all_items:
					if item.type == "node" and item.key == template_name:
						recent_item = item
						break
				if recent_item == null:
					continue
				var btn = _create_menu_button(recent_item, item_index, 12, false, ACCENT_COLOR)
				list_vbox.add_child(btn)
				visible_items.append(_make_visible_item(recent_item, btn))
				item_index += 1

			# Small separator after recent
			var sep = HSeparator.new()
			var sep_style = StyleBoxLine.new()
			sep_style.color = Color(1.0, 1.0, 1.0, 0.05)
			sep_style.thickness = 1
			sep.add_theme_stylebox_override("separator", sep_style)
			list_vbox.add_child(sep)

		var categories = []
		for item in all_items:
			if item.type == "node":
				var cat = item.category
				if not cat in categories:
					categories.append(cat)
		categories.sort()

		for cat in categories:
			var expanded := _is_category_expanded(cat)
			var cat_item = {
				"type": "category",
				"key": cat,
				"label": cat,
				"category": ""
			}
			var btn = _create_menu_button(cat_item, item_index, 12, true, Color("e5e7eb"))
			btn.text = ("%s  %s" % ["▾" if expanded else "▸", _localized_node_category(cat)])
			list_vbox.add_child(btn)
			visible_items.append(_make_visible_item(cat_item, btn))
			item_index += 1

			if expanded:
				for item in all_items:
					if item.type == "node" and item.category == cat:
						var child_btn = _create_menu_button(item, item_index, 30)
						list_vbox.add_child(child_btn)
						visible_items.append(_make_visible_item(item, child_btn))
						item_index += 1

	if visible_items.size() > 0:
		_set_highlight(0)

	# Disable vertical scrollbar if content fits
	var main_content_height = list_vbox.get_child_count() * ROW_HEIGHT + 12
	var main_scroll_height = min(main_content_height, MENU_MAX_HEIGHT)
	scroll.custom_minimum_size = Vector2(MENU_WIDTH, main_scroll_height)
	if main_content_height > MENU_MAX_HEIGHT:
		scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	else:
		scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	update_layout()

func update_layout(hovered_button: Button = null):
	min_size = Vector2i(MENU_WIDTH, 0)
	reset_size()
	size.x = MENU_WIDTH

	if submenu_popup.visible:
		var item_count = sub_list_vbox.get_child_count()
		var content_height = item_count * ROW_HEIGHT + 12
		var has_arrow_buttons = sub_scroll_up_btn != null and sub_scroll_down_btn != null
		var scrollbar_width = 14
		var scroll_max_height = MENU_MAX_HEIGHT
		var chosen_scroll_height = min(content_height, scroll_max_height)

		# Disable vertical scrollbar if content fits
		var has_overflow = content_height > scroll_max_height
		sub_has_scroll_overflow = has_overflow
		sub_scroll_max = maxf(0.0, content_height - chosen_scroll_height)
		sub_scroll_value = clampf(sub_scroll_value, 0.0, sub_scroll_max)
		var submenu_height = maxi(ROW_HEIGHT, int(chosen_scroll_height))
		var view_width = MENU_WIDTH - (scrollbar_width if has_overflow else 0)
		var sub_container = sub_scroll.get_parent() as Control
		if sub_container:
			sub_container.custom_minimum_size = Vector2(MENU_WIDTH, submenu_height)
			sub_container.size = Vector2(MENU_WIDTH, submenu_height)
		sub_scroll.custom_minimum_size = Vector2(view_width, chosen_scroll_height)
		sub_scroll.position = Vector2.ZERO
		sub_scroll.size = Vector2(view_width, chosen_scroll_height)
		if sub_list_margin:
			sub_list_margin.custom_minimum_size = Vector2(view_width, content_height)
			sub_list_margin.size = Vector2(view_width, content_height)
			sub_list_margin.position = Vector2(0, -sub_scroll_value)
		if sub_scrollbar:
			sub_scrollbar.visible = has_overflow
			sub_scrollbar.position = Vector2(view_width, 0)
			sub_scrollbar.size = Vector2(scrollbar_width, chosen_scroll_height)
			sub_scrollbar.min_value = 0.0
			sub_scrollbar.max_value = content_height
			sub_scrollbar.page = chosen_scroll_height
			sub_scrollbar.step = 1.0
			sub_scrollbar.value = sub_scroll_value
		if has_arrow_buttons:
			sub_scroll_up_btn.visible = has_overflow
			sub_scroll_down_btn.visible = has_overflow
			sub_scroll_up_btn.position = Vector2.ZERO
			sub_scroll_up_btn.size = Vector2(view_width, SCROLL_ARROW_HEIGHT)
			sub_scroll_down_btn.position = Vector2(0, chosen_scroll_height - SCROLL_ARROW_HEIGHT)
			sub_scroll_down_btn.size = Vector2(view_width, SCROLL_ARROW_HEIGHT)
		if not has_overflow:
			_set_sub_scroll_value(0.0)

		submenu_popup.min_size = Vector2i(MENU_WIDTH, submenu_height)
		submenu_popup.size = Vector2i(MENU_WIDTH, submenu_height)

		# Position submenu popup to the right of the main popup
		var x = position.x + size.x + 8
		var y = position.y

		if hovered_button and is_instance_valid(hovered_button):
			# Calculate screen y of hovered button: window pos + button local y
			y = position.y + int(hovered_button.global_position.y)
			# Clamp y so the submenu doesn't go below the main popup's bottom
			var max_y = position.y + size.y - submenu_popup.size.y
			y = clamp(y, position.y, max(position.y, max_y))

		submenu_popup.position = Vector2i(x, y)
		call_deferred("_update_sub_scroll_arrows")

func _set_highlight(index: int, scroll_to_item := true):
	# Clear previous highlight
	if highlighted_index >= 0 and highlighted_index < visible_items.size():
		var old_item = visible_items[highlighted_index]
		if is_instance_valid(old_item.button_node):
			var old_indent := int(old_item.button_node.get_meta("menu_indent", 12))
			var old_color: Color = old_item.button_node.get_meta("menu_base_color", Color("c8c8d4"))
			old_item.button_node.add_theme_color_override("font_color", old_color)
			old_item.button_node.add_theme_stylebox_override("normal", _make_empty_button_style(old_indent))

	highlighted_index = index
	if highlighted_index >= 0 and highlighted_index < visible_items.size():
		var new_item = visible_items[highlighted_index]
		if is_instance_valid(new_item.button_node):
			new_item.button_node.add_theme_color_override("font_color", Color.WHITE)
			var new_indent := int(new_item.button_node.get_meta("menu_indent", 12))
			new_item.button_node.add_theme_stylebox_override("normal", _make_button_style(SELECTED_BG_COLOR, new_indent))
			if scroll_to_item:
				_ensure_visible(new_item.button_node)

func _ensure_visible(ctrl: Control):
	var scroll_y = scroll.scroll_vertical
	var scroll_height = scroll.size.y
	var ctrl_y = ctrl.position.y
	var ctrl_height = ctrl.size.y

	if ctrl_y < scroll_y:
		scroll.scroll_vertical = int(ctrl_y)
	elif ctrl_y + ctrl_height > scroll_y + scroll_height:
		scroll.scroll_vertical = int(ctrl_y + ctrl_height - scroll_height)

func _select_item(item: Dictionary):
	if item.type == "node":
		_track_recently_used(item.key)
		node_selected.emit(item.key)
		hide()
	elif item.type == "action":
		action_selected.emit(item.key)
		hide()
	elif item.type == "input":
		input_selected.emit(item.key)
		hide()
	elif item.type == "output":
		output_selected.emit(item.key)
		hide()
	elif item.type == "category":
		_toggle_category(item.key)
	elif item.type == "back":
		current_category = ""
		rebuild_list()

func _track_recently_used(template_name: String):
	# Remove if already present
	var idx = recently_used.find(template_name)
	if idx >= 0:
		recently_used.remove_at(idx)
	# Insert at front
	recently_used.insert(0, template_name)
	# Trim to max
	if recently_used.size() > MAX_RECENT:
		recently_used.resize(MAX_RECENT)

func _on_search_text_changed(new_text: String):
	search_query = new_text
	rebuild_list()

func _on_line_edit_gui_input(event: InputEvent):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_UP:
				if visible_items.size() > 0:
					var next_idx = highlighted_index - 1
					if next_idx < 0:
						next_idx = visible_items.size() - 1
					_set_highlight(next_idx)
				get_viewport().set_input_as_handled()
			KEY_DOWN:
				if visible_items.size() > 0:
					var next_idx = (highlighted_index + 1) % visible_items.size()
					_set_highlight(next_idx)
				get_viewport().set_input_as_handled()
			KEY_LEFT:
				if highlighted_index >= 0 and highlighted_index < visible_items.size() and search_query == "":
					var item = visible_items[highlighted_index]
					var category_name := String(item.key if item.type == "category" else item.category)
					if not category_name.is_empty() and _is_category_expanded(category_name):
						_set_category_expanded(category_name, false)
						rebuild_list()
						_highlight_category(category_name)
						get_viewport().set_input_as_handled()
			KEY_RIGHT:
				if highlighted_index >= 0 and highlighted_index < visible_items.size() and search_query == "":
					var item = visible_items[highlighted_index]
					if item.type == "category" and not _is_category_expanded(item.key):
						_set_category_expanded(item.key, true)
						rebuild_list()
						_highlight_category(item.key)
						get_viewport().set_input_as_handled()
			KEY_ENTER:
				if highlighted_index >= 0 and highlighted_index < visible_items.size():
					_select_item(visible_items[highlighted_index])
				get_viewport().set_input_as_handled()
			KEY_ESCAPE:
				hide()
				get_viewport().set_input_as_handled()

func _get_category_for_template(template_name: String) -> String:
	for category in _CATEGORY_MAP.keys():
		if template_name in _CATEGORY_MAP[category]:
			return String(category)
	return "Utility"

func _on_id_pressed(id: int):
	var item = _id_to_item.get(id, {})
	if item.is_empty():
		return

	# Keyboard-driven flow: never auto-dismiss while the search box has focus.
	# Distance-based dismissal only applies once focus is lost.
	if line_edit and line_edit.has_focus():
		return

	# Bounding box calculation for automatic hide when mouse moves too far away
	# We use screen-level coordinates from DisplayServer to avoid clamping issues outside the popup window
	var mouse_screen_pos = DisplayServer.mouse_get_position()

	# Main popup screen rect
	var main_rect = Rect2(position, size)
	var dist = _dist_to_rect(mouse_screen_pos, main_rect)

	if submenu_popup.visible:
		var sub_rect = Rect2(submenu_popup.position, submenu_popup.size)
		var sub_dist = _dist_to_rect(mouse_screen_pos, sub_rect)
		dist = min(dist, sub_dist)

	if dist > POPUP_KEEPALIVE_DISTANCE:
		hide()

func _is_mouse_near_submenu_stack() -> bool:
	var mouse_screen_pos = DisplayServer.mouse_get_position()
	var main_rect = Rect2(position, size).grow(SUBMENU_KEEPALIVE_PADDING)
	if main_rect.has_point(mouse_screen_pos):
		return true
	if submenu_popup.visible:
		var sub_rect = Rect2(submenu_popup.position, submenu_popup.size).grow(SUBMENU_KEEPALIVE_PADDING)
		if sub_rect.has_point(mouse_screen_pos):
			return true
	return false

func _dist_to_rect(p: Vector2, rect: Rect2) -> float:
	var dx = max(rect.position.x - p.x, 0.0, p.x - rect.end.x)
	var dy = max(rect.position.y - p.y, 0.0, p.y - rect.end.y)
	return sqrt(dx*dx + dy*dy)
