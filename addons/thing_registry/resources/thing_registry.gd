@tool
extends Node


static func is_valid_thing_script(script: GDScript, display_warnings: bool = false) -> bool:
	if not script.get_instance_base_type() == "Resource":
		if display_warnings:
			push_warning("Script is not a child class of 'Resource' at '%s'" % script.resource_path)
		return false
	if script.is_abstract():
		if display_warnings:
			push_warning("Script is abstract at '%s'" % script.resource_path)
		return false
	if not script.is_tool():
		if display_warnings:
			push_warning("Script is missing the @tool anotation at '%s'" % script.resource_path)
		return false
	if not script.can_instantiate():
		if display_warnings:
			push_warning("Script can't be instantiated at '%s'" % script.resource_path)
		return false

	var base_script: Script = script.get_base_script()
	while base_script != null:
		if base_script == Thing:
			return true
		base_script = base_script.get_base_script()

	if display_warnings:
		push_warning("Script is not a child class of the Thing class at '%s'" % script.resource_path)
	return false
