extends Camera2D

@onready var player: RigidBody2D = $"../Player"
@onready var planet: Node2D = $"../Planet"

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var player_dist = player.position.distance_to(planet.position)
	#if player_dist != 0:
		#zoom.x = 300 / (player_dist + 25)
		#zoom.y = zoom.x

	#interval zoom
	if player_dist < 200:
		zoom = Vector2(1.3, 1.3)
	if player_dist < 160:
		zoom = Vector2(1.6, 1.6)
	if player_dist < 120:
		zoom = Vector2(2, 2)
	if player_dist < 80:
		zoom = Vector2(3, 3)
