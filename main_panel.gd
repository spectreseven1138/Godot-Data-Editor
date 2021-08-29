tool
extends Control

signal expand_all
signal collapse_all

var plugin: EditorPlugin

const recognised_file_extensions: Array = ["json", "gdjson"]
const data_dirs: Array = ["res://data/"]

const add_icon: Texture = preload("icons/Add.png")
const folder_icon: Texture = preload("icons/Folder.png")
onready var rename_icon: Texture = plugin.get_editor_interface().get_base_control().get_icon("TextEdit", "EditorIcons")

onready var data_container: VBoxContainer = $HBoxContainer/Values/VBoxContainer/PanelContainer2/ScrollContainer/VBoxContainer

enum file_tree_BUTTONS {CREATE_NEW}#, EDIT_NAME}
onready var file_tree: Tree = $HBoxContainer/VSplitContainer/Files/VBoxContainer/ScrollContainer/VBoxContainer/Tree
onready var selected_file_label: Label = $HBoxContainer/VSplitContainer/Files/VBoxContainer/SelectedFileLabel
onready var file_buttons: Container = $HBoxContainer/VSplitContainer/Files/VBoxContainer/Buttons

onready var data_tree: Tree = $HBoxContainer/VSplitContainer/Data/VBoxContainer/ScrollContainer/VBoxContainer/Tree
onready var data_buttons: Container = $HBoxContainer/VSplitContainer/Data/VBoxContainer/Buttons

onready var bottom_bar: Control = $HBoxContainer/Values/VBoxContainer/BottomBar

# The maximum nesting level to expand by default in the data tree
const data_tree_max_expand_depth: int = -1

var current_file = null
var current_file_data = null

func _ready():
	file_tree.connect("item_selected", self, "fileTree_item_selected")
	file_tree.connect("item_activated", self, "fileTree_item_double_clicked")
	data_tree.connect("item_activated", self, "dataTree_item_double_clicked")
	data_tree.connect("item_rmb_selected", self, "dataTree_item_rmb_selected")
	reload_file_tree()
	bottom_bar.get_node("Left/IndicatorLabel").visible = false
	
	if plugin.config_data["startup_file"] != null:
		var dir: Directory = Directory.new()
		if not dir.file_exists(plugin.config_data["startup_file"]):
			indicator_notification("Startup file does not exist", true)
		else:
			load_file(plugin.config_data["startup_file"])
	
	# Prepare NewFileDialog
	$NewFileDialog.get_ok().queue_free()
	$NewFileDialog.add_button("Folder", true, "folder")
	$NewFileDialog.add_button("Data file", true, "file")
	
	# Prepare TypeSelectMenu
	$TypeSelectMenu.clear()
	for type in plugin.value_types:
		$TypeSelectMenu.add_item(type)
	$TypeSelectMenu.add_separator(" ")
	$TypeSelectMenu.add_item("Cancel")
	
	for button in file_buttons.get_children():
		button.disabled = true
	for button in data_buttons.get_children():
		button.disabled = true

func indicator_notification(message: String, warning: bool = false):
	bottom_bar.get_node("Left/IndicatorLabel").text = message
	bottom_bar.get_node("Left/IndicatorLabel").modulate = Color.red if warning else Color.white
	bottom_bar.get_node("Left/IndicatorLabel").visible = true

func reload_file_tree():
	file_tree.clear()
	var tree_root: TreeItem = file_tree.create_item()
	
	var dirs_to_add: Array = []
	for data_dir in data_dirs:
		dirs_to_add.append([data_dir, tree_root])
	
	var all_dir_items: Array = []
	var dir: Directory = Directory.new()
	while len(dirs_to_add) > 0:
		dir.open(dirs_to_add[0][0])
		for file in iterate_directory(dir):
			if dir.file_exists(file) and not file.get_extension() in recognised_file_extensions:
				continue
			
			var item: TreeItem = file_tree.create_item(dirs_to_add[0][1])
			item.set_text(0, file)
			if dir.dir_exists(file):
				item.set_meta("is_dir", true)
				item.set_meta("path", dirs_to_add[0][0] + file + "/")
				dirs_to_add.append([item.get_meta("path"), item])
				item.set_icon(0, folder_icon)
				item.add_button(0, add_icon, file_tree_BUTTONS.CREATE_NEW, false, "Create new...")
				all_dir_items.append(item)
			else:
				item.set_meta("is_dir", false)
				item.set_meta("path", dirs_to_add[0][0] + file)
