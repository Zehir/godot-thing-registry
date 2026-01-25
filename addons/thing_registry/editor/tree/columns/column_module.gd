@tool
class_name ThingTreeColumnModule
extends ThingTreeColumn

var _module: ThingModule

func _init(module: ThingModule) -> void:
	_module = module
	adapter = TreeValueAdapterModule.new(self)


func get_module() -> ThingModule:
	return _module
