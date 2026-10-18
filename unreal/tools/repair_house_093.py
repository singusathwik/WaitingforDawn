"""Targeted in-place repair; preserve all accepted room and Eleanor assets."""
from pathlib import Path
import json
import unreal as u
root=Path(__file__).resolve().parents[2]
levels=u.get_editor_subsystem(u.LevelEditorSubsystem)
assert levels.load_level('/Game/Maps/House')
changed=[]
for actor in u.get_editor_subsystem(u.EditorActorSubsystem).get_all_level_actors():
    label=actor.get_actor_label();p=actor.get_actor_location()
    if label.startswith('Hinged_portrait_'):
        actor.set_editor_property('open_yaw',-100.0);changed.append(label)
    if label=='EscapeCar':
        actor.mesh.set_relative_rotation(u.Rotator(yaw=-90),False,False);changed.append(label)
    # The garage dresser previously obstructed the car's exit path. Move its
    # shell and six independent trays together; this room contains no key stash.
    if label.startswith('Garage_drawer_') and p.x>700:
        actor.set_actor_location(p-u.Vector(350,0,0),False,False);changed.append(label)
    if isinstance(actor,u.StaticMeshActor):
        mesh=actor.static_mesh_component.static_mesh
        if mesh and mesh.get_name()=='SM_dresser' and abs(p.x-900)<5 and abs(p.y+1030)<5 and abs(p.z)<5:
            actor.set_actor_location(p-u.Vector(350,0,0),False,False);changed.append(label)
        if label.startswith('Skirting') and abs(p.x-900)<5 and abs(p.y+1170)<5 and abs(p.z-12)<5:
            actor.set_actor_location(u.Vector(447.5,-1170,12),False,False)
            actor.set_actor_scale3d(u.Vector(4.45,.08,.24));actor.set_actor_label('GarageSkirtingLeft')
            other=u.get_editor_subsystem(u.EditorActorSubsystem).spawn_actor_from_class(u.StaticMeshActor,u.Vector(1422.5,-1170,12))
            other.set_actor_label('GarageSkirtingRight');other.static_mesh_component.set_static_mesh(mesh)
            other.static_mesh_component.set_material(0,actor.static_mesh_component.get_material(0))
            other.static_mesh_component.set_collision_profile_name('BlockAll');other.set_actor_scale3d(u.Vector(3.05,.08,.24));changed.append('Garage skirting opening')
assert levels.save_current_level()
actors=u.get_editor_subsystem(u.EditorActorSubsystem).get_all_level_actors()
portraits=[a for a in actors if a.get_actor_label().startswith('Hinged_portrait_')]
trays=[a for a in actors if a.get_actor_label().startswith('Garage_drawer_')]
assert len(portraits)==2 and all(a.get_editor_property('open_yaw')==-100 for a in portraits)
assert len(trays)==6 and all(a.get_actor_location().x<700 for a in trays)
assert any(a.get_actor_label()=='GarageSkirtingRight' for a in actors)
(root/'unreal/docs/evidence/map-repair-093.json').write_text(json.dumps({'changed_this_run':changed,'portraits_open_into_room':2,'garage_trays_moved_clear':6,'garage_skirting_cut':True,'scope':'portrait hinges, car forward axis, garage dresser/trays and skirting clearance'},indent=2)+'\n')
print('WD_MAP_REPAIR',json.dumps(changed))
