@tool
class_name Thing
extends Resource

signal module_changed()


## Parent thing
@export_custom(PROPERTY_HINT_RESOURCE_TYPE, "Thing", PROPERTY_USAGE_EDITOR)
var parent: Thing:
	get = get_parent


func get_root_path() -> String:
	var maybe_parent: Thing = get_parent()
	if is_instance_valid(maybe_parent):
		return maybe_parent.get_root_path()
	return resource_path.get_base_dir()


func have_child_directory() -> bool:
	return DirAccess.dir_exists_absolute(resource_path.get_basename())


static func load_thing_at(path: String) -> Thing:
	if not ResourceLoader.exists(path):
		return null
	var resource: Resource = load(path)
	if resource is Thing:
		return resource
	return null


## Return Thing resource path that is directly the child of this Thing.
## Return an empty array if no child if found. Does not return sub childs.
## The returned path might not be a Thing, you should use [method load_thing_at] to validate it.
func get_childs_paths() -> PackedStringArray:
	var list: PackedStringArray= []
	if not have_child_directory():
		return list

	for path: String in DirAccess.get_files_at(resource_path.get_basename()):
		list.append(resource_path.get_basename().path_join(path))
	return list


func get_parent() -> Thing:
	return load_thing_at(resource_path.get_base_dir() + ".tres")


## Reference to ThingModule scripts that could add properties
@export var modules: Array[ThingModule] = []:
	set(value):
		modules = value
		module_changed.emit()
		for module in modules:
			if not module.property_list_changed.is_connected(module_changed.emit):
				module.property_list_changed.connect(module_changed.emit)
@export_group("")

## Stores property values
var properties: Dictionary[StringName, Variant] = {}

var _is_loaded_modules_valid: bool = false

## Contains loaded modules for this Thing and its parents
var _loaded_modules: Dictionary[StringName, ThingModule] = {}


func _init() -> void:
	# Deferred call because "resource_path" it not always defined at that time.
	module_changed.connect.call_deferred(_on_module_changed)


func _on_module_changed():
	_update_modules_list()
	notify_property_list_changed()
	notify_childrens_property_list_changed()


## Notify childrens that their property list may have changed.
func notify_childrens_property_list_changed() -> void:
	for child_path in get_childs_paths():
		var child: Thing = load_thing_at(child_path)
		if child != null:
			child.notify_childrens_property_list_changed()
			child.notify_property_list_changed()


## Notify childrens that a property value has changed.
func notify_childrens_property_value_changed(property_name: StringName, old_value: Variant):
	for child_path in get_childs_paths():
		var child: Thing = load_thing_at(child_path)
		if child != null:
			child.notify_childrens_property_value_changed(property_name, old_value)
			child._on_parent_property_value_changed(property_name, old_value)


## Called when a parent property value has changed.
func _on_parent_property_value_changed(property_name: StringName, old_value: Variant):
	if get(property_name) == old_value:
		set(property_name, parent.get(property_name))


## Load modules from parent and self.
## The returned Dictionary contain module name and ThingModule
func get_modules(force_refresh: bool = false) -> Dictionary[StringName, ThingModule]:
	if force_refresh or not _is_loaded_modules_valid:
		_update_modules_list()
	return _loaded_modules


func _update_modules_list() -> void:
	_loaded_modules.clear()
	if parent is Thing:
		_loaded_modules.assign(parent.get_modules())
	for module in modules:
		if not module is ThingModule:
			continue
		var instance_name: StringName = module.get_instance_name()
		if _loaded_modules.has(instance_name):
			#TODO allow multiple modules if they can be, need to add a flag on the module to allow duplicates
			push_error("The thing '%s' already have the module '%s'." % [
				resource_path,
				module.get_script().get_global_name() if module.get_script() is GDScript else "Invalid script"
			])
			continue
		_loaded_modules.set(instance_name, module)
	_is_loaded_modules_valid = true


func has_module(instance_name: StringName) -> bool:
	#TODO optimise by looking parent if modules are not loaded ?
	if not _is_loaded_modules_valid:
		_update_modules_list()
	return _loaded_modules.has(instance_name)


func _get_property_list() -> Array[Dictionary]:
	var properties_list: Array[Dictionary] = []
	var modules_list: Dictionary[StringName, ThingModule] = get_modules()
	var module_ids: Array[StringName] = modules_list.keys()
	module_ids.sort()
	for module_name: StringName in module_ids:
		var module: ThingModule = modules_list.get(module_name)
		var module_properties: Array = module.get_thing_property_list()
		for property in module_properties:
			property.name = module.get_property_fullname(property.name)
			if not properties.has(property.name) and property_can_revert(property.name):
				properties.set(property.name, property_get_revert(property.name))

		if module_properties.size() > 0:
			properties_list.append({
				"name": module.get_instance_name(),
				"type": TYPE_NIL,
				"hint": PROPERTY_HINT_NONE,
				"hint_string": "ThingModuleHeader",
				"usage": PROPERTY_USAGE_EDITOR
			})
			properties_list.append_array(module_properties)
	return properties_list


## Call a method on the module that handle the given property.
func call_module_property_method(property: StringName, method: StringName, arguments: Array = [], default: Variant = null) -> Variant:
	if not property.contains(":"):
		return default
	var parts: PackedStringArray = property.split(":", true, 1)
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
	if not property.name.contains(":"):
		return

	if property_can_revert(property.name):
		if get(property.name) == property_get_revert(property.name):
			property.usage &= ~PROPERTY_USAGE_STORAGE


func _set(property: StringName, value: Variant) -> bool:
	if not property.contains(":"):
		return false
	var old_value = properties.get(property)
	properties.set(property, value)
	notify_childrens_property_value_changed(property, old_value)
	return true


func _get(property: StringName) -> Variant:
	if not property.contains(":"):
		return null
	return properties.get(property)


func get_display_name() -> String:
	if not resource_name.is_empty():
		return resource_name
	else:
		return resource_path.get_file().trim_suffix(".tres").capitalize()


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
	#ThingUtils.set_parent(self, items)
	#set_parent(null)
	#prints("root", get_root_path())
	#if not is_instance_valid(parent):
		#set(&"item:name", "ID %d" % randi())
