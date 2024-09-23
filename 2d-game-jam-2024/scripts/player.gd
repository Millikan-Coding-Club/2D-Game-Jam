extends RigidBody2D

@onready var trail: Line2D = $Trail
@onready var sprite = $Sprite2D

@export var max_points_trail = 10
@export var initial_thrust := 50
@export var const_thrust := 10
@export var sideways_thrust := 1000.0
# @export var offset := 100
@export var spawn_dist: float = 500
@export var max_angle_variance := 0.5 # Radians
@export var min_angle_variance := 0.1
@export var torque := 100
const CENTER = Vector2(250, 250)


signal game_over

# found this in the rigidbody2d section 
# https://docs.godotengine.org/en/4.3/tutorials/physics/physics_introduction.html
func _ready():
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
	trail.clear_points()
	set_deferred("freeze", false)
	linear_velocity = Vector2.ZERO
	var rand_angle = randf_range(0, 2 * PI)
	position = CENTER + Vector2(cos(rand_angle), sin(rand_angle)) * spawn_dist
	look_at(CENTER) # Point towards center
	var rotate = randf_range(min_angle_variance, max_angle_variance)
	if randf() > 0.5:
		rotate *= -1
	rotate(PI/2 + rotate)
	apply_impulse(-transform.y * (initial_thrust))


#freezes the player when they crash, kinda buggy
func _on_hitbox_body_entered(body):
	if body.name == "PlanetHitbox":
		game_over.emit()
