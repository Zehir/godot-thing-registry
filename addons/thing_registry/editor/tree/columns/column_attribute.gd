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

	if _property.get("type") in [TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING, TYPE_STRING_NAME]:
		adapter = TreeValueAdapterAttributeTextCast.new(self)
		return

	match [_property.get("type"), _property.get("hint"), _property.get("hint_string")]:
		[TYPE_OBJECT, PROPERTY_HINT_RESOURCE_TYPE, "Texture2D"]:
			adapter = TreeValueAdapterAttributeTexture2D.new(self)
		[_, _, _]:
			adapter = TreeValueAdapterMissing.new(self)


func get_module() -> ThingModule:
	return _module


func get_property() -> Dictionary:
	return _property
