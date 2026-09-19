extends SceneTree
func _init():
    var files = [
        'res://assets/graveyard_kit/character-keeper.glb',
        'res://assets/graveyard_kit/character-skeleton.glb',
        'res://assets/graveyard_kit/character-vampire.glb',
        'res://assets/graveyard_kit/character-zombie.glb',
        'res://assets/graveyard_kit/character-ghost.glb',
        'res://assets/space_kit/alien.glb'
    ]
    for f in files:
        print('=== Inspecting: ', f)
        var p = load(f) as PackedScene
        if p:
            var inst = p.instantiate()
            _dump_nodes(inst, '  ')
            inst.free()
    quit(0)

func _dump_nodes(n: Node, indent: String):
    var extra = ''
    if n is AnimationPlayer:
        var ap = n as AnimationPlayer
        extra = ' [Anims: ' + str(ap.get_animation_list()) + ']'
    print(indent + n.name + ' (' + n.get_class() + ')' + extra)
    for c in n.get_children():
        _dump_nodes(c, indent + '  ')
