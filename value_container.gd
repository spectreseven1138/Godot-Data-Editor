tool
extends Control

const highlight_colours: Array = [Color("75a8d7"), Color("f7afff"), Color("74d792"), Color("d4d775")]

var plugin: EditorPlugin
var keyLabel: TextEdit

var parent_container: Control
var value_node: DataEditorValueType
var tree_item: TreeItem

func init(key, value, _plugin: EditorPlugin, _parent_container: Control, _tree_item: TreeItem):
	plugin = _plugin
	parent_container = _parent_container
	tree_item = _tree_item
	tree_item.set_meta("value_container", self)
	
	keyLabel = $HBoxContainer/KeyLabel
	if key == null:
		keyLabel.queue_free()
	else:
		keyLabel.text = key
	
	# DEBUG
	if not value["type"].to_lower() in plugin.value_types:
		queue_free()
		return
	var type_dict: Dictionary = plugin.value_types[value["type"].to_lower()]
	if type_dict["scene"]:
		value_node = type_dict["scene"].instance()
		value_node.init(value, plugin, self)
		plugin.main_panel.connect("expand_all", value_node, "expand")
		plugin.main_panel.connect("collapse_all", value_node, "collapse")
		$HBoxContainer.add_child(value_node)
	
	var tree_text: String = value_node.get_preview_short()
	if key != null:
		tree_text = key + ": " + tree_text
	tree_item.set_text(0, tree_text)
	
	tree_item.collapsed = get_depth_in_tree() > plugin.main_panel.data_tree_max_expand_depth

func init_blank(key, type: String, _plugin: EditorPlugin, _parent_container: Control, _tree_item: TreeItem):
	plugin = _plugin
	parent_container = _parent_container
	tree_item = _tree_item
	
	keyLabel = $HBoxContainer/KeyLabel
	if key == null:
		keyLabel.queue_free()
	else:
		keyLabel.text = key
	
	assert(type.to_lower() in plugin.value_types)
	var type_dict = plugin.value_types[type.to_lower()]
	if type_dict["scene"]:
		value_node = type_dict["scene"].instance()
		value_node.init_blank(plugin, self)
		plugin.main_panel.connect("expand_all", value_node, "expand")
		plugin.main_panel.connect("collapse_all", value_node, "collapse")
		$HBoxContainer.add_child(value_node)

func _ready():
	if not plugin:
		return
	_on_KeyLabel_text_changed()
	get("custom_styles/panel").border_color = highlight_colours[get_depth_in_tree() % len(highlight_colours)]

func _input(event: InputEvent):
	
	if is_instance_valid(keyLabel) and event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed and not keyLabel.get_global_rect().has_point(event.global_position):
		keyLabel.release_focus()

func _on_KeyLabel_text_changed():
	keyLabel.rect_min_size.x = plugin.font.get_string_size(keyLabel.text + "		").x
	
	if "\n" in keyLabel.text:
		keyLabel.text = keyLabel.text.replace("\n", "")
		keyLabel.release_focus()

func get_depth_in_tree() -> int:
	var current: Control = parent_container
	var depth: int = 0
	
	while current != plugin.main_panel:
		depth += 1
		current = current.parent_container

	return depth
