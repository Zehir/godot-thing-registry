@tool
extends EditorInspectorPlugin

var grabbing_default : bool = false

@warning_ignore("unused_parameter")
func _can_handle(object: Object) -> bool:
	return object is Thing
	#return false


func _parse_begin(object: Object) -> void:
	if object is Thing:
		pass
		#prints("_parse_begin", object.get_modules())
	pass


@warning_ignore("unused_parameter")
func _parse_category(object: Object, category: String) -> void:
	if category == Thing.resource_path.get_file():
		add_custom_control(ThingBreadcrumb.new(object, ThingBreadcrumb.Mode.THING))
		add_custom_control(ThingBreadcrumb.new(object, ThingBreadcrumb.Mode.INHERITS))
		add_custom_control(ThingBreadcrumb.new(object, ThingBreadcrumb.Mode.INHERITED_BY))



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

	#prints("parse_property", object, type, name, hint_type, hint_string, usage_flags, wide)
	if object is Thing:
		if hint_string == "ThingModuleHeader":
			add_custom_control(HSeparator.new())
			add_custom_control(ThingBreadcrumb.new(object, ThingBreadcrumb.Mode.MODULE, name))
			return true

		if name.contains(Thing.SEPERATOR):
			var default_property_editor := _get_inspector(object, type, name, hint_type, hint_string, usage_flags, wide)
			# Waiting for this PR for tooltip : https://github.com/godotengine/godot/pull/115182
			add_property_editor(name, default_property_editor, false, name.split(Thing.SEPERATOR, false, 1)[1].capitalize())
			return true

	return false


func _get_inspector(object: Object, type: Variant.Type, path: String, hint: PropertyHint, hint_text: String, usage: int, wide: bool) -> EditorProperty:
		grabbing_default = true
		var default_property_editor := EditorInspector.instantiate_property_editor(object, type, path, hint, hint_text, usage, wide)
		grabbing_default = false
		return default_property_editor



class ThingBreadcrumb extends MarginContainer:
	var label: RichTextLabel

	enum Mode {
		THING,
		INHERITS,
		INHERITED_BY,
		MODULE,
	}

	var _mode: Mode
	var _thing: Thing
	var _module: ThingModule
	var _module_instance_name: String
	const inherit_tooltip: String = "Path of the thing in the tree structure. Use the filesystem dock to change the structure.\nA Thing is a child when placed in a directory named after its parent.\n\nExample:\nthing.tres\nthing/child.tres"

	func _init(thing: Thing, mode: Mode, module_instance_name: String = "") -> void:
		_thing = thing
		_mode = mode
		_module_instance_name = module_instance_name

		label = RichTextLabel.new()
		label.fit_content = true
		label.meta_clicked.connect(_on_rich_text_label_meta_clicked)
		add_child(label)
		update_breadcrumb()

		_thing.parent_changed.connect(update_breadcrumb)


	func update_breadcrumb() -> void:
		label.clear()
		label.add_text(String(Mode.find_key(_mode)).capitalize())
		label.add_text(" : ")
		match _mode:
			Mode.THING:
				_add_thing(_thing)
			Mode.INHERITS:
				label.tooltip_text = inherit_tooltip
				var things: Array[Thing] = [_thing]
				while is_instance_valid(things[-1].parent):
					things.append(things[-1].parent)

				things.pop_front()
				visible = things.size() > 0
				for current_thing in things:
					_add_thing(current_thing)
					if current_thing != things[-1]:
						_add_left_arrow()
			Mode.INHERITED_BY:
				label.tooltip_text = inherit_tooltip

				var things: Array[Thing] = []

				for path: String in _thing.get_childs_paths():
					var maybe: Thing = Thing.load_thing_at(path)
					if is_instance_valid(maybe):
						things.append(maybe)
				visible = things.size() > 0
				for current_thing in things:
					_add_thing(current_thing)
					if current_thing != things[-1]:
						label.add_text(", ")
			Mode.MODULE:
				_module = _thing.get_modules().get(_module_instance_name)
				if not is_instance_valid(_module):
					push_error("Could not find module that have the instance '%s'" % _module_instance_name)
					queue_free.call_deferred()
					return

				label.tooltip_text = _module.get_description()

				label.add_image(_module.get_icon(), 16, 16)
				label.add_text(" ")
				label.push_meta(_module, RichTextLabel.META_UNDERLINE_ON_HOVER, "Edit module\n%s" % _module.resource_path)
				label.add_text(_module.get_display_name())
				label.pop()

				if not _thing.modules.has(_module):
					var module_owner: Thing = _thing.parent
					while not module_owner.modules.has(_module):
						module_owner = module_owner.parent
					_add_left_arrow()
					_add_thing(module_owner)


	func _add_thing(thing: Thing) -> void:
		label.add_text(" ")
		label.add_image(EditorInterface.get_editor_theme().get_icon("ResourcePreloader", "EditorIcons"), 16, 16)
		label.add_text(" ")

		label.push_meta(thing, RichTextLabel.META_UNDERLINE_ON_HOVER, "Edit thing")
		label.add_text(thing.get_display_name())
		label.pop()


	func _add_left_arrow() -> void:
		label.add_text(" ")
		label.add_image(EditorInterface.get_editor_theme().get_icon("PagePrevious", "EditorIcons"), 16, 16)
		label.add_text(" ")

	func _add_right_arrow() -> void:
		label.add_text(" ")
		label.add_image(EditorInterface.get_editor_theme().get_icon("PageNext", "EditorIcons"), 16, 16)
		label.add_text(" ")



	func _on_rich_text_label_meta_clicked(meta: Variant) -> void:
		if meta is Thing or meta is ThingModule:
			EditorInterface.edit_resource.call_deferred(meta)
