"""Run in Unreal Editor after compiling the C++ module and preparing Blender FBXs.
Refuses to overwrite an authored map. Regeneration goes to a new map name via WD_MAP_NAME.
"""
import os, sys, json
from pathlib import Path
import unreal as u

HERE=Path(__file__).resolve().parent
sys.path.insert(0,str(HERE))
from slice_layout import layout, verify_layout
ROOT=HERE.parents[1]
STAGING=ROOT/'unreal/Staging'
MAP='/Game/Maps/'+os.environ.get('WD_MAP_NAME','StairHall')
if u.EditorAssetLibrary.does_asset_exist(MAP):
    raise RuntimeError(f'{MAP} already exists; preserve it and use WD_MAP_NAME for a new revision.')
DATA=layout(); verify_layout(DATA)
ASSET_TOOLS=u.AssetToolsHelpers.get_asset_tools()
ACTORS=u.get_editor_subsystem(u.EditorActorSubsystem)
LEVELS=u.get_editor_subsystem(u.LevelEditorSubsystem)
MESHES=u.get_editor_subsystem(u.StaticMeshEditorSubsystem)

def load(path):
    value=u.load_asset(path)
    if not value: raise RuntimeError(f'Missing required asset: {path}')
    return value

def import_file(path, name, options=None):
    task=u.AssetImportTask()
    for key,value in dict(filename=str(path),destination_path='/Game/Imported',destination_name=name,
                          automated=True,replace_existing=False,save=True).items():
        task.set_editor_property(key,value)
    if options: task.set_editor_property('options',options)
    ASSET_TOOLS.import_asset_tasks([task])
    results=task.get_objects()
    if not results: raise RuntimeError(f'Import returned no objects: {path}')
    return results

meshes={}; ghost_mesh=None; ghost_animations={}; ghost_record=None
for entry in json.loads((STAGING/'assets.json').read_text(encoding='utf-8')):
    skeletal=entry.get('skeletal',False)
    options=u.FbxImportUI()
    options.set_editor_property('import_mesh',True)
    options.set_editor_property('import_as_skeletal',skeletal)
    options.set_editor_property('import_animations',skeletal)
    options.set_editor_property('import_materials',True)
    options.set_editor_property('import_textures',True)
    options.set_editor_property('automated_import_should_detect_type',False)
    options.set_editor_property('mesh_type_to_import',u.FBXImportType.FBXIT_SKELETAL_MESH if skeletal else u.FBXImportType.FBXIT_STATIC_MESH)
    if not skeletal:
        options.static_mesh_import_data.set_editor_property('combine_meshes',True)
        options.static_mesh_import_data.set_editor_property('auto_generate_collision',False)
    results=import_file(STAGING/entry['fbx'],entry['fbx'].split('.')[0],options)
    if skeletal:
        ghost_record=entry
        ghost_mesh=next((o for o in results if isinstance(o,u.SkeletalMesh)),None)
        if not ghost_mesh: raise RuntimeError('Ghost skeletal mesh import failed')
        animations=[u.load_asset(p) for p in u.EditorAssetLibrary.list_assets('/Game/Imported',recursive=True)]
        animations=[o for o in animations if isinstance(o,u.AnimSequence)]
        for clip in ('idle','walk','run'):
            ghost_animations[clip]=next((o for o in animations if clip in o.get_name().lower()),None)
            if not ghost_animations[clip]: raise RuntimeError('Missing ghost animation: '+clip)
    else:
        mesh=next((o for o in results if isinstance(o,u.StaticMesh)),None)
        if not mesh: raise RuntimeError('No static mesh: '+entry['name'])
        meshes[entry['name']]=mesh
        # Hollow cupboards need concave collision, not a convex solid box across the opening.
        body=mesh.get_editor_property('body_setup')
        body.set_editor_property('collision_trace_flag',u.CollisionTraceFlag.CTF_USE_COMPLEX_AS_SIMPLE)
        u.EditorAssetLibrary.save_loaded_asset(mesh)

