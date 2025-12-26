@tool
extends Resource
class_name ThingDefinition


@export var uid: int
@export var parent_uid: int
@export var properties: Array[ThingProperty] = []


func _init() -> void:
	uid = ResourceUID.create_id()


func create_child_thing() -> ThingDefinition:
	var thing = ThingDefinition.new()
	thing.parent_uid = uid
	return thing
