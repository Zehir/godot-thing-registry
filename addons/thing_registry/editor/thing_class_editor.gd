@tool
extends VBoxContainer


var _counterpart: CounterPart


static func init_plugin(plugin: EditorPlugin) -> Callable:
	var inspector_plugin = CounterPartEditorInspectorPlugin.new()
	plugin.add_inspector_plugin(inspector_plugin)
	return plugin.remove_inspector_plugin.bind(inspector_plugin)


func populate(script: GDScript):
	unpopulate()
	_counterpart = CounterPart.new(script)

	var editor_inspector = EditorInterface.get_inspector()
	editor_inspector.edit(_counterpart)



func unpopulate():
	if is_instance_valid(_counterpart):
		_counterpart.free()

	for child in get_children():
		child.queue_free()


func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		unpopulate()


func _on_filesystem_panel_thing_class_selected(script: GDScript) -> void:
	populate(script)


class CounterPart extends Object:
	@export_category("Class definition")
	@export var _display_name: String
	@export var _class: String
	@export var _parent_class: String
	@export_category("Test number")


	@export var number_count = 3:
		set(nc):
			number_count = nc
			numbers.resize(number_count)
			notify_property_list_changed()

	var numbers = PackedInt32Array([0, 0, 0])

	func _init(base_script: GDScript) -> void:
		_display_name = base_script.resource_name
		_class = base_script.get_global_name()
		_parent_class = base_script.get_base_script().get_global_name()
		# TODO load / save metadata somewhere ? # https://github.com/godotengine/godot/issues/84653

	func _get_property_list() -> Array[Dictionary]:
		var properties: Array[Dictionary] = []

		for i in range(number_count):
			properties.append({
				"name": "number_%d" % i,
				"type": TYPE_INT,
				"hint": PROPERTY_HINT_ENUM,
				"hint_string": "ZERO,ONE,TWO,THREE,FOUR,FIVE",
			})



		return properties

	func _validate_property(property: Dictionary) -> void:
		#prints("_validate_property", property.name)
		if property.name == "script":
			property.usage = property.usage | PROPERTY_USAGE_NO_EDITOR

			#prints("script", property)

	func _get(property):
		if property.begins_with("number_"):
			var index = property.get_slice("_", 1).to_int()
			return numbers[index]

	func _set(property, value):
		if property.begins_with("number_"):
			var index = property.get_slice("_", 1).to_int()
			numbers[index] = value
			return true
		return false


class CounterPartEditorInspectorPlugin extends EditorInspectorPlugin:
	func _can_handle(object):
		return object is CounterPart


	func _parse_property(object: Object, type: Variant.Type, name: String, hint_type: PropertyHint, hint_string: String, usage_flags: int, wide: bool) -> bool:
		if name == "script":
			return true
		return false
