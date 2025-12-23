@tool
extends Resource
class_name ThingDefinition


@export var class_id: StringName
@export var parent_class_id: StringName

@export var properties: Array[ThingProperty] = []
