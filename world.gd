extends Node

@onready var main_menu = $CanvasLayer/MainMenu
@onready var logo = $CanvasLayer/Logo
@onready var menubg = $CanvasLayer/MenuBG
@onready var address_entry = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/AddressEntry
@onready var hud = $CanvasLayer/HUD
@onready var healthbar = $CanvasLayer/HUD/MarginContainer/HBoxContainer/Label

const Player = preload("res://player.tscn")
const PORT = 37288
var enet_peer = ENetMultiplayerPeer.new()

func _unhandled_input(event):
	#if Input.is_action_just_pressed("quit") and main_menu.visible == false:
		#Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		#$MenuUp.play()
		#logo.show()
		#menubg.show()
		#main_menu.show()
		#hud.hide()
		#$Camera3D.current = true
	if Input.is_action_just_pressed("quit") and main_menu.visible == false and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif Input.is_action_just_pressed("quit") and main_menu.visible == false and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

# Called when the node enters the scene tree for the first time.
func _ready():
	$MenuUp.play()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_host_button_pressed():
	$MenuSelect.play()
	main_menu.hide()
	logo.hide()
	menubg.hide()
	$MenuDown.play()
	hud.show()
	
	$Camera3D.current = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	enet_peer.create_server(PORT)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	
	add_player(multiplayer.get_unique_id())
	
	upnp_setup()


func _on_join_button_pressed():
	$MenuSelect.play()
	main_menu.hide()
	logo.hide()
	menubg.hide()
	$MenuDown.play()
	hud.show()
	
	$Camera3D.current = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	enet_peer.create_client(address_entry.text,PORT)
	#enet_peer.create_client('localhost',PORT)
	multiplayer.multiplayer_peer = enet_peer


func add_player(peer_id):
	var player = Player.instantiate()
	player.name = str(peer_id)
	add_child(player)
	player.health_changed.connect(update_health_bar)
	$Talk.play()
	
func remove_player(peer_id):
	var player = get_node_or_null(str(peer_id))
	if player:
		player.queue_free()
	$Talk.play()

func update_health_bar(health_value):
	match typeof(str(health_value)):
		TYPE_STRING:
			healthbar.text = String("• " + str(health_value))


func _on_multiplayer_spawner_spawned(node):
	if node.is_multiplayer_authority():
		node.health_changed.connect(update_health_bar)


func upnp_setup():
	var upnp = UPNP.new()
	
	var discover_result = upnp.discover()
	assert(discover_result == upnp.UPNP_RESULT_SUCCESS, \
		"UPNP Discover failed! Error %s" % discover_result)
	
	assert(upnp.get_gateway() and upnp.get_gateway().is_valid_gateway(), \
		"UPNP Invalid gateway!")
	
	var map_result = upnp.add_port_mapping(PORT)
	assert(map_result == upnp.UPNP_RESULT_SUCCESS, \
		"UPNP port mapping failed! Error %s" % map_result)
	
	print("Success! Join address: %s" % upnp.query_external_address())

func _on_play_button_pressed():
	$MenuSelect.play()
	main_menu.hide()
	logo.hide()
	menubg.hide()
	$MenuDown.play()
	hud.show()
	
	$Camera3D.current = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	add_player(multiplayer.get_unique_id())


func _on_address_entry_text_submitted(new_text):
	$MenuGlow.play()
