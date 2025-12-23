@tool
extends MarginContainer

const FilesystemPanel = preload("uid://cv6tebjxh2fr8")

@export var filesystem_panel: FilesystemPanel


static func get_scene() -> PackedScene:
	return load("uid://bybjt46vqisvu")
