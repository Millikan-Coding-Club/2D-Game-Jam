extends Node2D

@onready var player: RigidBody2D = $Player
@onready var planet: Node2D = $Planet
@onready var trajectory: Line2D = $Player/Trajectory
@export var max_points_trajectory = 300

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
	

func get_gravity_at_point(area: Area2D, point: Vector2) -> Vector2:
	var gravity_strength = area.gravity
	var center = area.global_position

	var direction = center - point
	var distance = direction.length()# - area.gravity_point_unit_distance

	direction = direction.normalized()

	var force_magnitude = gravity_strength / pow(distance, 2)
	
	return direction * force_magnitude


func update_trajectory(delta):
	trajectory.clear_points()
	var pos = player.global_position
	var vel = player.linear_velocity
	var gravity = Vector2.ZERO
	var trajectory_periapsis = pos.distance_to(planet.global_position)
	for i in max_points_trajectory:
		trajectory.add_point(pos)
		if pos.distance_to(planet.global_position) < trajectory_periapsis:
			trajectory_periapsis = pos.distance_to(planet.global_position)
		gravity = get_gravity_at_point($Planet/Area2D, pos) * 8
		if pos.distance_to(planet.global_position) > trajectory_periapsis:
			gravity *= 0.25
		vel += gravity / (player.mass * delta)
		pos += vel * delta #TODO: fix trajectory calculation
		if pos.distance_to(planet.global_position) < 14: #TODO: calculate planet radius
			break
		if i % 5 == 0: #draws circle at every multiple of 5
			circle_locations.append(pos)
	queue_redraw()

var circle_locations: PackedVector2Array
func _draw():
	var size = .4 / $Camera2D.zoom.x
	for i in circle_locations:
		draw_circle(i, size, Color(1, 1, 1))
	circle_locations.clear()

#restart key
func _input(event):
	if Input.is_key_pressed(KEY_R):
		restart()


func _process(delta: float) -> void:
	update_trajectory(delta)
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
