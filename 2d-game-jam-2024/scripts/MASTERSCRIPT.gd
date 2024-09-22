extends Node2D

@onready var player: RigidBody2D = $Player
@onready var planet: Node2D = $Planet

@onready var periapsis = round(player.position.distance_to(planet.position))

func restart():
	get_tree().reload_current_scene()
	#$background.star_death()
	#$background.generate_stars()
	#$UI/crashed.hide()
	#$UI/RestartButton.hide()
	#$Player.spawn_in()
	#$Camera2D.zoom = Vector2(1,1)

func _on_restart_button_pressed():
	restart()
	

#restart key
func _input(event):
	if Input.is_key_pressed(KEY_R):
		restart()


func _process(delta: float) -> void:
	update_ui()
	# Stops planet from slowing ship back down for slingshot effect
	if round(player.position.distance_to(planet.position)) > periapsis:
		$Planet/Area2D.gravity *= 0.5

var text = "Velocity: %s mi/s
	Angle: %s °
	Periapsis: %s mi"
	
func update_ui():
	if round(player.position.distance_to(planet.position)) < periapsis:
		periapsis = round(player.position.distance_to(planet.position))
	$UI/leftstats.text = text % [str(round(abs(player.linear_velocity.x) + abs(player.linear_velocity.y))), 
	str(round(player.rotation_degrees + 180)),
	periapsis]


func _on_player_game_over() -> void:
	player.set_deferred("freeze", true)
	$UI/crashed.show()
	$UI/RestartButton.show()
	$UI/leftstats.text = text % ["0", "0", "0"]
