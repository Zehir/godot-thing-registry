extends EditorInspectorPlugin

const MODULE_HEADER = preload("uid://c4rqar0ymkyhg")

var _parse_property_ongoing: bool = false


@warning_ignore("unused_parameter")
func _can_handle(object: Object) -> bool:
	#return object is Thing
	return false


func _parse_begin(object: Object) -> void:
	if object is Thing:


		add_property_editor_for_multiple_properties(
			"Corner Properties",
			[
				"item/name",
				"item/icon",
			],
			EditorProperty.new()
		)
		prints("_parse_begin", object.get_modules())
	pass


@warning_ignore("unused_parameter")
func _parse_category(object: Object, category: String) -> void:
	pass
	#prints("_parse_category", object, category)


@warning_ignore("unused_parameter")
func _parse_end(object: Object) -> void:
	pass
	#prints("_parse_end", object)


@warning_ignore("unused_parameter")
func _parse_group(object: Object, group: String) -> void:

	pass
	#prints("_parse_group", object, group)



@warning_ignore("unused_parameter")
func _parse_property(object: Object, type: Variant.Type, name: String, hint_type: PropertyHint, hint_string: String, usage_flags: int, wide: bool) -> bool:
	if _parse_property_ongoing:
		return false

	if object is Thing:

		if hint_string == "ThingModuleGroup":
			#var base_inspector: EditorProperty = EditorInspector.instantiate_property_editor(object, type, name, hint_type, hint_string, usage_flags, wide)

			var base_inspector: EditorProperty = EditorProperty.new()
#
			base_inspector.set_object_and_property(object, name)
#
			_parse_property_ongoing = true
			var default_property_editor := EditorInspector.instantiate_property_editor(object, type, name, hint_type,
			 hint_string, usage_flags, wide)
			_parse_property_ongoing = false

			default_property_editor.label = "Fooo"


			add_custom_control(HSeparator.new())

			add_property_editor(name, default_property_editor)

			add_custom_control(MODULE_HEADER.instantiate())
			#
			#
			#var module_header: EditorProperty = load("uid://c1fxpydncodpj").new()
#
			#module_header.populate(object, name)
#
			#add_property_editor(name, module_header)


			return true



		#if name == &"modules":
			#var button: Button = Button.new()
			#button.text = "Add Module"
			#add_custom_control(button)
			#return true


	prints("_parse_property", object, type, name, hint_type, hint_string, usage_flags, wide)
	return false
