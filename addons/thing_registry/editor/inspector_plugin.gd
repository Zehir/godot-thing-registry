@tool
extends EditorInspectorPlugin

var grabbing_default : bool = false

@warning_ignore("unused_parameter")
func _can_handle(object: Object) -> bool:
	return object is Thing
	#return false


func _parse_begin(object: Object) -> void:
	if object is Thing:
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

	#var property: EditorProperty = _get_inspector(object, TYPE_NIL, group, PROPERTY_HINT_NONE, "item/", PROPERTY_USAGE_GROUP, true)
	#add_property_editor(group, property)
	#prints("_parse_group", object, group)
	pass



@warning_ignore("unused_parameter")
func _parse_property(object: Object, type: Variant.Type, name: String, hint_type: PropertyHint, hint_string: String, usage_flags: int, wide: bool) -> bool:
	if grabbing_default:
		return false

	if object is Thing:

		if name == "parent":
			add_custom_control(ThingBreadcrumb.new(object, ThingBreadcrumb.Mode.THING_PATH))

		if hint_string == "ThingModuleHeader":
			add_custom_control(HSeparator.new())
			add_custom_control(ThingBreadcrumb.new(object, ThingBreadcrumb.Mode.MODULE_ORIGIN, name))
			return true

		if name.contains(":"):
			var default_property_editor := _get_inspector(object, type, name, hint_type, hint_string, usage_flags, wide)
			# Waiting for this PR for tooltip : https://github.com/godotengine/godot/pull/115182
			add_property_editor(name, default_property_editor, false, name.split(":", false, 1)[1].capitalize())
			return true

	return false


func _get_inspector(object: Object, type: Variant.Type, path: String, hint: PropertyHint, hint_text: String, usage: int, wide: bool) -> EditorProperty:
		grabbing_default = true
		var default_property_editor := EditorInspector.instantiate_property_editor(object, type, path, hint, hint_text, usage, wide)
		grabbing_default = false
		return default_property_editor



class ThingBreadcrumb extends MarginContainer:
	var label: RichTextLabel

	var _thing: Thing
	var _module: ThingModule

	enum Mode {
		THING_PATH,
		MODULE_ORIGIN,
	}

	func _init(thing: Thing, mode: Mode, module_instance_name: String = "") -> void:
		_thing = thing

		label = RichTextLabel.new()
		label.fit_content = true
		label.meta_clicked.connect(_on_rich_text_label_meta_clicked)
		add_child(label)

		match mode:
			Mode.THING_PATH:
				var things: Array[Thing] = [thing]
				while is_instance_valid(things[-1].parent):
					things.append(things[-1].parent)

				things.reverse()
				for current_thing in things:
					_add_thing(current_thing)
					if current_thing != things[-1]:
						_add_arrow()

			Mode.MODULE_ORIGIN:
				_module = thing.get_modules().get(module_instance_name)
				if not is_instance_valid(_module):
					push_error("Could not find module that have the instance '%s'" % module_instance_name)
					queue_free.call_deferred()
					return

				if not thing.modules.has(_module):
					var module_owner: Thing = thing.parent
					while not module_owner.modules.has(_module):
						module_owner = module_owner.parent

					_add_thing(module_owner)
					_add_arrow()

				label.add_image(_module.get_icon(), 16, 16)
				label.add_text(" ")
				label.push_meta(_module, RichTextLabel.META_UNDERLINE_ON_HOVER, "Edit module\n%s" % _module.resource_path)
				label.add_text(_module.get_display_name())
				label.pop()

				label.tooltip_text = _module.get_description()


	func _add_thing(thing: Thing) -> void:
		label.add_text(" ")
		label.add_image(EditorInterface.get_editor_theme().get_icon("ResourcePreloader", "EditorIcons"), 16, 16)
		label.add_text(" ")

		label.push_meta(thing, RichTextLabel.META_UNDERLINE_ON_HOVER, "Edit thing")
		label.add_text(thing.get_display_name())
		label.pop()


	func _add_arrow() -> void:
		label.add_text(" ")
		label.add_image(EditorInterface.get_editor_theme().get_icon("PageNext", "EditorIcons"), 16, 16)
		label.add_text(" ")



	func _on_rich_text_label_meta_clicked(meta: Variant) -> void:
		if meta is Thing or meta is ThingModule:
			EditorInterface.edit_resource.call_deferred(meta)