def import_texture(rel,name):
    return next(o for o in import_file(ROOT/rel,name) if isinstance(o,u.Texture2D))

textures={
    'wood':import_texture('assets/textures/worn-oak.png','T_WornOak'),
    'floor':import_texture('assets/textures/old_wooden_floor_01/diff.jpg','T_OldFloor'),
    'plaster':import_texture('assets/textures/decrepit_wallpaper/diff.jpg','T_Wallpaper'),
}
materials={}
for name,texture in textures.items():
    mat=ASSET_TOOLS.create_asset('M_'+name,'/Game/Imported',u.Material,u.MaterialFactoryNew())
    tex=u.MaterialEditingLibrary.create_material_expression(mat,u.MaterialExpressionTextureSample)
    tex.set_editor_property('texture',texture)
    u.MaterialEditingLibrary.connect_material_property(tex,'RGB',u.MaterialProperty.MP_BASE_COLOR)
    rough=u.MaterialEditingLibrary.create_material_expression(mat,u.MaterialExpressionConstant)
    rough.set_editor_property('r',.92)
    u.MaterialEditingLibrary.connect_material_property(rough,'',u.MaterialProperty.MP_ROUGHNESS)
    u.MaterialEditingLibrary.recompile_material(mat)
    u.EditorAssetLibrary.save_loaded_asset(mat)
    materials[name]=mat

audio={}
for name in ('door','wail','key','ambient'):
    audio[name]=next(o for o in import_file(ROOT/f'assets/audio/{name}.wav','S_'+name) if isinstance(o,u.SoundWave))
    if name!='ambient':
        # Every positional cue needs explicit attenuation; engine defaults are not spatial.
        attenuation=u.SoundAttenuationSettings()
        attenuation.set_editor_property('attenuate',True)
        attenuation.set_editor_property('spatialize',True)
        attenuation.set_editor_property('attenuation_shape_extents',u.Vector(250,0,0))
        attenuation.set_editor_property('falloff_distance',2400)
        settings=ASSET_TOOLS.create_asset('A_'+name,'/Game/Imported',u.SoundAttenuation,u.SoundAttenuationFactory())
        settings.set_editor_property('attenuation',attenuation)
        audio[name].set_editor_property('attenuation_settings',settings)
        u.EditorAssetLibrary.save_loaded_asset(settings)
        u.EditorAssetLibrary.save_loaded_asset(audio[name])

if not LEVELS.new_level(MAP): raise RuntimeError('Could not create map')
cube=load('/Engine/BasicShapes/Cube.Cube')
def spawn(cls,label,position,yaw=0):
    actor=ACTORS.spawn_actor_from_class(cls,u.Vector(*position),u.Rotator(0,yaw,0))
    if not actor: raise RuntimeError('Could not spawn '+label)
    actor.set_actor_label(label)
    return actor

for b in DATA['boxes']:
    actor=spawn(u.StaticMeshActor,b['name'],b['centre'])
    component=actor.static_mesh_component
    component.set_static_mesh(cube)
    actor.set_actor_scale3d(u.Vector(*(s/100 for s in b['size'])))
    component.set_material(0,materials[b['material']])
    component.set_collision_profile_name('BlockAll')
    if not b['visible']: component.set_visibility(False)
    actor.set_editor_property('tags',[u.Name(b['role'])])

for i,p in enumerate(DATA['props']):
    actor=spawn(u.StaticMeshActor,f"Dressing_{i}_{p['asset']}",p['location'],p['yaw'])
    component=actor.static_mesh_component
    component.set_static_mesh(meshes[p['asset']])
    actor.set_actor_scale3d(u.Vector(p['scale'],p['scale'],p['scale']))
    component.set_collision_profile_name('NoCollision' if 'litter' in p['asset'] else 'BlockAll')

