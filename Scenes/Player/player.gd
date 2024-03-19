extends CharacterBody2D


var can_move: bool = true
var can_sprint: bool = true
var can_jump: bool = true

const SPEED = 300.0
#const JUMP_VELOCITY = -600.0

@export var jump_height: float = 150.0
@export var jump_time_to_peak: float = 0.5
@export var jump_time_to_descent: float = 0.3
@export var wall_time_to_descent: float = 0.8

@onready var jump_velocity: float # = ((2.0 * jump_height) / jump_time_to_peak) * -1.0
@onready var jump_gravity: float # = ((-2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)) * -1.0
@onready var fall_gravity: float # = ((-2.0 * jump_height) / (jump_time_to_descent * jump_time_to_descent)) * -1.0
@onready var wall_gravity: float # = ((-2.0 * jump_height) / (wall_time_to_descent * wall_time_to_descent)) * -1.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
#var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
#var gravity = 980

func _physics_process(delta):
	jump_velocity = ((2.0 * jump_height) / jump_time_to_peak) * -1.0
	jump_gravity = ((-2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)) * -1.0
	fall_gravity = ((-2.0 * jump_height) / (jump_time_to_descent * jump_time_to_descent)) * -1.0
	wall_gravity = ((-2.0 * jump_height) / (wall_time_to_descent * wall_time_to_descent)) * -1.0
	#print(jump_gravity,fall_gravity)
	# Add the gravity.
	if not is_on_floor():
		velocity.y += get_gravity() * delta
		if is_on_wall_only():
			wall_friction(delta)
	
	if is_on_floor() and not can_jump:
		can_jump = true
	elif can_jump and $Timers/CoyoteTime.is_stopped():
		$Timers/CoyoteTime.start()
	
	var direction = Input.get_axis("left", "right")
	# Handle Jump.
	jump()
	
	move(direction, delta)
	
	move_and_slide()

func move(direction, delta):
	if direction and can_move:
		#velocity.x = move_toward(direction * SPEED, SPEED, delta)
		velocity.x = direction * SPEED
		sprint()
		slow_friction(delta)
	else:
		# this control the "sliding" after character stops moving
		velocity.x = move_toward(velocity.x, 0, 20)

func sprint():
	if Input.is_action_pressed("sprint") and can_sprint:
		velocity.x *= 1.75
	if is_on_floor():
		can_sprint = true
	if not is_on_floor() and not Input.is_action_pressed("sprint"):
		can_sprint = false

func jump():
	if Input.is_action_just_pressed("jump") and can_jump:
		velocity.y = jump_velocity
	if Input.is_action_just_pressed("jump") and is_on_wall_only():# and Input.is_action_pressed("left"):
		can_move = false
		velocity.y = jump_velocity * 0.75
		velocity.x += SPEED * get_wall_normal().x * 2
		$Timers/WallJumpTimer.start()
	#if Input.is_action_just_pressed("jump") and is_on_wall_only() and Input.is_action_pressed("right"):
		#can_move = false
		#velocity.y = jump_velocity * 0.75
		#velocity.x += SPEED * get_wall_normal().x * 2
		#$WallJumpTimer.start()

func slow_friction(d):
	velocity.x -= .02 * d

func wall_friction(d):
	velocity.y += wall_time_to_descent * d
	velocity.y = min(velocity.y, wall_gravity)

func get_gravity() -> float:
	return jump_gravity if velocity.y < 0.0 else fall_gravity

func _on_wall_jump_timer_timeout():
	can_move = true

func _on_coyote_time_timeout():
	can_jump = false
