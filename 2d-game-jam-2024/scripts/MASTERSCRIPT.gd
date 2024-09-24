extends Node2D

var player: RigidBody2D
var trajectory: Line2D
@onready var explosion: AnimatedSprite2D = $Explosion
@onready var planet: Node2D = $Planet
@export var max_points_trajectory: int = 300
@export var trajectory_dot_interval: int = 10
@export var trajectory_dot_size: float = 1
@export var start_zoom := 1.0
@export var min_planet_spin: float = 1
@export var max_planet_spin: float = 10
@export var planet_sprites: Array[CompressedTexture2D] = []
@onready var camera = $Camera2D

var periapsis
var passed_periapsis := false
var new_vel
var speed
var planet_spin

func _ready() -> void:
	start()
	if player.gameplay2 == true:
		trajectory_dot_size = .5
		start_zoom = .2
		trajectory_dot_interval = 5
	
func start():
	create_player()
	periapsis = round(player.position.distance_to(planet.position))
	passed_periapsis = false
	generate_planet()
	camera.zoom = Vector2(start_zoom,start_zoom)

func restart():
	player.queue_free()
	start()
	$background.star_death()
	$background.generate_stars()
	$UI/crashed.hide()
	$UI/RestartButton.hide()
	
# WIP
func generate_planet():
	$Planet/Sprite2D.texture = planet_sprites.pick_random() 
	planet_spin = randf_range(min_planet_spin, max_planet_spin)
	if randf() > 0.5:
		planet_spin *= -1


func _on_restart_button_pressed():
	get_tree().reload_current_scene()
	
func create_player():
	player = load("res://scenes/player.tscn").instantiate()
	player.gravity_scale = 1
	if new_vel:
		player.initial_thrust = new_vel
	add_child(player)
	trajectory = player.get_node("Trajectory")
	player.connect("game_over", game_over)
	player.get_node("Sprite2D/VisibleOnScreenNotifier2D").connect("screen_exited", _on_player_exited)


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
			gravity *= 0.5
		vel += gravity / (player.mass * delta)
		pos += vel * delta #TODO: fix trajectory calculation
		if pos.distance_to(planet.global_position) < 200*planet.scale.x: #DONE: calculated planet radius
			break
		var interval: int = trajectory_dot_interval / $Camera2D.zoom.x
		if i % interval == 0: #draws circle at every multiple of interval
			circle_locations.append(pos)
	queue_redraw()
	
func update_camera():
	var player_dist = player.global_position.distance_to(planet.global_position)
	if player.gameplay2 == true:
		if player_dist < 800:
			$Camera2D.zoom = Vector2(0.3, 0.3)
		if player_dist < 500:
			$Camera2D.zoom = Vector2(0.5, 0.5)
		if player_dist < 300:
			$Camera2D.zoom = Vector2(0.8, 0.8)
	if player_dist < 200:
		$Camera2D.zoom = Vector2(1.3, 1.3)
	if player_dist < 120:
		$Camera2D.zoom = Vector2(2, 2)
	if player_dist < 60:
		$Camera2D.zoom = Vector2(5, 5)
	if player_dist < 10:
		$Camera2D.zoom = Vector2(15, 15)

var circle_locations: PackedVector2Array
func _draw():
	var size = trajectory_dot_size / $Camera2D.zoom.x
	for i in circle_locations:
		draw_circle(i, size, Color(1, 1, 1))
	circle_locations.clear()

#restart key
func _input(event):
	if Input.is_key_pressed(KEY_R):
		get_tree().reload_current_scene()


func _process(delta: float) -> void:
	update_trajectory(delta)
	update_camera()
	update_ui()
	planet.rotate(planet_spin * delta)
	# Stops planet from slowing ship back down for slingshot effect
	if !passed_periapsis:
		passed_periapsis = round(player.position.distance_to(planet.position)) > periapsis
	else:
		player.gravity_scale = 0.5

var text = "Speed: %s mi/s
	Angle: %s °
	Periapsis: %s mi"
	
func update_ui():
	if round(player.position.distance_to(planet.position)) < periapsis:
		periapsis = round(player.position.distance_to(planet.position))
	speed = round(player.linear_velocity.length())
	if speed != 0:
		$UI/leftstats.text = text % [str(round(speed)), 
	str(round(player.rotation_degrees + 180)),
	periapsis]


func game_over():
	explode()
	player.set_deferred("freeze", true)
	player.hide()
	$UI/crashed.show()
	$UI/RestartButton.show()
	$UI/leftstats.text = text % ["0", "0", "0"]


func explode():
	var dist_offset = 2.5
	var offset = (player.position - planet.position).normalized() * dist_offset
	explosion.position = player.position + offset
	explosion.look_at(planet.position)
	explosion.rotate(PI)
	explosion.reparent(planet)
	explosion.show()
	explosion.play("explosion")
	await explosion.animation_finished
	explosion.hide()


func _on_player_exited() -> void:
	if player.visible:
		new_vel = speed
		restart()