interactive=u.load_class(None,'/Script/WaitingForDawn.WDInteractable')
ghost_class=u.load_class(None,'/Script/WaitingForDawn.WDGhost')
if not interactive or not ghost_class: raise RuntimeError('Compile WaitingForDawnEditor before building the map')
door=spawn(interactive,'GroundFloorDoor',DATA['door'])
door.mesh.set_static_mesh(meshes['room_door'])
door.mesh.set_relative_rotation(u.Rotator(0,90,0),False,False)
door.handle.set_relative_location(u.Vector(98,-14,105),False,False)
door.set_editor_property('display_name',u.Text('parlour door'))
door.set_editor_property('interaction_sound',audio['door'])

cabinet=spawn(u.StaticMeshActor,'HollowCupboard',DATA['cupboard'])
cabinet.static_mesh_component.set_static_mesh(meshes['cupboard_shell'])
cabinet.static_mesh_component.set_collision_profile_name('BlockAll')
cupboard=spawn(interactive,'CupboardLeaf',[-568,0,0])
cupboard.mesh.set_static_mesh(meshes['cupboard_leaf'])
cupboard.handle.set_relative_location(u.Vector(82,-12,98),False,False)
cupboard.set_editor_property('display_name',u.Text('cupboard'))
cupboard.set_editor_property('open_yaw',-100.0)
cupboard.set_editor_property('interaction_sound',audio['door'])
key=spawn(interactive,'VisibleCupboardKey',[-520,20,75])
key.mesh.set_static_mesh(meshes['key'])
key.mesh.set_relative_scale3d(u.Vector(.4,.4,.4))
key.set_editor_property('kind',u.WDInteraction.KEY)
key.set_editor_property('container',cupboard)
key.set_editor_property('grants_key',u.Name('Nursery'))
key.set_editor_property('display_name',u.Text('small brass key'))
key.set_editor_property('open_offset',u.Vector(47,10,75))
key.set_editor_property('interaction_sound',audio['key'])

for i,position in enumerate(DATA['starts']): spawn(u.PlayerStart,f'SurvivorStart_{i}',position)
ghost=spawn(ghost_class,'Eleanor',DATA['ghost'],180)
ghost.set_editor_property('patrol_points',[u.Vector(*p) for p in DATA['patrol']])
ghost.set_editor_property('warning_sound',audio['wail'])
ghost.mesh.set_skeletal_mesh_asset(ghost_mesh)
ghost_scale=ghost_record['target_height_cm']/(ghost_record['source_height_m']*100)
ghost.mesh.set_relative_scale3d(u.Vector(ghost_scale,ghost_scale,ghost_scale))
ghost.mesh.set_relative_location(u.Vector(0,0,-88-ghost_record['source_min_z_m']*100*ghost_scale),False,False)
for clip,animation in ghost_animations.items(): ghost.set_editor_property(clip+'_animation',animation)

for i,position in enumerate(DATA['lights']):
    light=spawn(u.PointLight,f'WarmFixture_{i}',position)
    light.point_light_component.set_mobility(u.ComponentMobility.MOVABLE)
    light.point_light_component.set_intensity(700)
    light.point_light_component.set_light_color(u.LinearColor(1,.62,.32))
    light.point_light_component.set_attenuation_radius(700)
sky=spawn(u.SkyLight,'LowAmbient',[0,0,700])
sky.light_component.set_intensity(.08)
nav=spawn(u.NavMeshBoundsVolume,'WholeHouseNavigation',[0,0,320])
nav.set_actor_scale3d(u.Vector(8,6,5))
world=u.get_editor_subsystem(u.UnrealEditorSubsystem).get_editor_world()
u.SystemLibrary.execute_console_command(world,'RebuildNavigation')
if not LEVELS.save_current_level(): raise RuntimeError('Map save failed')
u.EditorAssetLibrary.save_directory('/Game/Imported',only_if_is_dirty=False,recursive=True)
print('WD_MAP_CREATED',MAP,'Runtime traversal and navigation validation still required.')
