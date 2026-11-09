class_name CrystalChip
extends PanelContainer
## Small "crystal count" chip used in several screens; refreshes on currency changes.

var _label: Label

func _init() -> void:
    theme_type_variation = "GlassPanel"
    var h := HBoxContainer.new()
    h.add_theme_constant_override("separation", 10)
    add_child(h)
    h.add_child(UIKit.crystal_icon(40))
    _label = UIKit.label("0", 38, GameConfig.COL_GOLD)
    h.add_child(_label)

func _ready() -> void:
    refresh()
    ProgressionManager.crystals_changed.connect(func(_t: int) -> void: refresh())

func refresh() -> void:
    _label.text = GameConfig.format_int(ProgressionManager.crystals())
