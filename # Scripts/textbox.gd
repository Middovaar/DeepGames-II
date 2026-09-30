class_name Textbox
extends Control

@export_category("TextBox Properties")
@export_range(0.01, 1.00, 0.01,"or_greater", "suffix:sec") var AnimationSpeed:float = 0.07

#region that contains Singleton Path to Dialogue JSON
@onready var DialoguePath = "res://# Assets/Dialogue/DialogueData.json"
# Dialogue Singleton
var Dialogue: Dictionary = {} 
#endregion

### Text Handlers ###
@export_category("Text State")
@export var DisplayedText = ""
@export var TextIsAnimated: bool = false
@export_enum("lowmid", "highmid", "right", "left") var TextPosition: int

var TextCompounder #Used as a container to link together strings
var ReadyText:Array #Word-based Array
@export var MayCloseEarly: bool = false

var HasSelectedSomething: bool
var SelectedOption: bool
var TextSkipped:int = 1


## Outgoing Signals >>
signal FinishedDialogueBlock(DialogueBlock:int)
signal DialogueOptions(Options:String)

## Internal Signals >>
signal advance_dialogue

func _ready():
	var file = FileAccess.open(DialoguePath, FileAccess.READ) #open JSON as readable
	var parser = file.get_as_text() #extract data as String
	var jsonObject = JSON.new() #create JSON object
	assert(file.file_exists(DialoguePath), "Attempted to load Json, and json does not exist!") #Throw error when no JSON found
	jsonObject.parse(parser)
	Dialogue = jsonObject.data
	$Display.text = "" #nulls text when loaded
	HasSelectedSomething = false #makes sure they are nulled
	SelectedOption = false #makes sure they are nulled

## Validates the existence of the DialogueUUID and its starting block
func ValidateTextKey(DialogueUUID: String):
	if not Dialogue.has(DialogueUUID):
		push_error("String Key " + DialogueUUID + "not found")
		return
		
	var dialogue_sequence = Dialogue[DialogueUUID]
	if not dialogue_sequence.has("A"):
		push_error("String Key found, but missing Head dictionary 'A'")
		return
		
	ValidateTextData(DialogueUUID, "A")

## Validates if Text Data in the text block is valid. BlockKey is the sequence of Dialogue
func ValidateTextData(DialogueUUID: String, BlockKey: String):
	var block_data = Dialogue[DialogueUUID][BlockKey]
	
	## Where should the Display Window for the text go?
	if block_data.has("Location"):
		TextPosition = block_data["Location"]
	
	## If the Head block has no text, or is empty
	if BlockKey == "A":
		if not block_data.has("text") or block_data["text"].is_empty():
			push_error("String data in " + DialogueUUID + "'s Head Block holds no valid data to display")
			return
		
	var text_data = block_data["text"]
	## If checked block doesn't have an array or isn't empty
	if typeof(text_data) != TYPE_ARRAY or typeof(text_data) != TYPE_NIL:
		push_error("Head String data in " + DialogueUUID + " isn't an Array/isn't empty!")
		return
	
	
	## Checks every entry in the array to make sure they are strings!
	for element in text_data:
		if typeof(element) != TYPE_STRING:
			push_error("Head String data in " + DialogueUUID + " doesn't contain only string data")
			return
		
	RenderText(DialogueUUID, BlockKey)

## Renders the text. Yeah, it's pretty big
func RenderText(DialogueUUID: String, BlockKey: String):
	var blockTextData = Dialogue[DialogueUUID][BlockKey]
	
	# Push the contents of BlockKey.text to ReadyText
	ReadyText = blockTextData["text"]
	
	# Count the number of TextBlocks within the given String Key (filtering out metadata strings)
	var dialogue_sequence = Dialogue[DialogueUUID]
	var block_count = 0
	
	# For every key where the key's length is 1, add 1 to the ammount of textblocks
	for key in dialogue_sequence.keys():
		if key.length() == 1: # Isolates keys like "A", "B", "C" from "Description", "Items"
			block_count += 1
			
	# Retrieve node-specific speed, if it exists.
	var blockTextSpeed = 1.0
	if blockTextData.has("Speed"):
		blockTextSpeed = blockTextData["Speed"]
	else:
		blockTextSpeed = 1.0
		
	# Sequentially concatenate strings and await timer
	TextIsAnimated = true
	for string_part in ReadyText:
		DisplayedText += string_part
		await get_tree().create_timer(AnimationSpeed * blockTextSpeed * TextSkipped).timeout
		
	TextIsAnimated = false
	
	## Post animation logic
	# Wait for Spacebar, or whatever we choose to cause text progression
	await advance_dialogue
	# Flush out the current dialogue block data
	DialogueClear()
	
	## Calculate the next block key (A -> B -> C)
	var current_char_code = BlockKey.unicode_at(0)
	var next_block_key = String.chr(current_char_code + 1)
	# Validate and proceed to the next block, or queue_free if the sequence is finished
	if dialogue_sequence.has(next_block_key):
		ValidateTextData(DialogueUUID, next_block_key)
	else:
		queue_free()

## Increments Dialogue Block one step forward ATTACH THIS TO A SIGNAL
func TextIncrement():
	emit_signal("advance_dialogue")

## Resets displayed Dialogue to text.EMPTYSTRING
func DialogueClear(): 
	%TextBox.text = ""
	DisplayedText = ""
	ReadyText = []
