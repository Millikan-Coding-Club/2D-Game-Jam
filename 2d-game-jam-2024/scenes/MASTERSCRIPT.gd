extends Node2D

func restart():
	$background.star_death()
	$background.generate_stars()
	$UI/crashed.hide()
	$UI/RestartButton.hide()
	$Player.spawn_in()

func _on_restart_button_pressed():
	restart()

#restart key
func _input(event):
	if Input.is_key_pressed(KEY_R):
		restart()
