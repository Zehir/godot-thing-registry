@tool
class_name ThingTreeColumnAttribute
extends ThingTreeColumn

var _module: ThingModule
# The same as _get_property_list()
var _property: Dictionary


@warning_ignore("shadowed_variable")
func _init(module: ThingModule, property: Dictionary) -> void:
	_module = module
	_property = property

	match property.get("type"):
		TYPE_STRING:
			adapter = TreeValueAdapterAttributeString.new(self)
		_:
			adapter = TreeValueAdapterMissing.new(self)


func get_module() -> ThingModule:
	return _module


func get_property() -> Dictionary:
	return _property
