extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready():
	var anim = get_node("AnimationPlayer").get_animation("Armature|Armature|Armature|mixamo_com|Layer0")
	anim.loop_mode = (Animation.LOOP_LINEAR)
	$AnimationPlayer.play("Armature|Armature|Armature|mixamo_com|Layer0",1,1,false)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
