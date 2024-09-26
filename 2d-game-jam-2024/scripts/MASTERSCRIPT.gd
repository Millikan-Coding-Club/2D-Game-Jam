extends Node2D

var player: RigidBody2D
var trajectory: Line2D
@onready var explosion: AnimatedSprite2D = $Explosion
@onready var planet: Node2D = $Planets/Earth
@export var max_points_trajectory: int = 300
@export var trajectory_dot_interval: int = 10
@export var trajectory_dot_size: float = 1
@export var start_zoom := 1.0
@export var explosion_dist_offset = 2.8
@onready var camera = $Camera2D
# Planets
@export var min_planet_spin: float = 1
@export var max_planet_spin: float = 5
@export var cool_planet_chance: float = 0.25
@export var overlay_chance:float = 0.1
@export var planets: Array[Node2D] = []
var planets_copy: Array[Node2D] = []
@export var basic_planets: Array[Node2D] = []
@export var rings: Array[CompressedTexture2D] = []

var periapsis
var passed_periapsis := false
var new_vel
var speed
var planet_spin
var surface


func _ready() -> void:
	start()
	if player.gameplay2 == true:
		trajectory_dot_size = .5
		start_zoom = .2
		trajectory_dot_interval = 5
	
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
# - Make planets scale with speed
# - Make planet chances weighted
func generate_planet():
	# Disable old planet
	planet.get_node("PlanetHitbox/CollisionShape2D").disabled = true
	planet.get_node("Area2D/CollisionShape2D").disabled = true
	planet.hide()
	planet.set_process(false)
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
		planet.get_node("Sprite2D").self_modulate = Color.from_hsv(randf(), 0.25, 1)
		if randf() < overlay_chance: # Rings
			planet.get_node("Rings").texture = rings.pick_random()
			planet.get_node("Rings").show()
		if randf() < overlay_chance: # Clouds
			planet.get_node("Clouds").show()
			planet.get_node("Clouds").self_modulate = Color.from_hsv(randf(), 0.25, 1)
	# Set planet values
	planet.gravity_strength = planet.starting_gravity
	var scale = planet.get_node("PlanetHitbox/CollisionShape2D").scale
	planet.get_node("Area2D/CollisionShape2D").scale = 100 * scale
	planet.get_node("Area2D").gravity *= planet.get_node("PlanetHitbox/CollisionShape2D").scale.x
	planet.rotation = randf_range(0, 2 * PI)
	planet_spin = randf_range(min_planet_spin, max_planet_spin)
	if randf() > 0.5:
		planet_spin *= -1
	# Enable planet
	planet.get_node("PlanetHitbox/CollisionShape2D").disabled = false
	#planet.get_node("Area2D/CollisionShape2D").disabled = false
	planet.show()
	planet.set_process(true)
	surface = planet.get_node("PlanetHitbox/CollisionShape2D").shape.radius \
		* planet.get_node("PlanetHitbox/CollisionShape2D").scale.x / 10

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


#func get_gravity_at_point(area: Area2D, point: Vector2) -> Vector2:
	#var gravity_strength = area.gravity
	#var center = area.global_position
#
	#var direction = center - point
	#var distance = direction.length() - area.gravity_point_unit_distance
#
	#direction = direction.normalized()
#
	#var force_magnitude = gravity_strength / pow(distance, 2)
	#
	#return direction * force_magnitude
#
#
##func update_trajectory(delta):
	##trajectory.clear_points()
	##var pos = player.global_position
	##var vel = player.linear_velocity
	##var gravity = Vector2.ZERO
	##var trajectory_periapsis = pos.distance_to(planet.global_position)
	##for i in max_points_trajectory:
		##trajectory.add_point(pos)
		##if pos.distance_to(planet.global_position) < trajectory_periapsis:
			##trajectory_periapsis = pos.distance_to(planet.global_position)
		##gravity = get_gravity_at_point(planet.get_node("Area2D"), pos)
		##if pos.distance_to(planet.global_position) > trajectory_periapsis:
			##gravity *= 0.5
		##vel += gravity / player.mass#i dont know why this fixes it but who cares
		##pos += vel * delta # Trajectory is good enough if it doesn't cause more problems
		##if pos.distance_to(planet.global_position) < surface:
			##break
		##var interval: int = trajectory_dot_interval / $Camera2D.zoom.x
		##if i % interval == 0: #draws circle at every multiple of interval
			##circle_locations.append(pos)
	##queue_redraw()


func calculate_gravity(point: Vector2):
	var distance = planet.position.distance_to(point)
	var direction = (planet.position - point).normalized()
	var magnitude = planet.gravity_strength * 1000 / distance
	var force = direction * magnitude # OH YEAH
	return force
		
		
func update_trajectory(delta):
	pass
	
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
		#get_tree().reload_current_scene()
		restart()
	if Input.is_key_pressed(KEY_C):
		GlobalVariables.debug = !GlobalVariables.debug
		
		
func _physics_process(delta: float) -> void:
	if player.position.distance_to(planet.position) < planet.radius:
		player.apply_force(calculate_gravity(player.position))
	

func _process(delta: float) -> void:
	update_trajectory(delta)
	update_camera()
	update_ui()
	planet.rotate(planet_spin * delta)
	# Stops planet from slowing ship back down for slingshot effect
	if !passed_periapsis:
		passed_periapsis = round(player.position.distance_to(planet.position)) > periapsis
	else:
		planet.gravity_strength = planet.starting_gravity * 0.5

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
	$UI/rightstats.visible = GlobalVariables.debug
	$UI/rightstats.text = str(Engine.get_frames_per_second())

func game_over():
	explode()
	player.set_deferred("freeze", true)
	player.hide()
	$UI/crashed.show()
	$UI/RestartButton.show()
	$UI/leftstats.text = text % ["0", "0", "0"]


func explode():
	var offset = (player.position - planet.position).normalized() * explosion_dist_offset
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
