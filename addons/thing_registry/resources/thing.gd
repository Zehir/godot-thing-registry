@tool
class_name Thing
extends Resource

signal module_changed()


@export_custom(PROPERTY_HINT_RESOURCE_TYPE, "Thing", PROPERTY_USAGE_EDITOR)
var parent: Thing:
	get = get_parent, set = set_parent


func get_root_path() -> String:
	var maybe_parent: Thing = get_parent()
	if is_instance_valid(maybe_parent):
		return maybe_parent.get_root_path()
	return resource_path.get_base_dir()


func have_child_directory() -> bool:
	return DirAccess.dir_exists_absolute(resource_path.get_basename())


## Return Thing resource path that is directly the child of this Thing.
## Return an empty array if no child if found. Does not return sub childs.
func get_childs_paths() -> PackedStringArray:
	var list: PackedStringArray= []
	if not have_child_directory():
		return list

	for path: String in DirAccess.get_files_at(resource_path.get_basename()):
		var child_path: String = resource_path.get_basename().path_join(path)
		if ResourceLoader.exists(child_path, "Thing"):
			list.append(child_path)
	return list


func rename(new_name: String) -> bool:
	var new_path = resource_path.get_base_dir().path_join(new_name.to_snake_case()) + "." + resource_path.get_extension()
	if FileAccess.file_exists(new_path):
		return false

	resource_name = new_name

	if resource_path == new_path:
		return true

	_move_to(new_path)

	## Maybe we can do a less brute force than a full scan but it's fast for now.
	EditorInterface.get_resource_filesystem().scan()
	return true


func get_parent() -> Thing:
	var parent_path: String = resource_path.get_base_dir() + ".tres"
	return load(parent_path) if ResourceLoader.exists(parent_path, "Thing") else null


func set_parent(new_parent: Thing) -> void:
	if not Engine.is_editor_hint():
		push_error("You can only change the parent in edit mode")
		return

	var current_parent: Thing = parent
	if current_parent == new_parent:
		return

	if is_instance_valid(new_parent) and new_parent.is_child_of(self):
		push_error("Can't set the new parent because it's currrently a child of this Thing.")
		return

	if is_instance_valid(new_parent):
		_move_to(new_parent.resource_path.get_basename().path_join(resource_path.get_file()))
	else:
		_move_to(get_root_path().path_join(resource_path.get_file()))

	## Cleaup old directory if empty.
	if is_instance_valid(current_parent):
		var old_parent_dir: String = current_parent.resource_path.get_basename()
		if DirAccess.dir_exists_absolute(old_parent_dir):
			var old_parent: DirAccess = DirAccess.open(old_parent_dir)
			old_parent.include_hidden = true
			old_parent.include_navigational = false
			if old_parent.get_files().size() == 0 and old_parent.get_directories().size() == 0:
				DirAccess.remove_absolute(old_parent_dir)

	## Maybe we can do a less brute force than a full scan but it's fast for now.
	EditorInterface.get_resource_filesystem().scan()


func _move_to(target_path: String) -> void:
	var old_thing_dir: String = resource_path.get_base_dir()
	var new_thing_dir: String = target_path.get_base_dir()
	var old_child_dir: String = resource_path.get_basename()
	var new_child_dir: String = target_path.get_basename()
	var moved: PackedStringArray = []

	## Make sure new parent have a directory for childs.
	if not DirAccess.dir_exists_absolute(new_thing_dir):
		DirAccess.make_dir_recursive_absolute(new_thing_dir)

	## Move existing childs Thing.
	if DirAccess.dir_exists_absolute(old_child_dir):
		DirAccess.rename_absolute(old_child_dir, new_child_dir)
		moved.append(new_child_dir + "/")

	## Move Thing.
	DirAccess.rename_absolute(resource_path, target_path)
	moved.append(target_path)

	## Update resource cache and resource_path for moved files.
	var moved_path: String = ""
	var moved_resource: Resource
	while moved.size() > 0:
		moved_path = moved.get(0)
		moved.remove_at(0)
		if moved_path.ends_with("/"):
			for sub_path in ResourceLoader.list_directory(moved_path):
				moved.append(moved_path.path_join(sub_path))
		else:
			var old_path = old_child_dir + moved_path.trim_prefix(new_child_dir)
			if ResourceLoader.has_cached(old_path):
				moved_resource = ResourceLoader.load(old_path, "", ResourceLoader.CACHE_MODE_REUSE)
				moved_resource.resource_path = moved_path


## Reference to ThingModule scripts that could add properties
@export var modules: Array[ThingModule] = []:
	set(value):
		modules = value
		module_changed.emit()
@export_group("")

## Stores property values
var properties: Dictionary[StringName, Variant] = {}

