extends Node
class_name DataEditorValueType

signal data_changed

var all_data: Dictionary
var data
var parent_container: Control
var plugin: EditorPlugin
var expanded: bool = false

var expand_data_in_pretty_file: bool = false

func init(_all_data: Dictionary, _plugin: EditorPlugin, _parent_container: Control) -> void:
	connect("data_changed", self, "on_data_changed")
	all_data = _all_data
	data = all_data["data"]
	plugin = _plugin
	parent_container = _parent_container

func init_blank(plugin: EditorPlugin, parent_container: Control) -> void:
	init(self.default_value, plugin, parent_container)

func get_preview() -> String:
	return "Template preview"

func get_preview_short() -> String:
	return get_preview()

func on_data_changed():
	pass

func expand():
	expanded = true

func collapse():
	expanded = false

func get_subvalues() -> Array:
	return []

func get_subvalues_from_data(data_override=null) -> Array:
	return []

func prettify_data(all_values: Dictionary, all_data: Dictionary, is_root: bool, depth: int) -> String:
	return JSON.print(all_data)
