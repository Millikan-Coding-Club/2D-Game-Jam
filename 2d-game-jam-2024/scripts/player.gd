extends RigidBody2D

@export var initial_thrust := 2000
@export var thrust := 10.0
var torque := .5

# found this in the rigidbody2d section 
# https://docs.godotengine.org/en/4.3/tutorials/physics/physics_introduction.html
func _ready():
	apply_force(Vector2(0, -initial_thrust))

func _integrate_forces(state):
	var rotation_direction = 0
	if Input.is_action_pressed("right"):
		apply_force(Vector2(thrust, 0))
		rotation_direction += 1
	if Input.is_action_pressed("left"):
		apply_force(Vector2(-thrust, 0))
		rotation_direction -= 1
	state.apply_torque(rotation_direction * torque)
	update_ui()

#freezes the player when they crash, kinda buggy
func _on_hitbox_body_entered(body):
	print(body.name)
	if body.name == "PlanetHitbox":
		set_deferred("freeze", true)
		$"../UI/crashed".show()
		$"../UI/leftstats".text = text % ["0", "0", "0", "0"]



var text = "Velocity: %s m9/s
	Angle: %s °
	Apoapsis: %s mi
	Periapsis:%s mi"
func update_ui():
	$"../UI/leftstats".text = text % [str(round(abs(linear_velocity.x) + abs(linear_velocity.y))), str(round(rad_to_deg(rotation))), "???", "???"]
