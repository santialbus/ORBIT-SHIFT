class_name SkinCatalog
extends RefCounted
## Static catalog of sphere skins (20) and core variants (5).
## style -> shader mode in shaders/skin.gdshader:
##  0 solid  1 plasma swirl  2 banded gradient  3 pulse  4 glitch  5 starfield  6 metallic  7 void rim

const SKINS := [
    {"id": "cyan_core",    "name": "Cyan Core",    "color": "19f0ff", "glow": "7dfaff", "style": 0, "price": 0,    "desc": "The standard energy sphere."},
    {"id": "plasma",       "name": "Plasma",       "color": "7a3cff", "glow": "ff5af0", "style": 1, "price": 80,   "desc": "Swirling magenta plasma."},
    {"id": "solar",        "name": "Solar",        "color": "ffb000", "glow": "fff08a", "style": 3, "price": 120,  "desc": "A pulsing miniature sun."},
    {"id": "violet_pulse", "name": "Violet Pulse", "color": "9b5cff", "glow": "d6b8ff", "style": 3, "price": 160,  "desc": "Slow, hypnotic violet beat."},
    {"id": "inferno",      "name": "Inferno",      "color": "ff3b1f", "glow": "ffa23a", "style": 1, "price": 220,  "desc": "Molten surface, restless heat."},
    {"id": "quantum",      "name": "Quantum",      "color": "2bffb0", "glow": "b8fff0", "style": 4, "price": 280,  "desc": "Flickers between states."},
    {"id": "nebula",       "name": "Nebula",       "color": "4d6bff", "glow": "ff7ad9", "style": 5, "price": 340,  "desc": "A pocket of deep space."},
    {"id": "shadow",       "name": "Shadow",       "color": "1b1f33", "glow": "8f7bff", "style": 7, "price": 400,  "desc": "Dark matter with a violet halo."},
    {"id": "golden_core",  "name": "Golden Core",  "color": "ffc233", "glow": "fff2b0", "style": 6, "price": 600,  "desc": "Polished gold, pure prestige."},
    {"id": "glacier",      "name": "Glacier",      "color": "9fe8ff", "glow": "e8fbff", "style": 2, "price": 180,  "desc": "Frozen light in icy bands."},
    {"id": "toxic",        "name": "Toxic",        "color": "9dff2e", "glow": "e6ff9a", "style": 4, "price": 260,  "desc": "Unstable green isotope."},
    {"id": "rose_quartz",  "name": "Rose Quartz",  "color": "ff7aa8", "glow": "ffd0e0", "style": 2, "price": 200,  "desc": "Soft crystalline pink."},
    {"id": "ion_storm",    "name": "Ion Storm",    "color": "2f7bff", "glow": "9fd0ff", "style": 1, "price": 320,  "desc": "Electric storm in a sphere."},
    {"id": "aurora",       "name": "Aurora",       "color": "37ffb8", "glow": "c07bff", "style": 2, "price": 380,  "desc": "Northern lights wrapped around."},
    {"id": "ember",        "name": "Ember",        "color": "ff6a2b", "glow": "ffd07a", "style": 3, "price": 240,  "desc": "A glowing coal that breathes."},
    {"id": "abyss",        "name": "Abyss",        "color": "0a2a5c", "glow": "19c3ff", "style": 7, "price": 450,  "desc": "Deep-sea darkness, bright rim."},
    {"id": "chrome",       "name": "Chrome",       "color": "cfd8ea", "glow": "ffffff", "style": 6, "price": 500,  "desc": "Liquid mirror metal."},
    {"id": "lunar",        "name": "Lunar",        "color": "b9c2d6", "glow": "f2f6ff", "style": 5, "price": 300,  "desc": "Moon dust and starlight."},
    {"id": "hyperion",     "name": "Hyperion",     "color": "ff2bd6", "glow": "2bf0ff", "style": 4, "price": 700,  "desc": "Neon glitch, two colors at war."},
    {"id": "singularity",  "name": "Singularity",  "color": "05060d", "glow": "ffffff", "style": 7, "price": 900,  "desc": "Nothing escapes. Almost nothing."},
]

## Core variants: palette changes scenery only, never difficulty.
const CORES := [
    {"id": "standard",     "name": "Standard Core",  "price": 0,    "core": "0d1f5c", "emit": "2b5cff", "ring": "9b5cff", "track": "6a5cff", "bg": "050a18", "light": "4d7bff"},
    {"id": "pulse_reactor","name": "Pulse Reactor",  "price": 300,  "core": "3a0d4f", "emit": "ff4df0", "ring": "ff7af5", "track": "c04dff", "bg": "0c0516", "light": "ff4df0"},
    {"id": "void_heart",   "name": "Void Heart",     "price": 600,  "core": "05060d", "emit": "19f0ff", "ring": "19f0ff", "track": "2b8fff", "bg": "010308", "light": "19f0ff"},
    {"id": "solar_forge",  "name": "Solar Forge",    "price": 900,  "core": "4a1505", "emit": "ff8a1f", "ring": "ffc233", "track": "ff7a3a", "bg": "100602", "light": "ff8a1f"},
    {"id": "aurora_prism", "name": "Aurora Prism",   "price": 1200, "core": "053a33", "emit": "37ffb8", "ring": "c07bff", "track": "37e0ff", "bg": "020c10", "light": "37ffb8"},
]

static func skin_ids() -> Array:
    var out: Array = []
    for s in SKINS:
        out.append(s["id"])
    return out

static func core_ids() -> Array:
    var out: Array = []
    for c in CORES:
        out.append(c["id"])
    return out

static func get_skin(id: String) -> Dictionary:
    for s in SKINS:
        if s["id"] == id:
            return s
    return SKINS[0]

static func get_core(id: String) -> Dictionary:
    for c in CORES:
        if c["id"] == id:
            return c
    return CORES[0]