## Contains loaded modules for this Thing and its parents
var _loaded_modules: Dictionary[StringName, ThingModule] = {}


func _init() -> void:
	module_changed.connect(_on_module_changed)
	_on_module_changed()


func _on_module_changed():
	_loaded_modules = get_modules(true)
	notify_property_list_changed()
	notify_childrens_property_list_changed()


## Notify childrens that their property list may have changed.
func notify_childrens_property_list_changed() -> void:
	for child_path in get_childs_paths():
		var child: Resource = load(child_path)
		if child is Thing:
			child.notify_childrens_property_list_changed()
			child.notify_property_list_changed()


## Notify childrens that a property value has changed.
func notify_childrens_property_value_changed(property_name: StringName, old_value: Variant):
	for child_path in get_childs_paths():
		var child: Resource = load(child_path)
		if child is Thing:
			child.notify_childrens_property_value_changed(property_name, old_value)
			child._on_parent_property_value_changed(property_name, old_value)


## Called when a parent property value has changed.
func _on_parent_property_value_changed(property_name: StringName, old_value: Variant):
	if get(property_name) == old_value:
		set(property_name, parent.get(property_name))


## Load modules from parent and self.
## The returned Dictionary contain module name and ThingModule
func get_modules(force_refresh: bool = false) -> Dictionary[StringName, ThingModule]:
	if not force_refresh and is_instance_valid(_loaded_modules):
		return _loaded_modules

	var modules_list: Dictionary[StringName, ThingModule] = {}
	if parent is Thing:
		modules_list = parent.get_modules()
	for module in modules:
		if not module is ThingModule:
			continue
		var name: String = module.get_module_name()
		if modules_list.has(name):
			push_error("The thing '%s' already have the module '%s'." % [
				resource_path,
				module.get_script().get_global_name() if module.get_script() is GDScript else "Invalid script"
			])
			continue
		modules_list.set(name, module)

	return modules_list


func _get_property_list() -> Array[Dictionary]:
	var properties_list: Array[Dictionary] = []
	var modules_list: Dictionary[StringName, ThingModule] = get_modules()
	for module_name: StringName in modules_list.keys():
		var module_properties: Array = modules_list.get(module_name).get_thing_property_list()
		for property in module_properties:
			property.name = module_name + "/" + property.name
			if not properties.has(property.name) and property_can_revert(property.name):
				properties.set(property.name, property_get_revert(property.name))

		if module_properties.size() > 0:
			properties_list.append({
				"name": module_name.capitalize(),
				"class_name": &"",
				"type": 0,
				"hint": 0,
				"hint_string": module_name + "/",
				"usage": PROPERTY_USAGE_GROUP
			})
			properties_list.append_array(module_properties)
	return properties_list


## Call a method on the module that handle the given property.
func call_module_property_method(property: StringName, method: StringName, arguments: Array = [], default: Variant = null) -> Variant:
	if not property.contains("/"):
		return default
	var parts: PackedStringArray = property.split("/", true, 1)
	var module: ThingModule = get_modules().get(parts[0])
	if not is_instance_valid(module):
		return default
	if module.has_method(method):
		var argument_list = arguments.duplicate()
		argument_list.push_front(parts[1])
		return module.callv(method, argument_list)
	return default


func _property_can_revert(property: StringName) -> bool:
	if property == &"resource_name":
		return true
	return call_module_property_method(property, &"thing_property_can_revert", [self], false)


func _property_get_revert(property: StringName) -> Variant:
	if property == &"resource_name":
		return ""
	return call_module_property_method(property, &"thing_property_get_revert", [self], null)


func _validate_property(property: Dictionary) -> void:
	if not property.name.contains("/"):
		return

	if property_can_revert(property.name):
		if get(property.name) == property_get_revert(property.name):
			property.usage &= ~PROPERTY_USAGE_STORAGE


func _set(property: StringName, value: Variant) -> bool:
	if not property.contains("/"):
		return false
	var old_value = properties.get(property)
	properties.set(property, value)
	notify_childrens_property_value_changed(property, old_value)
	return true


func _get(property: StringName) -> Variant:
	if not property.contains("/"):
		return null
	return properties.get(property)


func is_child_of(other: Thing) -> bool:
	var current: Thing = self
	while is_instance_valid(current.parent):
		if current.parent == other:
			return true
		current = current.parent
	return false


#@export_tool_button("Debug") var debug_action = debug
#func debug():
	#var items: Thing = load("uid://dd6uaa4frttpn")
	#parent = items
	#set_parent(null)
	#prints("root", get_root_path())
	#if not is_instance_valid(parent):
		#set(&"item/name", "ID %d" % randi())
