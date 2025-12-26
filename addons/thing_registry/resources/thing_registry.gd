@tool
extends Resource
class_name ThingRegistry

@export_dir var base_directory: String

@export var _thing_definitions: Dictionary[int, ThingDefinition] : get = get_thing_definitions


signal thing_added(uid: int)
signal thing_removed(uid: int)


func get_thing_definitions() -> Dictionary[int, ThingDefinition]:
	return _thing_definitions


func add_thing(thing: ThingDefinition) -> void:
	_thing_definitions.set(thing.uid, thing)
	thing_added.emit(thing.uid)


func remove_thing(uid: int) -> void:
	_thing_definitions.erase(uid)
	thing_removed.emit(uid)
