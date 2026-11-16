extends XRController3D

@onready var ray: RayCast3D = $TeleportRay
@onready var marker: MeshInstance3D = $TeleportMarker

var xr_origin: XROrigin3D
var xr_camera: XRCamera3D

func _ready() -> void:
    xr_origin = get_parent() as XROrigin3D
    xr_camera = xr_origin.get_node("XRCamera3D") as XRCamera3D
    marker.visible = false
    button_pressed.connect(_on_button_pressed)

func _process(_delta: float) -> void:
    # Pokazujemy dysk tylko wtedy, gdy celujemy w płaską powierzchnię (podłoga lub góra sześcianu)
    if ray.is_colliding() and ray.get_collision_normal().y > 0.7:
        marker.global_position = ray.get_collision_point() + Vector3(0, 0.01, 0)
        marker.visible = true
    else:
        marker.visible = false

func _on_button_pressed(button_name: String) -> void:
    if button_name == "trigger_click":
        teleport_now()

func teleport_now() -> void:
    if not ray.is_colliding() or ray.get_collision_normal().y <= 0.7:
        return
        
    var target: Vector3 = ray.get_collision_point()
    
    var cam_offset: Vector3 = xr_camera.global_position - xr_origin.global_position
    cam_offset.y = 0.0
    
    xr_origin.global_position = Vector3(
        target.x - cam_offset.x,
        target.y + 0.05,
        target.z - cam_offset.z
    )
