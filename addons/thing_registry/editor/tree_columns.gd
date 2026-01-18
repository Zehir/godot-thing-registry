@tool
extends HSplitContainer


@export var tree_content: ThingTree

func _ready() -> void:
	if is_part_of_edited_scene():
		return

	for i in tree_content.columns:
		var button: Button = Button.new()
		button.text = "Button #%d" % (i + 1)
		button.size.x = tree_content.get_column_width(i)
		add_child(button)
		button.resized.connect(_on_button_resized.bind(i, button))


func _on_button_resized(idx: int, button: Button) -> void:
	tree_content.set_column_custom_minimum_width(idx, roundi(button.size.x))
