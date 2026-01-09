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


	var base = (ThingResource as GDScript).get_base_script()

	var item: Thing = Thing.new()
	item.set_script(ThingItem)
	item.set_script(ThingResource)

	print(item.toto)





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
	@export var _class: StringName
	@export var _parent_class: StringName

	const revertable_properties: Array[StringName] = [
		&"_display_name",
		&"_class",
		&"_parent_class"
	]

	var _base_script: GDScript

	func _init(base_script: GDScript) -> void:
		_base_script = base_script
		for property in revertable_properties:
			set(property, _property_get_revert(property))

		if not _base_script.resource_name.is_empty():
			_display_name = _base_script.resource_name

		# TODO load / save metadata somewhere ? # https://github.com/godotengine/godot/issues/84653

	func _get_property_list() -> Array[Dictionary]:
		var properties: Array[Dictionary] = []
		return properties

	func _validate_property(property: Dictionary) -> void:
		pass


	func _property_can_revert(property: StringName) -> bool:
		return revertable_properties.has(property)


	func _property_get_revert(property: StringName) -> Variant:
		match property:
			&"_display_name":
				var display_name = _base_script.get_global_name()
				if display_name.is_empty():
					display_name = _base_script.resource_path.get_file().trim_suffix(".gd").capitalize()
				display_name = display_name.trim_prefix("Thing")
				return display_name
			&"_class":
				return _base_script.get_global_name()
			&"_parent_class":
				return _base_script.get_base_script().get_global_name()
		return null


class CounterPartEditorInspectorPlugin extends EditorInspectorPlugin:
	func _can_handle(object):
		return object is CounterPart


	func _parse_property(object: Object, type: Variant.Type, name: String, hint_type: PropertyHint, hint_string: String, usage_flags: int, wide: bool) -> bool:
		if name == "script":
			return true
		return false
