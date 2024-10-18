extends CharacterBody3D

signal health_changed(health_value)

@onready var camera = $Camera3D
@onready var player = $GordonModel
@onready var audiolistner = $GordonModel/AudioListener3D
@onready var raycast = $Camera3D/RayCast3D
@onready var anim_player = $AnimationPlayer
@onready var gun = $Camera3D/gun
@onready var gunsound = $GordonModel/gunshot
@onready var walksound1 = $GordonModel/walk1
@onready var walksound2 = $GordonModel/walk2
@onready var walksound3 = $GordonModel/walk3
@onready var walksound4 = $GordonModel/walk4
@onready var deathsound = $GordonModel/death
@onready var gunpickupsound = $GordonModel/gunpickup
@onready var muzzleflash = $Camera3D/gun/MuzzleFlash

var health = 100

const SPEED = 9
const JUMP_VELOCITY = 6

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _enter_tree():
	set_multiplayer_authority(str(name).to_int())

func _ready():
	if not is_multiplayer_authority(): return
	player.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.current = true
	camera.position = Vector3(0,1.711,-0.188)
	camera.rotation = Vector3(0,0,0)
	gunpickupsound.play()


func _unhandled_input(event):
	if not is_multiplayer_authority(): return
	audiolistner.make_current()
	if event is InputEventMouseMotion and not camera.rotation.z == -90:
		rotate_y(-event.relative.x * .005)
		camera.rotate_x(-event.relative.y * .005)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)
	if Input.is_action_just_pressed("fire") \
		and anim_player.current_animation != "shot" and not camera.rotation.z == -90:
		play_shoot_effects.rpc()
		if raycast.is_colliding():
			var hit_player = raycast.get_collider()
			hit_player.recieve_damage.rpc_id(hit_player.get_multiplayer_authority())
	if Input.is_action_just_pressed("kill") and not camera.rotation.z == -90:
		health = 0
		health_changed.emit(health)
		deathsound.play()
		gun.visible = false
		player.rotation = Vector3(0,0,-90)
		camera.position = Vector3(0,0.2,0)
		camera.rotation = Vector3(0,0,-90)
	if Input.is_action_just_pressed("jump") \
		and camera.rotation.z == -90:
		velocity.y = 0
		gun.visible = true
		position = Vector3.ZERO
		player.rotation = Vector3(0,0,0)
		camera.position = Vector3(0,1.711,-0.188)
		camera.rotation = Vector3(0,0,0)
		gunpickupsound.play()
		health = 100
		health_changed.emit(health)
	if Input.is_action_just_pressed("crouch") and not camera.rotation.z == -90:
		velocity.y -= 10000

func _physics_process(delta):
	if not is_multiplayer_authority(): return
	var walksoundrandom = [walksound1, walksound2, walksound3, walksound4]
	var walksound = walksoundrandom[randi() % walksoundrandom.size()]
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("jump") and is_on_floor() and not camera.rotation.z == -90:
		velocity.y = JUMP_VELOCITY
		walksound.play()

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	if not camera.rotation.z == -90:
		var input_dir = Input.get_vector("left", "right", "up", "down")
		var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if direction:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)
		
		if anim_player.current_animation == "shot":
			pass
		elif input_dir != Vector2.ZERO and is_on_floor():
			anim_player.play("move")
			
			walksound.play()
			
		else:
			anim_player.play("idle")
		
	else:
		velocity.x = 0
		velocity.z = 0
	move_and_slide()

@rpc("call_local")
func play_shoot_effects():
	anim_player.stop()
	anim_player.play("shot")
	gunsound.play()
	muzzleflash.restart()

@rpc("any_peer")
func recieve_damage():
	health -= 25
	if health == 0:
		deathsound.play()
		gun.visible = false
		player.rotation = Vector3(0,0,-90)
		camera.position = Vector3(0,0.2,0)
		camera.rotation = Vector3(0,0,-90)
	health_changed.emit(health)
	
