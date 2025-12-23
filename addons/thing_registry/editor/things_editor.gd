@tool
extends MarginContainer
const Menu = preload("uid://dsju3xwf6tler")

@export var file_button: MenuButton
@export var tree: Tree


func foo(test: String) -> void:
	print(test)


func _on_menu_action_pressed(action: Menu.Action) -> void:
	match action:
		Menu.Action.FILE_NEW_REGISTRY:
			#file_dialog.title = "New Thing Registry..."

			#for connection in file_dialog.file_selected.get_connections():
			#	file_dialog.file_selected.disconnect(connection.callable)

			#file_dialog.file_selected.connect(func (path: String):
			#	print(path)
			#	if ResourceLoader.exists(path):
			#		print("already exist")
			#	var new_registry = ThingRegistry.new()
			#	ResourceSaver.save(new_registry, )
			#, CONNECT_ONE_SHOT)
			#file_dialog.popup_centered()
			pass

	prints("_on_menu_action_pressed", Menu.Action.find_key(action))
