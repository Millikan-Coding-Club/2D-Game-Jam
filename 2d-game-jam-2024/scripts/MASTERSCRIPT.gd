extends Node2D

var player: RigidBody2D
var trajectory: Line2D
@onready var explosion: AnimatedSprite2D = $Explosion
@onready var planet: Node2D = $Planets/Earth
@onready var main_menu = $MainMenu

@export var skip_intro = false
@export var max_points_trajectory: int = 300
@export var trajectory_dot_interval: int = 10
@export var trajectory_dot_size: float = 1
@export var start_zoom := 1.0
@export var explosion_dist_offset = 2.8
@onready var camera = $Camera2D
@onready var pause = $UI/pause
# Planets
@export var min_planet_spin: float = 1
@export var max_planet_spin: float = 5
@export var cool_planet_chance: float = 0.25
@export var overlay_chance:float = 0.1
@export var planets: Array[Node2D] = []
var planets_copy: Array[Node2D] = []
@export var basic_planets: Array[Node2D] = []
@export var rings: Array[CompressedTexture2D] = []
# Audio
@onready var explosion_sfx: AudioStreamPlayer2D = $Audio/ExplosionSFX
@onready var launch_sfx: AudioStreamPlayer2D = $Audio/LaunchSFX
@onready var button_sfx: AudioStreamPlayer2D = $Audio/ButtonSFX

var periapsis
var passed_periapsis := false
var new_vel
var speed = 50
var planet_spin
var surface
var menu = true
var camera_scale = 1
var planet_scale = 1
var score = 0
var game_is_over = false
var exit_scale = 1
@export var max_speed = 400

	
func start():
	create_player()
	generate_planet()
	periapsis = round(player.position.distance_to(planet.position))
	passed_periapsis = false
	camera.zoom = Vector2(camera_scale, camera_scale)

func restart():
	player.queue_free()
	start()
	$background.star_death()
	$background.generate_stars()
	$UI/crashed.hide()
	$UI/RestartButton.hide()
	
# TODO:
# - Make planet chances weighted
func generate_planet():
	# Disable old planet
	planet.get_node("PlanetHitbox/CollisionShape2D").disabled = true
	planet.hide()
	# Cool planets 😎
	if randf() < cool_planet_chance: 
		if planets_copy.is_empty():
			planets_copy = planets.duplicate()
		var rand = randi_range(0, planets_copy.size() - 1)
		planet = planets_copy.pop_at(rand)
	else: # Basic planets
		planet = basic_planets.pick_random()
		planet.get_node("Rings").hide()
		planet.get_node("Clouds").hide()
		planet.get_node("Islands").hide()
		planet.get_node("Sprite2D").self_modulate = Color.from_hsv(randf(), 0.25, 1)
		if randf() < overlay_chance: # Rings
			planet.get_node("Rings").texture = rings.pick_random()
			planet.get_node("Rings").show()
		if randf() < overlay_chance: # Clouds
			planet.get_node("Clouds").show()
			planet.get_node("Clouds").self_modulate = Color.from_hsv(randf(), 0.25, 1)
		if randf() < overlay_chance && planet.name == "Basic1":
			planet.get_node("Islands").show()
	# Set planet values
	# Scaling stuff may need to be tweaked more in the future
	var speed_factor = (player.initial_thrust - 50) / 100 + 1
	var scale_variance = randf_range(0.75, 1.25)
	planet_scale = min(planet.get_node("PlanetHitbox/CollisionShape2D").scale.x * \
	speed_factor * scale_variance, 5)
	player.sideways_thrust *= (speed_factor - 1) * 5 + 1
	planet.scale *= scale_variance
	planet.starting_gravity *= planet_scale
	planet.gravity_strength = planet.starting_gravity
	planet.radius *= planet_scale
	planet.rotation = randf_range(0, 2 * PI)
	planet_spin = randf_range(min_planet_spin, max_planet_spin)
	exit_scale = min(0.5 + (speed - 50) / ((max_speed - 50) / 0.5), 1)
	if randf() > 0.5:
		planet_spin *= -1
	# Enable planet
	planet.get_node("PlanetHitbox/CollisionShape2D").disabled = false
	planet.show()
	surface = planet.get_node("PlanetHitbox/CollisionShape2D").shape.radius \
		* planet.get_node("PlanetHitbox/CollisionShape2D").scale.x / 10 * scale_variance

func _on_restart_button_pressed():
	get_tree().reload_current_scene()
	
func create_player():
	player = load("res://scenes/player.tscn").instantiate()
	if new_vel:
		player.initial_thrust = new_vel
	add_child(player)
	trajectory = player.get_node("Trajectory")
	player.connect("game_over", game_over)
	player.get_node("Sprite2D/VisibleOnScreenNotifier2D").connect("screen_exited", _on_player_exited)

func calculate_gravity(point: Vector2):
	var distance = planet.position.distance_to(point)
	var direction = (planet.position - point).normalized()
	var magnitude = planet.gravity_strength * 100000 / pow(distance, 2)
	var force = direction * magnitude # OH YEAH
	return force

