@tool
extends HBoxContainer


func populate(thing: Thing, property_name: String) -> void:
	var module: ThingModule = thing.get_modules().get(property_name.trim_suffix("::enabled"))
#
	#icon.texture = module.get_module_icon()
	#label.text = module.get_module_name().capitalize()
	#if not thing.modules.has(module):
		#label.text += " (herited)"
