@tool
extends VBoxContainer


var _counterpart: CounterPart
var _inspector: EditorInspector


func _ready() -> void:
	_inspector = EditorInspector.new()
	_inspector.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_inspector)
	pass


func populate(script: GDScript):
	_counterpart = CounterPart.new(script)
	prints("populate", _counterpart)
	_inspector.edit(_counterpart)

	print(_inspector.get_edited_object().get(&"_class_name"))


func _on_filesystem_panel_thing_class_selected(script: GDScript) -> void:
	populate(script)


class CounterPart extends RefCounted:

	@export var display_name: String
	@export var _class_name: String
	@export var parent_class: String

	func _init(base_script: GDScript) -> void:
		display_name = base_script.resource_name
		_class_name = base_script.get_global_name()
		parent_class = base_script.get_base_script().get_global_name()