#			item.add_button(0, rename_icon, file_tree_BUTTONS.EDIT_NAME, false, "Edit name")
		dirs_to_add.pop_front()
	
	fileTree_item_selected()
	
#	# Remove empty directory items
#	var changes_made: bool = true
#	while changes_made:
#		changes_made = false
#		for dir_item in all_dir_items:
#			if dir_item.get_children() == null and dir_item.get_parent() != null:
#				dir_item.get_parent().remove_child(dir_item)
#				changes_made = true

# Single click
func fileTree_item_selected():
	var item: TreeItem = file_tree.get_selected()
	if item == null:
		selected_file_label.text = ""
		for button in file_buttons.get_children():
			button.disabled = true
		return
	
	selected_file_label.text = item.get_meta("path")
	if not item.get_meta("is_dir"):
		selected_file_label.text = item.get_meta("path").get_file()
	else:
		selected_file_label.text = item.get_meta("path").trim_suffix("/").split("/")[-1]
	
	file_buttons.get_node("Load").disabled = item.get_meta("is_dir")
	file_buttons.get_node("Delete").disabled = false
	file_buttons.get_node("Rename").disabled = false
		

func fileTree_item_double_clicked():
	var item: TreeItem = file_tree.get_selected()
	if item.get_meta("is_dir"):
		item.collapsed = !item.collapsed
	else:
		load_file(item.get_meta("path"))

func load_file(file_path: String):
	var is_reload: bool = file_path == current_file
	current_file = file_path
	
	for node in data_container.get_children():
		node.queue_free()
	
	data_tree.clear()
	var root_tree_item: TreeItem = data_tree.create_item()
	current_file_data = plugin.load_json(file_path)
	for key in current_file_data["data"]:
		var container: Control = plugin.ValueContainer.instance()
		container.init(key, current_file_data["data"][key], plugin, self, data_tree.create_item(root_tree_item))
		data_container.add_child(container)
	
	data_buttons.get_node("PrettyFormatting").pressed = current_file_data["pretty"]
	for button in data_buttons.get_children():
		button.disabled = false
	
	indicator_notification(("Reloaded" if is_reload else "Loaded" + " file: " + file_path.get_file()))

func iterate_directory(dir: Directory) -> Array:
	var ret = []
	dir.list_dir_begin(true, true)
	var file_name = dir.get_next()
	while file_name != "":
		ret.append(file_name)
		file_name = dir.get_next()
	return ret

func _on_NewFileDialog_custom_action(action):
	$NewFileDialog.visible = false
	
	var item: TreeItem = $NewFileDialog.get_meta("item")
	
	var creation_item: TreeItem = file_tree.create_item(item)
	creation_item.set_meta("path", item.get_meta("path"))
	creation_item.set_meta("creation_item_type", action)
	creation_item.set_editable(0, true)
	creation_item.select(0)
	yield(get_tree(), "idle_frame")
	file_tree.edit_selected()

func _on_Tree_button_pressed(item: TreeItem, column: int, id: int):
	match id:
		file_tree_BUTTONS.CREATE_NEW:
			$NewFileDialog.set_meta("item", item)
			$NewFileDialog.popup_centered()
#		file_tree_BUTTONS.EDIT_NAME:
#			item.set_editable(0, true)
#			item.select(0)
#			yield(get_tree(), "idle_frame")
#			file_tree.edit_selected()
#			item.set_editable(0, false)

func _on_Tree_item_edited():
	var item: TreeItem = file_tree.get_edited()
	var path: String = item.get_meta("path").trim_suffix("/")
	
	if not item.get_text(0).is_valid_filename():
		$Alert.dialog_text = "Invalid filename"
		$Alert.popup_centered()
		reload_file_tree()
		return
	
	if item.has_meta("creation_item_type"):
		match item.get_meta("creation_item_type"):
			"folder":
				var dir: Directory = Directory.new()
				if dir.dir_exists(path + "/" + item.get_text(0)):
					$Alert.dialog_text = "Folder already exists"
					$Alert.popup_centered()
					reload_file_tree()
					return
				dir.open(path)
				dir.make_dir(item.get_text(0))
			"file":
				var file: File = File.new()
				if file.file_exists(path + "/" + item.get_text(0)):
					$Alert.dialog_text + "File already exists"
					$Alert.popup_centered()
					reload_file_tree()
					return
				file.open(path + "/" + item.get_text(0), File.WRITE)
				file.store_string("{}")
				file.close()
		
	else:
		var dir: Directory = Directory.new()
		if item.get_meta("is_dir"):
			dir.rename(path, path.replace(path.split("/")[-1], item.get_text(0)))
		else:
			dir.rename(path, path.get_base_dir() + "/" + item.get_text(0))
	
	reload_file_tree()

