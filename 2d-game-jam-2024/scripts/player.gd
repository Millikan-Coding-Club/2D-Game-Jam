extends RigidBody2D

@onready var trajectory: Line2D = $Trajectory
@onready var timer: Timer = $Timer

@export var trajectory_interval = 0.1
@export var max_points = 10
@export var initial_thrust := 50
@export var const_thrust := 10
@export var sideways_thrust := 1000.0
# @export var offset := 100
@export var spawn_dist := 500
@export var angle_variance := 0.5 # Radians
@export var torque := 100
const CENTER = Vector2(250, 250)

signal game_over

# found this in the rigidbody2d section 
# https://docs.godotengine.org/en/4.3/tutorials/physics/physics_introduction.html
func _ready():
	timer.wait_time = trajectory_interval
	timer.start()
	spawn_in()

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

# spawns player at edge randomly and aims them at the planet based on the offset
func spawn_in():
	trajectory.clear_points()
	linear_velocity = Vector2(0,0)
	set_deferred("freeze", false)
	var rand_angle = randf_range(0, 2 * PI)
	position = CENTER + Vector2(cos(rand_angle), sin(rand_angle)) * spawn_dist
	look_at(CENTER) # Point towards center
	rotate(PI/2 + randf_range(-angle_variance, angle_variance)) # Fix offset and vary angle by +- angle_variance
	apply_impulse(-transform.y * initial_thrust)
	
	#var randnum = randf_range(250-offset, 250+offset)
	#var side = randi() % 4
	#match side:
		#0: #top spawn
			#position = Vector2(randf_range(0 , 500), 0)
			#apply_force(Vector2(-(position.x-randnum), 250)*initial_thrust)
		#1: #right spawn
			#position = Vector2(500, randf_range(0 , 500))
			#apply_force(Vector2(-250, -(position.y-randnum))*initial_thrust)
		#2: #bottom spawn
			#position = Vector2(randf_range(0 , 500), 500)
			#apply_force(Vector2(-(position.x-randnum), -250)*initial_thrust)
		#3: #left spawn
			#position = Vector2(0, randf_range(0 , 500))
			#apply_force(Vector2(250, -(position.y-randnum))*initial_thrust)
	#look_at(Vector2(250, 250))
	#rotate(PI/2)


#freezes the player when they crash, kinda buggy
func _on_hitbox_body_entered(body):
	if body.name == "PlanetHitbox":
		game_over.emit()

func _on_timer_timeout() -> void:
	trajectory.add_point(position)
	if trajectory.get_point_count() > max_points:
		trajectory.remove_point(0)
