extends CanvasLayer

@onready var game = $".."
@onready var ui = $"../UI"
@onready var start_button = $StartButton
@onready var anim = $Animation
@onready var ui_anim = $UI
@onready var settings = $Settings
@onready var credits = $Credits
@onready var launch_sfx: AudioStreamPlayer2D = $"../Audio/LaunchSFX"


func _ready():
	anim.play("orbit")
	game.menu = true
	ui.hide()
	await start_button.pressed
	$"../Audio/LaunchSFX".play()
	$Title.hide()
	$StartButton.hide()
	$SettingButton.hide()
	$QuitButton.hide()
	$CreditsButton.hide()
	$Settings.hide()
	$Credits.hide()
	$intructions.hide()
	game.start_music()
	anim.stop()
	anim.play("launch")
	launch_sfx.play()
	await anim.animation_finished
	ui.show()
	hide()
	game.menu = false
	game.start()

func _on_setting_button_pressed():
	if settings.visible == false:
		settings.show()
		ui_anim.play("settings")
	else:
		ui_anim.play_backwards("settings")
		await ui_anim.animation_finished
		settings.hide()

func _on_credits_button_pressed():
	if credits.visible == false:
		credits.show()
		ui_anim.play("credits")
	else:
		ui_anim.play_backwards("credits")
		await ui_anim.animation_finished
		credits.hide()

func _on_music_value_changed(value):
	var index = AudioServer.get_bus_index("Music")
	AudioServer.set_bus_volume_db(index, value)

func _on_sfx_value_changed(value):
	var index = AudioServer.get_bus_index("SFX")
	AudioServer.set_bus_volume_db(index, value)

func _on_quit_button_pressed():
	get_tree().quit()
