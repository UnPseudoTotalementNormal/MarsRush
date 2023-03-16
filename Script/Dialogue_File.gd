extends Node2D
var language = "french"
var dialogue = {
	"french": {
		
	},
	"english": {
		
	}
}

func get_dialogue(ID: String):
	var file = dialogue[language]
	var dialogue = file[ID]
	return dialogue
