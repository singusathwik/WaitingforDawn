"""Update existing saved map/audio/materials in place; preserve accepted house geometry."""
import unreal as u
u.load_module('BinkAudioDecoder')
import sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(Path(__file__).parent))
from mourning_material import apply
apply()
levels=u.get_editor_subsystem(u.LevelEditorSubsystem)
assert levels.load_level('/Game/Maps/House')
for name in ('introduction','wail','breath','stinger'):
    task=u.AssetImportTask();task.filename=str(ROOT/'unreal/Audio'/f'{name}.wav');task.destination_path='/Game/Imported';task.destination_name='S_'+name;task.automated=True;task.replace_existing=True;task.save=True
    u.AssetToolsHelpers.get_asset_tools().import_asset_tasks([task])
    sound=u.load_asset('/Game/Imported/S_'+name);assert sound
    sound.set_editor_property('looping',name=='breath')
    sound.set_editor_property('attenuation_settings',None if name in ('introduction','breath') else u.load_asset('/Game/Imported/A_'+('wail' if name=='wail' else 'stinger')))
    u.EditorAssetLibrary.save_loaded_asset(sound)
skin=u.load_asset('/Game/Imported/M_EleanorSkin')
u.MaterialEditingLibrary.delete_all_material_expressions(skin)
tex=u.MaterialEditingLibrary.create_material_expression(skin,u.MaterialExpressionTextureSample)
tex.set_editor_property('texture',u.load_asset('/Game/Imported/M_EleanorSkin_texture'))
assert u.MaterialEditingLibrary.connect_material_property(tex,'RGB',u.MaterialProperty.MP_BASE_COLOR)
rough=u.MaterialEditingLibrary.create_material_expression(skin,u.MaterialExpressionConstant);rough.set_editor_property('r',.9)
assert u.MaterialEditingLibrary.connect_material_property(rough,'',u.MaterialProperty.MP_ROUGHNESS)
# Texture-modulated low light keeps mottled skin visible without a flat grey silhouette.
glow=u.MaterialEditingLibrary.create_material_expression(skin,u.MaterialExpressionMultiply)
glow.set_editor_property('const_b',.16)
assert u.MaterialEditingLibrary.connect_material_expressions(tex,'RGB',glow,'A')
assert u.MaterialEditingLibrary.connect_material_property(glow,'',u.MaterialProperty.MP_EMISSIVE_COLOR)
skin.set_editor_property('used_with_skeletal_mesh',True)
u.MaterialEditingLibrary.recompile_material(skin);u.EditorAssetLibrary.save_loaded_asset(skin)
route=[[0,350,-230],[0,-800,-230],[0,350,-230],[0,400,90],[0,-760,90],[-450,-760,90],[0,-760,90],[0,140,90],[-450,140,90],[0,400,90],[0,400,410],[-450,140,410],[0,140,410],[0,-900,410],[0,400,410],[0,400,730],[0,-900,730],[0,400,730],[0,400,410],[0,400,90]]
for a in u.get_editor_subsystem(u.EditorActorSubsystem).get_all_level_actors():
    if a.get_actor_label()=='Eleanor':
        a.set_editor_property('patrol_points',[u.Vector(*p)for p in route])
        a.set_editor_property('attack_animation',u.load_asset('/Game/Imported/SK_Eleanor_Anim_Armature_attack2_Armature'))
        a.set_editor_property('warning_sound',u.load_asset('/Game/Imported/S_wail'))
        print('GHOST_MESH',a.mesh.get_editor_property("relative_location"),a.mesh.get_editor_property("relative_scale3d"),a.get_actor_bounds(False))
assert levels.save_current_level()
print('ENCOUNTERS_091_SAVED')
