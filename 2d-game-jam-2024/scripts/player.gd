extends RigidBody2D

@onready var trail: Line2D = $Trail
@onready var sprite = $Sprite2D
@onready var animation = $AnimatedSprite2D

# changes a bunch of values that i think are better, weird bug with turning though
@export var gameplay2 := false 

@export var max_points_trail := 10
@export var initial_thrust := 50
@export var const_thrust := 10
@export var sideways_thrust := 1000.0
@export var spawn_dist: float = 500
@export var max_offset = 100
@export var min_offset = 50
@export var torque := 100
const CENTER = Vector2(250, 250)


signal game_over

# found this in the rigidbody2d section 
# https://docs.godotengine.org/en/4.3/tutorials/physics/physics_introduction.html
func _ready():
	if gameplay2 == true:
		spawn_dist = 1500
		initial_thrust = 200
		torque = 200
		min_offset = 0
		max_offset = 15
	spawn_in()
	
func _process(delta: float) -> void:
	trail.add_point(position)
	if trail.get_point_count() > max_points_trail:
		trail.remove_point(0)

	sprite.look_at(linear_velocity + position)
	sprite.rotate(PI/2)

func _integrate_forces(state):
	var rotation_direction = 0
	state.apply_force(-transform.y * const_thrust)
	if Input.is_action_pressed("right"):
		apply_force(Vector2(cos(rotation), sin(rotation)) * sideways_thrust)
		rotation_direction += 1
	if Input.is_action_pressed("left"):
		apply_force(Vector2(cos(rotation), sin(rotation)).rotated(PI) * sideways_thrust)
		rotation_direction -= 1
	state.apply_torque(rotation_direction * torque)

# spawns player in a circle and randomly and aims them at the planet based on the offset
func spawn_in():
	dying = false
	sprite.show()
	trail.clear_points()
	set_deferred("freeze", false)
	linear_velocity = Vector2.ZERO
	var rand_angle = randf_range(0, 2 * PI)
	position = CENTER + Vector2(cos(rand_angle), sin(rand_angle)) * spawn_dist
	# Offset is a vector from the planet that is perpendicular to the vector of the ship
	# to the planet and has a magnitude ranging from min_offset to max_offset
	# TODO: Make offset change scale in relation to speed and later planet size
	var offset = (global_position - CENTER).normalized().rotated(PI/2) * randf_range(min_offset, max_offset)
	if randf() > 0.5:
		offset *= -1
	var target = CENTER + offset
	look_at(target)
	$Sprite2D/Pinky.global_position = CENTER + offset # Placeholder to visualize offset
	rotate(PI/2)
	apply_impulse(-transform.y * (initial_thrust))


#freezes the player when they crash, kinda buggy
func _on_hitbox_body_entered(body):
	if body.name == "PlanetHitbox":
		game_over.emit()

var dying = false
func explosion():
	dying = true
	look_at(CENTER)
	rotate(PI/2)
	sprite.hide()
	animation.show()
	animation.play("explosion")
	await animation.animation_finished
	animation.hide()
	
