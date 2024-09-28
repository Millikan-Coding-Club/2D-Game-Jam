extends Node2D

@export var starting_gravity = 500
var gravity_strength = starting_gravity
@export var radius = 100


func _process(delta):
	queue_redraw()
		

func _draw():
	if GlobalVariables.debug:
		draw_circle(Vector2(0, 0), radius / scale.x, Color(0, 0, 1, 0.5))
