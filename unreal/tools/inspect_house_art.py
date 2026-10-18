import unreal as u
u.get_editor_subsystem(u.LevelEditorSubsystem).load_level('/Game/Maps/House')
mesh=u.load_asset('/Game/Imported/SK_Eleanor')
for m in mesh.get_editor_property('materials'):
    print('GHOST_SLOT',m.get_editor_property('material_slot_name'),m.get_editor_property('imported_material_slot_name'),m.get_editor_property('material_interface').get_name())
for a in u.get_editor_subsystem(u.EditorActorSubsystem).get_all_level_actors():
    if a.get_actor_label()=='TheKeeper':print('KEEPER_BOUNDS',a.get_actor_bounds(False),a.get_actor_location(),a.get_actor_rotation())
