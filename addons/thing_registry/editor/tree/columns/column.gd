@tool
class_name ThingTreeColumn
extends Button

enum SortMethod {
	NONE,
	DESCENDING,
	ASCENDING,
}


var sort: SortMethod = SortMethod.NONE

var adapter: TreeValueAdapter
