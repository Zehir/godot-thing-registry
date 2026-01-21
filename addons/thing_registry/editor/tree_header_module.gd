@tool
class_name ThingTreeHeaderModule
extends Button


var _module: ThingModule



func _init(module: ThingModule) -> void:
	_module = module
	custom_minimum_size.x = 50.0
	text = _module.get_module_name()


func get_module() -> ThingModule:
	return _module
