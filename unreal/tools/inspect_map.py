"""Read actual imported bounds/transforms without modifying the map."""
import unreal as u
import json
from pathlib import Path
u.load_module('BinkAudioDecoder')
u.get_editor_subsystem(u.LevelEditorSubsystem).load_level('/Game/Maps/StairHall')
actors=u.get_editor_subsystem(u.EditorActorSubsystem).get_all_level_actors()
rows=[]
def vector(v): return [round(v.x,3),round(v.y,3),round(v.z,3)]
def rotation(v): return dict(pitch=round(v.pitch,3),yaw=round(v.yaw,3),roll=round(v.roll,3))
for actor in actors:
    if actor.get_actor_label() not in ('GroundFloorDoor','HollowCupboard','CupboardLeaf','VisibleCupboardKey','Eleanor','WholeHouseNavigation'):continue
    centre,extent=actor.get_actor_bounds(False)
    row=dict(name=actor.get_actor_label(),location=vector(actor.get_actor_location()),rotation=rotation(actor.get_actor_rotation()),centre=vector(centre),extent=vector(extent))
    for component in actor.get_components_by_class(u.StaticMeshComponent):
        mesh=component.get_editor_property('static_mesh')
        row['mesh']=dict(asset=mesh.get_path_name(),relative_rotation=rotation(component.get_editor_property('relative_rotation')),
            local_bounds=[vector(v) for v in component.get_local_bounds()],collision=str(component.get_collision_enabled()))
    if row['name']=='HollowCupboard': assert abs(extent.z*2-200)<1
    if row['name']=='GroundFloorDoor':
        assert abs(extent.z*2-238)<1
        assert row['mesh']['relative_rotation']==dict(pitch=0.,yaw=90.,roll=0.)
    rows.append(row)
result=json.dumps(rows,indent=2)
print('WD_IMPORT_INSPECTION',result)
Path(u.Paths.project_saved_dir(),'Validation').mkdir(exist_ok=True)
Path(u.Paths.project_saved_dir(),'Validation','import-inspection.json').write_text(result)
