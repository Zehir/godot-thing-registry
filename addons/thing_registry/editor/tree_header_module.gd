@tool
class_name ThingTreeHeaderModule
extends Button


var _module: ThingModule
var _module_path: StringName


func _init(module: ThingModule, module_path: StringName) -> void:
	_module = module
	_module_path = module_path
	custom_minimum_size.x = 50.0
	text = "%s (%s)" % [_module.get_display_name(), module_path]
	icon = _module.get_icon()


func get_module() -> ThingModule:
	return _module
