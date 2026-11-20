extends SceneTree
class TestGame extends "res://Godot/game.gd":
    func save_path() -> String: return "user://background-regression.json"
var failures: Array[String] = []
const PROFILES := ["gas-arc","dust-veil","planet-limb","supernova-remnant","solar-aurora","deep-void","cryo-cloud","ion-storm"]
func check(ok: bool, text: String) -> void:
    if not ok: failures.append(text)
func _initialize() -> void: call_deferred("run")
func run() -> void:
    var game := TestGame.new()
    root.add_child(game)
    game.set_physics_process(false)
    check(game.sector_backgrounds.size() == 100,"all sectors have ambience")
    var used := {}
    for sector in range(100):
        check(game.sector_backgrounds.has(4107+sector),"assigned sector %d" % sector)
        var profile: Dictionary = game.sector_backgrounds[4107+sector]
        check(profile.texture != null and profile.size.x > 0 and profile.size.y > 0 and profile.parallax > 0,"valid profile")
        used[profile.id] = true
        if game.sector_specs[sector].ice: check(profile.id == "cryo-cloud","ice ambience")
    for name in PROFILES: check(used.has(name),"profile used "+name)
    check(game.sector_backgrounds[4108].texture.resource_path.ends_with("nebula-4108.png"),"Nacar preserved")
    check(game.sector_backgrounds[4115].texture.resource_path.ends_with("nebula-4115.png"),"Vesper preserved")
    for name in ["solar-aurora","deep-void","cryo-cloud","ion-storm"]:
        var texture: Texture2D
        for profile in game.sector_backgrounds.values():
            if profile.id == name: texture = profile.texture; break
        var art := texture.get_image()
        for x in range(art.get_width()):
            check(art.get_pixel(x,0).a <= .01 and art.get_pixel(x,art.get_height()-1).a <= .01,"alpha top/bottom "+name)
        for y in range(art.get_height()):
            check(art.get_pixel(0,y).a <= .01 and art.get_pixel(art.get_width()-1,y).a <= .01,"alpha sides "+name)
    print("BACKGROUND_REGRESSION ","PASS" if failures.is_empty() else failures.slice(0,10))
    game.queue_free()
    quit(0 if failures.is_empty() else 1)
