extends SceneTree
class PreviewGame extends "res://Godot/game.gd":
    func save_path() -> String: return "user://ambience-preview.json"
func _initialize() -> void: call_deferred("preview")
func preview() -> void:
    var game := PreviewGame.new()
    root.add_child(game)
    game.set_physics_process(false)
    game.hangar = false
    game.pos = Vector2.ZERO
    game.zoom = 1
    for name in ["gas-arc","dust-veil","planet-limb","supernova-remnant","solar-aurora","deep-void","cryo-cloud","ion-storm"]:
        for i in range(100):
            if game.sector_backgrounds[4107+i].id == name:
                game.sector = i
                game.rocks = game.fields[i]
                game.fragments = game.sector_loot[i]
                break
        game.queue_redraw()
        await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png("res://build/background-preview-"+name+".png")
    quit()
