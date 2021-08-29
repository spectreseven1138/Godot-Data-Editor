tool
extends DataEditorValueType

const type: String = "Vector2"
const default_value: Dictionary = {"type": type, "data": [0, 0]}

onready var textEdits: Dictionary = {
	"x": $X/TextEdit,
	"y": $Y/TextEdit
}

#func init(_all_data: Dictionary, _plugin: EditorPlugin, _parent_container: Control):
#	.init(_all_data, _plugin, _parent_container)

func _ready():
	update_text()
	for textEdit in textEdits.values():
		textEdit.rect_min_size.y = (plugin.font.get_height() + textEdit.get("custom_constants/line_spacing")) * 1.35

func _input(event: InputEvent):
	if textEdits and event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed:
		for textEdit in textEdits.values():
			if not textEdit.get_global_rect().has_point(event.global_position):
				textEdit.release_focus()

func _on_updown_button_pressed(index: int, direction: int):
	data[index] += sign(direction)
	emit_signal("data_changed")
	update_text()

func update_text():
	for i in [0, 1]:
		textEdits.values()[i].text = str(data[i])
		update_textedit_width(i)

func _process(_delta: float):
	if textEdits:
		for textEdit in textEdits.values():
			textEdit.scroll_vertical = 0

func get_textedit(index: int) -> TextEdit:
	return textEdits.values()[index]

func _on_TextEdit_text_changed(index: int):
	var textEdit: TextEdit = get_textedit(index)
	if "\n" in textEdit.text:
		textEdit.text = textEdit.text.replace("\n", "")
		apply_edited_text(index)
	else:
		update_textedit_width(index)

func apply_edited_text(index: int):
	var textEdit: TextEdit = get_textedit(index)
	data[index] = float(textEdit.text)
	emit_signal("data_changed")
	update_text()
	textEdit.release_focus()

func update_textedit_width(index: int):
	var textEdit: TextEdit = get_textedit(index)
	textEdit.rect_min_size.x = max(
		plugin.font.get_string_size(textEdit.text + "		").x,
		plugin.font.get_string_size("000		").x
		)

func get_preview() -> String:
	return "Vector2(" + str(data[0]) + ", " + str(data[1]) + ")"

func get_preview_short() -> String:
	return get_preview().replace(" ", "")
