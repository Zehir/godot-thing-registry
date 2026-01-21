extends EditorInspectorPlugin


func _can_handle(object: Object) -> bool:
	return object is Thing
