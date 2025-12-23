extends Resource
class_name ThingDatabase

const ThingDefinition = preload("uid://bv17pvlus3fap")

@export_dir var base_directory: String

@export var things: Dictionary[StringName, ThingDefinition]
