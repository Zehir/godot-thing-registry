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

	match [_property.get("type"), _property.get("hint"), _property.get("hint_string")]:
		[TYPE_BOOL, _, _]:
			adapter = TreeValueAdapterAttributeBool.new(self)
		[TYPE_COLOR, _, _]:
			adapter = TreeValueAdapterAttributeColor.new(self)
		#[TYPE_OBJECT, PROPERTY_HINT_RESOURCE_TYPE, "Texture2D"]:
			#adapter = TreeValueAdapterAttributeTexture2D.new(self)
		[TYPE_OBJECT, PROPERTY_HINT_RESOURCE_TYPE, _]:
			adapter = TreeValueAdapterAttributeResource.new(self)

	if is_instance_valid(adapter):
		return

	if _property.get("type") in TreeValueAdapterAttributeTextCast.VALID_TYPES:
		adapter = TreeValueAdapterAttributeTextCast.new(self)
		return

	adapter = TreeValueAdapterMissing.new(self)


func get_module() -> ThingModule:
	return _module


func get_property() -> Dictionary:
	return _property
