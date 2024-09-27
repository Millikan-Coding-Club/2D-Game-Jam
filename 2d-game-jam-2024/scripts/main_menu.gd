extends CanvasLayer

@onready var game = $".."
@onready var ui = $"../UI"
@onready var start_button = $StartButton
@onready var anim = $Animation


func _ready():
	anim.play("orbit")
	GlobalVariables.debug = false
	game.menu = true
	ui.hide()
	await start_button.pressed
	$Title.hide()
	$StartButton.hide()
	$SettingButton.hide()
	$QuitButton.hide()
	anim.stop()
	anim.play("launch")
	await anim.animation_finished
	ui.show()
	hide()
	game.menu = false
	game.restart()
