extends RigidBody2D

@onready var trajectory: Line2D = $Trajectory
@onready var timer: Timer = $Timer

@export var trajectory_interval = 0.1
@export var max_points = 10
@export var initial_thrust := 2000
@export var sideways_thrust := 1000.0
@export var offset := 100
var torque := 100

# found this in the rigidbody2d section 
# https://docs.godotengine.org/en/4.3/tutorials/physics/physics_introduction.html
func _ready():
	timer.wait_time = trajectory_interval
	timer.start()
	spawn_in()

func _integrate_forces(state):
	var rotation_direction = 0
	if Input.is_action_pressed("right"):
		apply_force(Vector2(cos(rotation), sin(rotation)) * sideways_thrust)
		rotation_direction += 1
	if Input.is_action_pressed("left"):
		apply_force(Vector2(cos(rotation), sin(rotation)).rotated(PI) * sideways_thrust)
		rotation_direction -= 1
	state.apply_torque(rotation_direction * torque)
	update_ui()

#spawns player at edge randomly and aims them at the planet based on the offset
func spawn_in():
	trajectory.clear_points()
	linear_velocity = Vector2(0,0)
	set_deferred("freeze", false)
	var side = randi() % 4
	var randnum = randf_range(250-offset, 250+offset)
	match side:
		0: #top spawn
			position = Vector2(randf_range(0 , 500), 0)
			apply_force(Vector2(-(position.x-randnum), 250)*initial_thrust)
		1: #right spawn
			position = Vector2(500, randf_range(0 , 500))
			apply_force(Vector2(-250, -(position.y-randnum))*initial_thrust)
		2: #bottom spawn
			position = Vector2(randf_range(0 , 500), 500)
			apply_force(Vector2(-(position.x-randnum), -250)*initial_thrust)
		3: #left spawn
			position = Vector2(0, randf_range(0 , 500))
			apply_force(Vector2(250, -(position.y-randnum))*initial_thrust)
	look_at(Vector2(250, 250))
	rotate(PI/2)


#freezes the player when they crash, kinda buggy
func _on_hitbox_body_entered(body):
	if body.name == "PlanetHitbox":
		set_deferred("freeze", true)
		$"../UI/crashed".show()
		$"../UI/RestartButton".show()
		$"../UI/leftstats".text = text % ["0", "0", "0", "0"]

func _on_timer_timeout() -> void:
	trajectory.add_point(position)
	if trajectory.get_point_count() > max_points:
		trajectory.remove_point(0)

var text = "Velocity: %s mi/s
	Angle: %s °
	Apoapsis: %s mi
	Periapsis:%s mi"
func update_ui():
	$"../UI/leftstats".text = text % [str(round(abs(linear_velocity.x) + abs(linear_velocity.y))), str(round(rad_to_deg(rotation))), "???", "???"]
