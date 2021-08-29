tool
extends DataEditorValueType

const type: String = "String"
const default_value: Dictionary = {"type": type, "data": ""}

const max_reveal_lines: int = 10
var s: TextEdit

func init(_all_data: Dictionary, _plugin: EditorPlugin, _parent_container: Control):
	.init(_all_data, _plugin, _parent_container)
	s = self
	s.text = data
	s.clear_undo_history()
	_on_TextEdit_focus_exited()

func _input(event: InputEvent):
	if is_instance_valid(s) and event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
		if not s.get_global_rect().has_point(event.global_position):
			s.release_focus()
		else:
			update_size()

func _on_TextEdit_focus_exited():
	s.rect_min_size.y = plugin.get_string_height(self, 1)

func _on_TextEdit_text_changed():
	data = s.text
	all_data["data"] = data
	emit_signal("data_changed")
	update_size()

func update_size():
	s.rect_min_size.y = plugin.get_string_height(self, min(self.text.count("\n") + 1, max_reveal_lines))

func get_preview() -> String:
	if len(data) == 0:
		return "Empty " + type
	else:
		return data.strip_escapes()

func get_preview_short() -> String:
	if len(data) == 0:
		return "Empty " + type
	else:
		var ret: String = data.strip_escapes() if len(data.strip_escapes()) <= 12 else (data.strip_escapes().left(10) + "..")
		return '"' + ret + '"'