func update_trajectory(steps, delta):
	var pos = player.position
	var vel = player.linear_velocity
	var gravity = calculate_gravity(pos)
	var trajectory_periapsis = pos.distance_to(planet.global_position)
	for i in max_points_trajectory:
		if i % int(ceil(trajectory_dot_interval / $Camera2D.zoom.x)) == 0:
			circle_locations.append(pos)
		if pos.distance_to(planet.position) < trajectory_periapsis:
			trajectory_periapsis = pos.distance_to(planet.position)
		gravity = calculate_gravity(pos)
		if pos.distance_to(planet.global_position) > trajectory_periapsis:
			gravity *= exit_scale
		if pos.distance_to(planet.global_position) < planet.radius:
			vel += gravity / player.mass * delta
		pos += vel * delta
		if pos.distance_to(planet.global_position) < surface:
			break
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
	if player_dist < 200:
		$Camera2D.zoom *= camera_scale
var circle_locations: PackedVector2Array
func _draw():
	var size = trajectory_dot_size / $Camera2D.zoom.x
	for i in circle_locations:
		draw_circle(i, size, Color(1, 1, 1))
	circle_locations.clear()

func _input(event):
	#restart key
	if Input.is_key_pressed(KEY_R):
		get_tree().reload_current_scene()
	if Input.is_key_pressed(KEY_C):
		GlobalVariables.debug = !GlobalVariables.debug
	if Input.is_key_pressed(KEY_ESCAPE):
		if menu == false:
			if pause.visible == false:
				Engine.time_scale = 0
				AudioServer.set_bus_mute(1, true)
				$UI/pause.show()
				button_sfx.play()
			else:
				Engine.time_scale = 1
				AudioServer.set_bus_mute(1, false)
				$UI/pause.hide()
				button_sfx.play()
		
func _physics_process(delta: float) -> void:
	if menu == false:
		if player.position.distance_to(planet.position) < planet.radius:
			player.apply_force(calculate_gravity(player.position))

func _process(delta: float) -> void:
	if menu == false && !game_is_over:
		update_trajectory(max_points_trajectory, delta)
		update_camera()
		speed = round(player.linear_velocity.length())
		score += delta * (speed / 10)
		update_ui()
		planet.rotate(planet_spin * delta)
		# Stops planet from slowing ship back down for slingshot effect
		if !passed_periapsis:
			passed_periapsis = round(player.position.distance_to(planet.position)) > periapsis
		else:
			planet.gravity_strength = planet.starting_gravity * exit_scale

var text = "Speed: %s mi/s
	Angle: %s °
	Periapsis: %s mi"


func update_ui():
	if round(player.position.distance_to(planet.position)) < periapsis:
		periapsis = round(player.position.distance_to(planet.position))
	if speed != 0:
		$UI/Score.text = "SCORE
		" + str(round(score))
		$UI/leftstats.text = text % [str(round(speed)), 
		str(round(player.rotation_degrees + 180)),
		periapsis]
	$UI/rightstats.visible = GlobalVariables.debug
	$UI/rightstats.text = "FPS: " + str(Engine.get_frames_per_second()) \
	+ "\n" + "planet_scale: " + str(planet_scale) \
	+ "\n" + "exit_scale :" + str(exit_scale)

func game_over():
	game_is_over = true
	explode()
	$Audio/Music/Death.play("death")
	player.set_deferred("freeze", true)
	player.hide()
	$UI/crashed.show()
	$UI/RestartButton.show()
	$UI/leftstats.text = text % ["0", "0", "0"]
	$UI/crashed.text = "YOU CRASHED\nScore: " + str(round(score))

func explode():
	
	
	# this makes the explosion spawn on the opposite side of the planet
	#explosion.reparent(planet)
	#explosion.global_position = player.global_position
	var offset = (player.position - planet.position).normalized() * (surface + explosion_dist_offset)
	explosion.position = planet.position + offset
	explosion.look_at(planet.position)
	explosion.rotate(PI)
	explosion.reparent(planet)
	explosion.show()
	explosion_sfx.play()
	explosion.play("explosion")
	await explosion.animation_finished
	explosion.hide()

func _on_player_exited() -> void:
	if player.visible:
		new_vel = round(player.linear_velocity.length())
		restart()
func _on_button_pressed(): #some weird error with this
	button_sfx.play()

func start_music():
	$Audio/Music/Phase1.play()
	await $Audio/Music/Phase1.finished
	$Audio/Music/Loop1.play()
	while score < 300:
		await get_tree().create_timer(7.5).timeout
	$Audio/Music/Loop1.stop()
	$Audio/Music/Transition1.play()
	await get_tree().create_timer(3.75).timeout
	$Audio/Music/Phase2.play()
	await $Audio/Music/Phase2.finished
	$Audio/Music/Loop2.play()
	while score < 1200:
		await get_tree().create_timer(7.5).timeout
	$Audio/Music/Loop2.stop()
	$Audio/Music/FinalPhase.play()
	await $Audio/Music/FinalPhase.finished
	$Audio/Music/Loop3.play()
