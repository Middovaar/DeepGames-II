extends Node2D

## >> Internal Signals
signal AnimationStageChange(Stage:int)

## >> External Signals
signal DialogueReq(DialogueUUID:String)
signal GoToGame()

@export var ScreenMiddle:float = 990.0
@export var ScreenEnd:float = 3080.0
@export var AnimationStage:int = 0

@export_category("Animation Params")
@export_subgroup("Animation Stage 0")
@export_range(0.0, 2.0, 0.1, "or_greater", "suffix:fracs") var Stage1_SlideSpeed:float = 1.0

@export_subgroup("Animation Stage 1")
@export_range(0.0, 4.0, 0.1, "suffix:rad") var OccilationSpd:float = 0.8
@export_range(0.0, 4.0, 0.1, "suffix:str") var OccilationStr:float = 1.0

@export_subgroup("Animation Stage 3")
@export_range(0.0, 2.0, 0.1, "or_greater", "suffix:fracs") var Stage2_SlideSpeed:float = 1.0

var SinClock:float = 0.0
var CountTimer:float = 0.0
var single:bool = true

var DialogueIntroFlag:bool = false

func _ready():
	$Background.ControllableStars = false
	$Background.SpaceSpeed.x = 0.5
	

func _process(delta):
	match AnimationStage:
		0:
			$Spaceship.position.x = lerpf($Spaceship.position.x, ScreenMiddle, Stage1_SlideSpeed*0.01)
			if $Spaceship.position.x >= (910.0 + (OccilationSpd * -100)):
				emit_signal("AnimationStageChange", 1)
				AnimationStage = 1
		1:
			if SinClock < TAU:
				SinClock += PI * OccilationSpd * delta
			else:
				SinClock = 0.0
			
			$Spaceship.position.x += (sin(SinClock) * OccilationStr)
		2:
			$Spaceship.position.x = lerpf($Spaceship.position.x, ScreenEnd, Stage2_SlideSpeed*0.008)
			if $Spaceship.position.x >= 2300:
				AnimationStage = 3
		3:
			$Spaceship.position.x = lerpf($Spaceship.position.x, ScreenEnd, Stage2_SlideSpeed*0.008)
			if $Background.SpaceSpeed.y <= -0.95:
				$Background.SpaceSpeed.x = lerpf($Background.SpaceSpeed.x, 1.0, 0.008)
				$Background.SpaceSpeed.y -= 0.002 * delta
			else:
				AnimationStage = 4
				
		4:
			const Threshold:int = 500
			if CountTimer < Threshold:
				if CountTimer < Threshold*0.4:
					$Background.SpaceSpeed.x = lerpf($Background.SpaceSpeed.x, 0.3, 0.01)
				else:
					$Background.SpaceSpeed.x = lerpf($Background.SpaceSpeed.x, 0.0, 0.01)
				$Background.SpaceSpeed.y = lerpf($Background.SpaceSpeed.y, -1.0, 0.008)
				CountTimer += 101 * delta
			else:
				AnimationStage = 5
		5:
			if $Star.position.y < 1080 * 0.449:
				$Star.position.y = lerpf($Star.position.y, 1080*0.45, 0.012)
				$Background.SpaceSpeed.x = lerpf($Background.SpaceSpeed.x, 0.0, 0.008)
				$Background.SpaceSpeed.y = lerpf($Background.SpaceSpeed.y, 0.0, 0.008)
			else:
				emit_signal("AnimationStageChange", 5)
				$Background.SpaceSpeed = Vector2.ZERO
				$Star.position.y = 1080 * 0.45

func _input(event):
	## Replace This with a signal from the dialogue docs.
	if Input.is_action_just_pressed("ui_accept"):
		if AnimationStage == 1 and DialogueIntroFlag:
			AnimationStage = 2
		if AnimationStage == 5:
			emit_signal("GoToGame")

func _on_animation_stage_change(Stage):
	match Stage:
		1:
			emit_signal("DialogueReq", "Intro") #Loads the Dialogue "Intro" in Dialogue.json
		5:
			if single:
				emit_signal("DialogueReq", "PressSpace") # Shows the Press Space Message
				single = false
			else:
				pass
		_:
			pass


func _on_DialogueFinished(DialogueUUID):
	match DialogueUUID:
		"Intro":
			DialogueIntroFlag = true
