@tool
class_name ThingTreeColumnResource
extends ThingTreeColumn

func _init() -> void:
	adapter = TreeValueAdapterResource.new(self)
