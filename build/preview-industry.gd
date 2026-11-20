extends SceneTree
class PreviewGame extends "res://Godot/game.gd":
    func save_path() -> String: return "user://industry-preview.json"
func _initialize() -> void: call_deferred("preview")
func preview() -> void:
    var game := PreviewGame.new()
    root.add_child(game)
    game.set_physics_process(false)
    game.industry.open = true
    game.industry.selected = 44
    game.industry.page = 4
    await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://build/industry-godot-preview.png")
    game.industry.selected = 5
    game.industry.page = 0
    game.inventory[5] = 10
    game.industry.craft(game,5,1)
    game.queue_redraw()
    await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://build/industry-refining-preview.png")
    game.industry.tab = 1
    game.industry.page = 8
    game.queue_redraw()
    await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://build/industry-godot-materials-preview.png")
    quit()
