extends CharacterBody2D

var speed = 300.0

@onready var enemy = get_parent().get_node("Enemy")

func _physics_process(delta):

	var direction = Vector2.ZERO

	if Input.is_action_pressed("move_up"):
		direction.y -= 1

	if Input.is_action_pressed("move_down"):
		direction.y += 1

	if Input.is_action_pressed("move_left"):
		direction.x -= 1

	if Input.is_action_pressed("move_right"):
		direction.x += 1

	if direction.length() > 0:
		direction = direction.normalized()

	velocity = direction * speed

	move_and_slide()
	if Input.is_action_just_pressed("attack"):
		attack()
		
func attack():
	print("ATTACK!")

	var distance = global_position.distance_to(enemy.global_position)

	if distance < 150:
		print("ENEMY HIT!")

		enemy.color = Color.WHITE

		await get_tree().create_timer(0.2).timeout

		enemy.color = Color.RED
