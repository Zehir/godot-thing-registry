@tool
class_name TreeValueAdapterAttributeTextCast
extends TreeValueAdapterAttribute

const VALID_TYPES: Array[Variant.Type] = [
	TYPE_INT,
	TYPE_FLOAT,
	TYPE_STRING,
	TYPE_VECTOR2,
	TYPE_VECTOR2I,
	TYPE_RECT2,
	TYPE_RECT2I,
	TYPE_VECTOR3,
	TYPE_VECTOR3I,
	TYPE_TRANSFORM2D,
	TYPE_VECTOR4,
	TYPE_VECTOR4I,
	TYPE_PLANE,
	TYPE_QUATERNION,
	TYPE_AABB,
	TYPE_BASIS,
	TYPE_TRANSFORM3D,
	TYPE_PROJECTION,
	TYPE_STRING_NAME,
	TYPE_OBJECT,
	TYPE_DICTIONARY,
	TYPE_ARRAY,
	TYPE_PACKED_BYTE_ARRAY,
	TYPE_PACKED_INT32_ARRAY,
	TYPE_PACKED_INT64_ARRAY,
	TYPE_PACKED_FLOAT32_ARRAY,
	TYPE_PACKED_FLOAT64_ARRAY,
	TYPE_PACKED_STRING_ARRAY,
	TYPE_PACKED_VECTOR2_ARRAY,
	TYPE_PACKED_VECTOR3_ARRAY,
	TYPE_PACKED_COLOR_ARRAY,
	TYPE_PACKED_VECTOR4_ARRAY,
]

const MULTI_LINE_TYPES: Array[Variant.Type] = [
	TYPE_OBJECT,
	TYPE_DICTIONARY,
]

var _expected_type: Variant.Type

func _init(header: ThingTreeColumnAttribute) -> void:
	super(header)
	_expected_type = header.get_property().type


func _update_column(tree_item: ThingTreeItem, column_index: int) -> void:
	var thing: Thing = tree_item.get_thing()
	var property: StringName = get_property_path()
	tree_item.set_editable(column_index, true)
	tree_item.set_selectable(column_index, true)
	tree_item.set_text_alignment(column_index, HORIZONTAL_ALIGNMENT_LEFT)
	tree_item.set_edit_multiline(column_index, _expected_type in MULTI_LINE_TYPES)
	var value: Variant = thing.get(property)

	if not thing.has_self(property):
		var tree: Tree = tree_item.get_tree()
		var color: Color = tree.get_theme_color(&"font_color")
		color.a *= 0.5
		tree_item.set_custom_color(column_index, color)
	else:
		tree_item.clear_custom_color(column_index)

	if value == null:
		tree_item.set_text(column_index, "")
	elif _expected_type in [TYPE_STRING, TYPE_STRING_NAME]:
		tree_item.set_text(column_index, String(value))
	else:
		tree_item.set_text(column_index, var_to_str(value))


func _on_edited(tree_item: ThingTreeItem, column_index: int) -> void:
	var thing: Thing = tree_item.get_thing()
	var property: StringName = get_property_path()
	var value: Variant = tree_item.get_text(column_index)
	if _expected_type in [TYPE_FLOAT, TYPE_INT]:
		value = "0%s" % value
	elif not _expected_type in [TYPE_STRING, TYPE_STRING_NAME]:
		value = str_to_var(value)
	value = type_convert(value, _expected_type)
	thing.set(property, value)
