class_name BackdropScreen
extends Control
## Base class for screens drawn over the idle 3D backdrop.

var backdrop: OrbitBackdrop

func add_backdrop(v_offset: float = 0.0, auto_lane: bool = true) -> void:
    theme = UIKit.theme()
    var svc := SubViewportContainer.new()
    svc.stretch = true
    svc.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(svc)
    var sv := SubViewport.new()
    sv.own_world_3d = true
    svc.add_child(sv)
    backdrop = OrbitBackdrop.new()
    sv.add_child(backdrop)
    backdrop.setup(SkinManager.equipped_core_id(), SkinManager.equipped_skin_id(), v_offset, auto_lane)

func dim(alpha: float = 0.55) -> void:
    var d := ColorRect.new()
    d.color = Color(0.01, 0.02, 0.06, alpha)
    d.set_anchors_preset(Control.PRESET_FULL_RECT)
    d.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(d)
