extends XROrigin3D

@export var move_speed: float = 2.5
@export var deadzone: float = 0.15
@export var snap_angle_deg: float = 45.0
@export var gravity: float = 9.8

@onready var xr_camera: XRCamera3D = $XRCamera3D
@onready var left_ctrl: XRController3D = $LeftController
@onready var right_ctrl: XRController3D = $RightController

var can_snap_turn: bool = true
var player_body: CharacterBody3D

func _ready() -> void:
    player_body = CharacterBody3D.new()
    player_body.floor_snap_length = 0.05
    var col := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.25
    capsule.height = 1.6
    col.shape = capsule
    col.position.y = 0.8
    player_body.add_child(col)
    get_parent().call_deferred("add_child", player_body)

func _physics_process(delta: float) -> void:
    if not is_instance_valid(player_body) or not player_body.is_inside_tree():
        return

    # Wyliczamy przesunięcie głowy względem XROrigin3D w płaszczyźnie XZ
    var head_offset := xr_camera.global_position - global_position
    head_offset.y = 0.0

    # Ustawiamy kapsułę fizyczną dokładnie pod Twoją głową (z lekkim zapasem 2 cm w górę, żeby nie utknąć w podłodze po teleporcie)
    player_body.global_position = global_position + head_offset + Vector3(0, 0.02, 0)

    _handle_smooth_movement(delta)
    _handle_snap_turn()

    # Po przeliczeniu kolizji i grawitacji przesuwamy XROrigin3D z powrotem względem pozycji głowy
    var new_pos := player_body.global_position - head_offset
    if player_body.is_on_floor():
        new_pos.y = player_body.global_position.y
    global_position = new_pos

func _handle_smooth_movement(delta: float) -> void:
    var v: Vector2 = left_ctrl.get_vector2("thumbstick")
    var dir := Vector3.ZERO

    if v.length() >= deadzone:
        var fwd: Vector3 = -xr_camera.global_transform.basis.z
        fwd.y = 0.0
        fwd = fwd.normalized()

        var right: Vector3 = xr_camera.global_transform.basis.x
        right.y = 0.0
        right = right.normalized()

        dir = (fwd * v.y + right * v.x).normalized()

    player_body.velocity.x = dir.x * move_speed
    player_body.velocity.z = dir.z * move_speed

    if not player_body.is_on_floor():
        player_body.velocity.y -= gravity * delta
    else:
        player_body.velocity.y = 0.0

    player_body.move_and_slide()

func _handle_snap_turn() -> void:
    var v: Vector2 = right_ctrl.get_vector2("thumbstick")
    
    if abs(v.x) < 0.3:
        can_snap_turn = true
        return

    if can_snap_turn and abs(v.x) > 0.7:
        can_snap_turn = false
        var angle_rad: float = deg_to_rad(-sign(v.x) * snap_angle_deg)
        
        var cam_pos: Vector3 = xr_camera.global_position
        global_translate(-cam_pos)
        rotate_y(angle_rad)
        global_translate(cam_pos)
