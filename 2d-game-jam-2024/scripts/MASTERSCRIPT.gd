extends Node2D

var player: RigidBody2D
var trajectory: Line2D
@onready var explosion: AnimatedSprite2D = $Explosion
@onready var planet: Node2D = $Planets/Earth
@onready var main_menu = $MainMenu
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
var speed
var planet_spin
var surface
var max_speed = 0
var menu = true

func _ready() -> void:
	pass
	
func start():
	create_player()
	generate_planet()
	periapsis = round(player.position.distance_to(planet.position))
	passed_periapsis = false
	camera.zoom = Vector2(start_zoom,start_zoom)

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
	var scale = planet.get_node("PlanetHitbox/CollisionShape2D").scale.x * speed_factor * scale_variance
	player.sideways_thrust *= (speed_factor - 1) * 5 + 1
	planet.scale *= scale
	planet.starting_gravity *= scale
	planet.gravity_strength = planet.starting_gravity
	planet.radius += scale
	
	planet.rotation = randf_range(0, 2 * PI)
	planet_spin = randf_range(min_planet_spin, max_planet_spin)
	if randf() > 0.5:
		planet_spin *= -1
	# Enable planet
	planet.get_node("PlanetHitbox/CollisionShape2D").disabled = false
	planet.show()
	surface = planet.get_node("PlanetHitbox/CollisionShape2D").shape.radius \
		* planet.get_node("PlanetHitbox/CollisionShape2D").scale.x / 10

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
		if i % int(trajectory_dot_interval / $Camera2D.zoom.x) == 0:
			circle_locations.append(pos)
		if pos.distance_to(planet.position) < trajectory_periapsis:
			trajectory_periapsis = pos.distance_to(planet.position)
		gravity = calculate_gravity(pos)
		if pos.distance_to(planet.global_position) > trajectory_periapsis:
			gravity *= 0.75
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
				$UI/pause.show()
				button_sfx.play()
			else:
				Engine.time_scale = 1
				$UI/pause.hide()
				button_sfx.play()
		
func _physics_process(delta: float) -> void:
	if menu == false:
		if player.position.distance_to(planet.position) < planet.radius:
			player.apply_force(calculate_gravity(player.position))
	

func _process(delta: float) -> void:
	if menu == false:
		update_trajectory(max_points_trajectory, delta)
		update_camera()
		speed = round(player.linear_velocity.length())
		if speed > max_speed:
			max_speed = speed
		update_ui()
		planet.rotate(planet_spin * delta)
		# Stops planet from slowing ship back down for slingshot effect
		if !passed_periapsis:
			passed_periapsis = round(player.position.distance_to(planet.position)) > periapsis
		else:
			planet.gravity_strength = planet.starting_gravity * 0.75

var text = "Speed: %s mi/s
	Angle: %s °
	Periapsis: %s mi"
	
func update_ui():
	if round(player.position.distance_to(planet.position)) < periapsis:
		periapsis = round(player.position.distance_to(planet.position))
	if speed != 0:
		$UI/leftstats.text = text % [str(round(speed)), 
	str(round(player.rotation_degrees + 180)),
	periapsis]
	$UI/rightstats.visible = GlobalVariables.debug
	$UI/rightstats.text = str(Engine.get_frames_per_second())

func game_over():
	explode()
	player.set_deferred("freeze", true)
	player.hide()
	$UI/crashed.show()
	$UI/RestartButton.show()
	$UI/leftstats.text = text % ["0", "0", "0"]
	$UI/crashed.text = "YOU CRASHED\nScore: " + str(speed)


func explode():
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
		new_vel = speed
		restart()

func _on_button_pressed():
	button_sfx.play()
