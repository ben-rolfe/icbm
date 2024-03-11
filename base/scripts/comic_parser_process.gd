extends Object
class_name ComicParserProcess

enum Type {
	ADD_BUTTON,
	ADD_BG_BUTTON,
	IF_TRUE,
	IF_FALSE,
	IF_WAS_TRUE,
	WHILE_TRUE,
	WHILE_RETURN,
}

var type: Type
var id: int

func _init(type: Type, id: int):
	self.type = type
	self.id = id
