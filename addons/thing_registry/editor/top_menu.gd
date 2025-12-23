@tool
extends HBoxContainer
@export var file_button: MenuButton

signal action_pressed(action: Action)

enum Action {
	FILE_NEW_THING,
	FILE_NEW_REGISTRY,
	FILE_OPEN,
	FILE_SAVE,
	FILE_SAVE_ALL,
	FILE_SHOW_IN_FILESYSTEM,
	FILE_CLOSE,
	FILE_CLOSE_ALL,
	FILE_CLOSE_OTHER,
}


func _enter_tree() -> void:
	if is_part_of_edited_scene():
		return

	_init_menu()


func _init_menu() -> void:
	var file: PopupMenu = file_button.get_popup()
	file.id_pressed.connect(action_pressed.emit)
	_add_menu_item(file, Action.FILE_NEW_THING, tr("New Thing"), KeyModifierMask.KEY_MASK_CMD_OR_CTRL | KEY_N)
	_add_menu_item(file, Action.FILE_NEW_REGISTRY, tr("New Thing registry..."), KeyModifierMask.KEY_MASK_CMD_OR_CTRL | KeyModifierMask.KEY_MASK_SHIFT | KEY_N)
	_add_menu_item(file, Action.FILE_OPEN, tr("Open..."))
	file.add_separator()
	_add_menu_item(file, Action.FILE_SAVE, tr("Save"), KeyModifierMask.KEY_MASK_CMD_OR_CTRL | KEY_S)
	_add_menu_item(file, Action.FILE_SAVE_ALL, tr("Save All"), KeyModifierMask.KEY_MASK_ALT | KeyModifierMask.KEY_MASK_SHIFT | KEY_S)
	_add_menu_item(file, Action.FILE_SHOW_IN_FILESYSTEM, tr("Show in FileSystem"))
	file.add_separator()
	_add_menu_item(file, Action.FILE_CLOSE, tr("Close"), KeyModifierMask.KEY_MASK_CMD_OR_CTRL | KEY_W)
	_add_menu_item(file, Action.FILE_CLOSE_ALL, tr("Close All"))
	_add_menu_item(file, Action.FILE_CLOSE_OTHER, tr("Close Other registries"))


func _add_menu_item(popup: PopupMenu, id: Action, text: String, shortcut_key: Key = KEY_NONE) -> void:
	popup.add_item(tr(text), id)
	if shortcut_key != KEY_NONE:
		popup.set_item_shortcut(popup.get_item_index(id), _get_or_create_option_shortcut(id, shortcut_key), true)


func _get_or_create_option_shortcut(id: Action, shortcut_key: Key) -> Shortcut:
	var editorsettings: EditorSettings = EditorInterface.get_editor_settings()
	var shortcut_path = StringName("thing_editor/%s" % String(Action.find_key(id)).to_snake_case())

	if editorsettings.has_shortcut(shortcut_path):
		return editorsettings.get_shortcut(shortcut_path)

	var shortcut = Shortcut.new()
	var key_event = InputEventKey.new()
	key_event.keycode = shortcut_key & KeyModifierMask.KEY_CODE_MASK
	key_event.command_or_control_autoremap = shortcut_key & KeyModifierMask.KEY_MASK_CMD_OR_CTRL
	key_event.alt_pressed = shortcut_key & KeyModifierMask.KEY_MASK_ALT
	key_event.shift_pressed = shortcut_key & KeyModifierMask.KEY_MASK_SHIFT
	shortcut.events = [key_event]

	editorsettings.add_shortcut(shortcut_path, shortcut)

	return shortcut
