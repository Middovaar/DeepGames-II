extends Button

@export var FreeTexture:Texture2D
@export var HoverTexture:Texture2D



func _on_focus_entered():
	self.icon = HoverTexture


func _on_focus_exited():
	self.icon = FreeTexture
