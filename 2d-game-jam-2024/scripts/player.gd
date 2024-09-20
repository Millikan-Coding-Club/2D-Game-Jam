extends RigidBody2D

@export var initial_thrust = 20000
var torque = 2000

# found this in the rigidbody2d section 
# https://docs.godotengine.org/en/4.3/tutorials/physics/physics_introduction.html
func _ready():
	apply_force(Vector2(0, -initial_thrust))

func _integrate_forces(state):
	var rotation_direction = 0
	if Input.is_action_pressed("right"):
		rotation_direction += .1
	if Input.is_action_pressed("left"):
		rotation_direction -= .1
	state.apply_torque(rotation_direction * torque)
