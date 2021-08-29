tool
extends DataEditorValueType

const type: String = "Array"
const default_value: Dictionary = {"type": type, "data": []}

func init(_all_data: Dictionary, _plugin: EditorPlugin, _parent_container=null):
	.init(_all_data, _plugin, _parent_container)
	expand_data_in_pretty_file = true
	
	for value in data:
		var container: Control = plugin.ValueContainer.instance()
		container.init(null, value, plugin, parent_container, plugin.main_panel.data_tree.create_item(parent_container.tree_item))
		container.value_node.connect("data_changed", self, "on_child_data_changed")
		$ExpandedView.add_child(container)
	
	$Spacer.visible = false
	$Spacer2.visible = false
	$AddButton.visible = false
	$ExpandedView.visible = false
	
	$PreviewButton.text = get_preview()
	$PreviewButton.rect_min_size.y = plugin.get_string_height(null, 1)

const max_preview_items: int = 5
func get_preview() -> String:
	
	if $ExpandedView.get_child_count() == 0:
		return get_preview_short()
	
	var ret: String = "[ "
	for i in range($ExpandedView.get_child_count()):
		ret += $ExpandedView.get_child(i).value_node.get_preview_short()
		if i + 1 >= max_preview_items:
			ret += ", and " + str($ExpandedView.get_child_count() - i + 1) + " more"
			break
		elif i + 1 < $ExpandedView.get_child_count():
			ret += ", "
	return ret + " ]"

func get_preview_short() -> String:
	return type + "(" + (str($ExpandedView.get_child_count()) if $ExpandedView.get_child_count() > 0 else "Empty") + ")"

func _on_PreviewButton_pressed():
	if expanded:
		collapse()
	else:
		expand()

func expand():
	.expand()
	$ExpandedView.visible = true
	$Spacer.visible = true
	$Spacer2.visible = true
	$AddButton.visible = true

func collapse():
	.collapse()
	$ExpandedView.visible = false
	$Spacer.visible = false
	$Spacer2.visible = false
	$AddButton.visible = false

func _on_AddButton_pressed():
	var selected_type = yield(plugin.main_panel.get_type_from_user(), "completed")
	if selected_type == null:
		return
	
	var container: Node = plugin.ValueContainer.instance()
	container.init_blank(null, selected_type, plugin, parent_container, plugin.main_panel.data_tree.create_item(parent_container.tree_item))
	container.value_node.connect("data_changed", self, "on_child_data_changed")
	$ExpandedView.add_child(container)
	emit_signal("data_changed")

func on_data_changed():
	$PreviewButton.text = get_preview()

func on_child_data_changed():
	emit_signal("data_changed")

func get_subvalues() -> Array:
	return $ExpandedView.get_children()

func get_subvalues_from_data(data_override=null) -> Array:
	if data_override == null:
		data_override = data
	return data_override

func prettify_data(all_values: Dictionary, all_data: Dictionary, is_root: bool, depth: int) -> String:
	
	var ret: String = "{\n	" if is_root else "{"
	depth += 1
	
	for i in len(all_data):
		var key: String = all_data.keys()[i]
		ret += '"' + key + '":'
		if key == "data":
			ret += "[\n"
			for _i in len(all_data[key]):
				ret += "	".repeat(depth + 1)
				ret += all_values[all_data[key][_i]]["formatted_text"]
				if _i + 1 < len(all_data[key]): # If not the last element
					ret += ",\n"
			ret += "\n" + "	".repeat(depth) + "]"
		else:
			ret += JSON.print(all_data[key])
		if i + 1 < len(all_data): # If not the last element
			ret += ","
	ret += "\n}" if is_root else "}"
	
	return ret
