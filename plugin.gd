tool
extends EditorPlugin

var plugin_dir_path: String

const plugin_icon: Texture = preload("icon.png")
const MainPanel = preload("main_panel.tscn")
const ValueContainer = preload("value_container.tscn")
var main_panel: Control

const config_filename: String = "config.json"
var config_data: Dictionary

var font: Font
const value_types: Dictionary = {
	"vector2": {"scene": preload("value_types/vector2.tscn")},
	"string": {"scene": preload("value_types/string.tscn")},
	"array": {"scene": preload("value_types/array.tscn")},
	"dictionary": {"scene": preload("value_types/dictionary.tscn")},
	"colour": {"scene": preload("value_types/string.tscn")},
}

func _enter_tree():
	plugin_dir_path = MainPanel.resource_path.get_base_dir() + "/"
	
	font = get_editor_interface().get_base_control().theme.get_font("main", "EditorFonts")
	config_data = load_json(plugin_dir_path + config_filename)
	
	main_panel = MainPanel.instance()
	main_panel.plugin = self
	
	get_editor_interface().get_editor_viewport().add_child(main_panel)
	make_visible(false)
	
#	get_plugin_icon().get_data().save_png(("res://bruh"))

func _exit_tree():
	if main_panel:
		main_panel.queue_free()

func has_main_screen():
	return true

func make_visible(visible):
	if main_panel:
		main_panel.visible = visible

func get_plugin_name() -> String:
	return "Data"

func get_plugin_icon() -> Texture:
	return plugin_icon

func get_string_height(control, lines: int):
	var line_spacing: int = control.get("custom_constants/line_spacing") if control != null else 5
	return (font.get_height() + line_spacing) * (lines + 0.35)

func load_json(path: String):
	var f = File.new()
	if not f.file_exists(path):
		return null
	f.open(path, File.READ)
	var data = f.get_as_text()
	f.close()
	return JSON.parse(data).result

func save_json(path: String, data, pretty: bool = false):
	var f = File.new()
	var error: int = f.open(path, File.WRITE)
	if error != OK:
		push_error("Error saving json file '" + path + "': " + str(error))
		return
	f.store_string(JSON.print(data, "\t" if pretty else ""))
	f.close()
