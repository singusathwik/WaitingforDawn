"""Idempotent repair for already-imported house art; no layout regeneration."""
import unreal as u
import sys
from pathlib import Path
sys.path.insert(0,str(Path(__file__).parent))
from mourning_material import apply
apply()
levels=u.get_editor_subsystem(u.LevelEditorSubsystem)
assert levels.load_level('/Game/Maps/House')
mesh=u.load_asset('/Game/Imported/SK_Eleanor')
materials=list(mesh.get_editor_property('materials'))
for m in materials:
    slot=str(m.get_editor_property('imported_material_slot_name')).lower()
    m.set_editor_property('material_interface',u.load_asset('/Game/Imported/M_MourningFabric' if 'cloth' in slot else '/Game/Imported/M_EleanorSkin'))
mesh.set_editor_property('materials',materials)
u.EditorAssetLibrary.save_loaded_asset(mesh)
for a in u.get_editor_subsystem(u.EditorActorSubsystem).get_all_level_actors():
    if a.get_actor_label()=='Eleanor':
        a.set_actor_location(u.Vector(0,350,-230),False,False)
        a.set_editor_property('patrol_points',[u.Vector(*p) for p in [[0,-800,-230],[0,350,-230],[0,-850,90],[0,400,90],[-1350,700,90],[-400,700,410],[0,-900,410],[0,400,410]]])
    if a.get_actor_label()=='TheKeeper':
        center,extent=a.get_actor_bounds(False)
        a.set_actor_location(a.get_actor_location()+u.Vector(-1100-center.x,160-center.y,323+extent.z-center.z),False,False)
        print('KEEPER_FINAL_BOUNDS',a.get_actor_bounds(False))
actors=u.get_editor_subsystem(u.EditorActorSubsystem)
labels={a.get_actor_label() for a in actors.get_all_level_actors()}
for x in (-900,900):
    label='CourtyardBlueFill_'+str(x)
    if label in labels:continue
    a=actors.spawn_actor_from_class(u.PointLight,u.Vector(x,-1900,480));a.set_actor_label(label)
    c=a.point_light_component;c.set_mobility(u.ComponentMobility.MOVABLE);c.set_editor_property('intensity_units',u.LightUnits.LUMENS);c.set_intensity(500);c.set_attenuation_radius(1400);c.set_light_color(u.LinearColor(.25,.35,.6));c.set_cast_shadows(False)
assert levels.save_current_level()
