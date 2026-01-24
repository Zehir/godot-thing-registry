@tool
class_name ThingUtils
extends RefCounted


static func set_parent(thing: Thing, new_parent: Thing) -> void:
	if not Engine.is_editor_hint():
		push_error("You can only change the parent in edit mode")
		return

	var current_parent: Thing = thing.parent
	if current_parent == new_parent:
		return

	if is_instance_valid(new_parent) and new_parent.is_child_of(thing):
		push_error("Can't set the new parent because it's currrently a child of this Thing.")
		return

	if is_instance_valid(new_parent):
		move_to(thing, new_parent.resource_path.get_basename().path_join(thing.resource_path.get_file()))
	else:
		move_to(thing, thing.get_root_path().path_join(thing.resource_path.get_file()))

	## Cleaup old directory if empty.
	if is_instance_valid(current_parent):
		var old_parent_dir: String = current_parent.resource_path.get_basename()
		if DirAccess.dir_exists_absolute(old_parent_dir):
			var old_parent: DirAccess = DirAccess.open(old_parent_dir)
			old_parent.include_hidden = true
			old_parent.include_navigational = false
			if old_parent.get_files().size() == 0 and old_parent.get_directories().size() == 0:
				DirAccess.remove_absolute(old_parent_dir)

	## Maybe we can do a less brute force than a full scan but it's fast for now.
	EditorInterface.get_resource_filesystem().scan()

	#TODO fix private call
	thing._update_modules_list()



static func rename(thing: Thing, new_name: String) -> bool:
	var new_path = thing.resource_path.get_base_dir().path_join(new_name.to_snake_case()) + "." + thing.resource_path.get_extension()
	if FileAccess.file_exists(new_path):
		return false

	thing.resource_name = new_name

	if thing.resource_path == new_path:
		return true

	move_to(thing, new_path)

	## Maybe we can do a less brute force than a full scan but it's fast for now.
	EditorInterface.get_resource_filesystem().scan()
	return true




static func move_to(thing: Thing, target_path: String) -> void:
	var old_thing_path: String = thing.resource_path.get_basename()
	var new_thing_path: String = target_path.get_basename()
	var moved: PackedStringArray = []

	## Make sure new parent have a directory for childs.
	var new_thing_dir: String = target_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(new_thing_dir):
		DirAccess.make_dir_recursive_absolute(new_thing_dir)

	## Move existing childs Thing.
	if DirAccess.dir_exists_absolute(old_thing_path):
		DirAccess.rename_absolute(old_thing_path, new_thing_path)
		moved.append(new_thing_path + "/")

	## Move Thing.
	DirAccess.rename_absolute(thing.resource_path, target_path)
	moved.append(target_path)

	## Update resource cache and resource_path for moved files.
	var moved_path: String = ""
	var moved_resource: Resource
	while moved.size() > 0:
		moved_path = moved.get(0)
		moved.remove_at(0)
		if moved_path.ends_with("/"):
			for sub_path in ResourceLoader.list_directory(moved_path):
				moved.append(moved_path.path_join(sub_path))
		else:
			var old_path = old_thing_path + moved_path.trim_prefix(new_thing_path)
			if ResourceLoader.has_cached(old_path):
				moved_resource = ResourceLoader.load(old_path, "", ResourceLoader.CACHE_MODE_REUSE)
				moved_resource.resource_path = moved_path