func get_type_from_user() -> String:
	$TypeSelectMenu.popup_centered()
	$TypeSelectMenu.rect_global_position = get_global_mouse_position()
	
	var selected_text: String = $TypeSelectMenu.get_item_text(yield($TypeSelectMenu, "id_pressed"))
	return selected_text if selected_text in plugin.value_types else null

func _on_Delete_pressed():
	var path: String = file_tree.get_selected().get_meta("path")
	$ConfirmationDialog.dialog_text = path.get_file() + " will be deleted permanently."
	$ConfirmationDialog.set_meta("action", "delete_file")
	$ConfirmationDialog.popup_centered()

func _on_ConfirmationDialog_confirmed():
	match $ConfirmationDialog.get_meta("action"):
		"delete_file":
			var item: TreeItem = file_tree.get_selected()
			var dir: Directory = Directory.new()
			dir.remove(item.get_meta("path"))
			reload_file_tree()

func _on_Load_pressed():
	var item: TreeItem = file_tree.get_selected()
	if not item.get_meta("is_dir"):
		load_file(item.get_meta("path"))

func _on_Rename_pressed():
	var item: TreeItem = file_tree.get_selected()
	item.set_editable(0, true)
	item.select(0)
	yield(get_tree(), "idle_frame")
	file_tree.edit_selected()
	item.set_editable(0, false)

func dataTree_item_double_clicked():
	var item: TreeItem = data_tree.get_selected()
	item.collapsed = !item.collapsed

func dataTree_item_rmb_selected(_position: Vector2):
	var item: TreeItem = data_tree.get_selected()
	data_go_to_item(item.get_meta("value_container"))

func data_go_to_item(value_container: Control):
	value_container.grab_focus()

func _on_ExpandButton_pressed():
	emit_signal("expand_all")

func _on_CollapseButton_pressed():
	emit_signal("collapse_all")

func _on_Save_pressed():
	if current_file == null:
		return
	var file = File.new()
	var error: int = file.open(current_file, File.WRITE)
	if error != OK:
		push_error("Error saving json file '" + current_file + "': " + str(error))
		return
	
	var string_data: String
	if data_buttons.get_node("PrettyFormatting").pressed:
		string_data = prettify_data(current_file_data)
#		string_data = JSON.print(current_file_data)
	else:
		string_data = JSON.print(current_file_data)
	file.store_string(string_data)
	file.close()

const json_brackets: Dictionary = {
	"}": "{",
	"]": "[",
	"'": "'",
	'"': '"'
}

func prettify_data(data: Dictionary) -> String:
	data = data.duplicate(true)
	
	var all_values: Dictionary = {data: {"depth": 0, "parent": null, "all_data": data}}
	var unprocessed_values: Array = [data]
	var max_depth: int = 0 
	while len(unprocessed_values) > 0:
		var value: Dictionary = all_values[unprocessed_values.pop_front()]
		value["node"] = plugin.value_types[value["all_data"]["type"].to_lower()]["scene"].instance()
		
		for v in value["node"].get_subvalues_from_data(value["all_data"]["data"]):
			unprocessed_values.append(v)
			all_values[v] = {"depth": value["depth"] + 1, "parent": value, "all_data": v}
			max_depth = max(max_depth, value["depth"] + 1)
	
	for depth in range(max_depth, -1, -1):
		for value in all_values.values():
			if not value["depth"] == depth:
				continue
			value["formatted_text"] = value["node"].prettify_data(all_values, value["all_data"], value["all_data"] == data, depth)
	
	for value in all_values.values():
		value["node"].queue_free()
	
	var ret: String = all_values[data]["formatted_text"]
	var current_string_char = null
	var i: int = 0
	while i < len(ret):
		var c: String = ret[i]
		i += 1
		
		if current_string_char != null:
			if current_string_char == c:
				current_string_char = null
			continue
		
		match c:
			":", ",":
				if ret[i] != "\n":
					ret = ret.insert(i, " ")
			'"', "'":
				current_string_char = c
	
	return ret


func _on_IndicatorLabel_pressed():
	bottom_bar.get_node("Left/IndicatorLabel").visible = false
