extends CanvasLayer

var stars = []

func _ready():
	generate_stars()

func generate_stars():
	for i in range(randi_range(200, 400)):
		var star = ColorRect.new()
		star.size = Vector2(1, 1)
		star.position = Vector2(randf_range(0, 500), randf_range(0, 500))
		add_child(star)
		stars.append(star)


func star_death():
	for i in stars:
		i.queue_free()
	stars = []
