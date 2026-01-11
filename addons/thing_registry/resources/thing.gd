@tool
class_name Thing
extends Resource

signal module_changed()


@export_custom(PROPERTY_HINT_RESOURCE_TYPE, "Thing", PROPERTY_USAGE_EDITOR) var parent: Thing:
	get():
		if parent_id.is_empty():
			return null
		return load(parent_id)
	set(value):
		if is_instance_valid(parent):
			parent.childs.erase.call_deferred(ResourceUID.path_to_uid(resource_path))
		if is_instance_valid(value):
			value.childs.append.call_deferred(ResourceUID.path_to_uid(resource_path))
			parent_id = ResourceUID.path_to_uid(value.resource_path)
		else:
			parent_id = ""
		notify_property_list_changed()

#TODO check for infinite loop
@export_storage var parent_id: StringName

## References to child Things
@export_storage var childs: Array[StringName] = []

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
	for child_uid in childs:
		var child: Resource = load(child_uid)
		if child is Thing:
			child.notify_childrens_property_list_changed()
			child.notify_property_list_changed()


## Notify childrens that a property value has changed.
func notify_childrens_property_value_changed(property_name: StringName, old_value: Variant):
	for child_uid in childs:
		var child: Resource = load(child_uid)
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
	return call_module_property_method(property, &"thing_property_can_revert", [self], false)


func _property_get_revert(property: StringName) -> Variant:
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
	#prints("debug", parent)
	#if not is_instance_valid(parent):
		#set(&"item/name", "ID %d" % randi())
