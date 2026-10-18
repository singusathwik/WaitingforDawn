"""Import the Blender redesign without replacing the repaired skeleton or animation clips."""
from pathlib import Path
import unreal as u, json, hashlib
ROOT=Path(__file__).resolve().parents[2];ART=ROOT/'design/eleanor-092'
DEST='/Game/Eleanor092';tools=u.AssetToolsHelpers.get_asset_tools()
protected=list((ROOT/'unreal/WaitingForDawn/Content/Imported').glob('SK_Eleanor_Anim_*.uasset'))+[ROOT/'unreal/WaitingForDawn/Content/Imported/SK_Eleanor_Skeleton.uasset']
assert len(protected)==6, 'Expected five repaired clips and their skeleton'
protected_hashes={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in protected}
u.EditorAssetLibrary.make_directory(DEST)

def import_asset(file,name,options=None,factory=None):
    t=u.AssetImportTask();t.filename=str(file);t.destination_path=DEST;t.destination_name=name
    t.automated=True;t.replace_existing=True;t.replace_existing_settings=True;t.save=True
    if options:t.options=options
    if factory:t.factory=factory
    tools.import_asset_tasks([t]);assets=t.get_objects()
    assert assets, 'No imported asset for '+str(file)
    return assets

textures={}
for key in ('face','cloth'):
    textures[key]=next(a for a in import_asset(ART/(key+'_albedo.png'),'T_'+key,None,u.TextureFactory()) if isinstance(a,u.Texture2D))

def material(name,color=None,texture=None,emission=0,rough=.9,two_sided=False):
    m=u.load_asset(DEST+'/'+name)
    if not m:m=tools.create_asset(name,DEST,u.Material,u.MaterialFactoryNew())
    u.MaterialEditingLibrary.delete_all_material_expressions(m)
    if texture:
        source=u.MaterialEditingLibrary.create_material_expression(m,u.MaterialExpressionTextureSample);source.set_editor_property('texture',texture);pin='RGB'
    else:
        source=u.MaterialEditingLibrary.create_material_expression(m,u.MaterialExpressionConstant3Vector);source.set_editor_property('constant',u.LinearColor(*color));pin=''
    assert u.MaterialEditingLibrary.connect_material_property(source,pin,u.MaterialProperty.MP_BASE_COLOR)
    if emission:
        glow=u.MaterialEditingLibrary.create_material_expression(m,u.MaterialExpressionMultiply);glow.set_editor_property('const_b',emission)
        assert u.MaterialEditingLibrary.connect_material_expressions(source,pin,glow,'A')
        assert u.MaterialEditingLibrary.connect_material_property(glow,'',u.MaterialProperty.MP_EMISSIVE_COLOR)
    r=u.MaterialEditingLibrary.create_material_expression(m,u.MaterialExpressionConstant);r.set_editor_property('r',rough)
    assert u.MaterialEditingLibrary.connect_material_property(r,'',u.MaterialProperty.MP_ROUGHNESS)
    spec=u.MaterialEditingLibrary.create_material_expression(m,u.MaterialExpressionConstant);spec.set_editor_property('r',.22)
    assert u.MaterialEditingLibrary.connect_material_property(spec,'',u.MaterialProperty.MP_SPECULAR)
    m.set_editor_property('used_with_skeletal_mesh',True);m.set_editor_property('two_sided',two_sided)
    u.MaterialEditingLibrary.recompile_material(m);u.EditorAssetLibrary.save_loaded_asset(m);return m

mats={
 'face':material('M_DreadFace',texture=textures['face'],emission=.13),
 'cloth':material('M_DreadCloth',texture=textures['cloth'],emission=.12,two_sided=True),
 'hair':material('M_DreadHair',color=(.008,.010,.012),emission=.10,rough=.57,two_sided=True),
 'cavity':material('M_DreadCavity',color=(.001,.0007,.0015),rough=.95,two_sided=True),
 'ivory':material('M_DreadIvory',color=(.14,.115,.075),emission=.04,rough=.8),
 'eye':material('M_DreadEye',color=(.22,.24,.20),emission=.18,rough=.31),
 'rust':material('M_DreadRust',color=(.11,.043,.018),rough=.8),
 'arms':material('M_DreadArms',texture=u.load_asset('/Game/Imported/M_EleanorSkin_texture'),emission=.10)
}
# The face replaces the original head, but the retained hands still use their credited UV map.
old=u.load_asset('/Game/Imported/SK_Eleanor');assert old
skeleton=old.get_editor_property('skeleton')
options=u.FbxImportUI();options.import_mesh=True;options.import_as_skeletal=True;options.import_animations=False
options.import_materials=False;options.import_textures=False;options.automated_import_should_detect_type=False
options.mesh_type_to_import=u.FBXImportType.FBXIT_SKELETAL_MESH;options.skeleton=skeleton
options.create_physics_asset=False;options.physics_asset=old.get_editor_property('physics_asset')
options.skeletal_mesh_import_data.convert_scene_unit=True
# UE's legacy skeletal reimport retained a converted transform and alternated
# between metre and centimetre bounds. Recreate only this generated mesh and its
# generated physics asset; never delete or reimport the shared rig/animations.
for generated in ('SK_EleanorDread','SK_EleanorDread_PhysicsAsset'):
    path=DEST+'/'+generated
    if u.EditorAssetLibrary.does_asset_exist(path):
        assert u.EditorAssetLibrary.delete_asset(path), 'Cannot replace generated asset: '+path
assets=import_asset(ART/'SK_EleanorDread.fbx','SK_EleanorDread',options,u.FbxFactory())
mesh=next(a for a in assets if isinstance(a,u.SkeletalMesh))
assert mesh.get_editor_property('skeleton')==skeleton, 'Skeleton compatibility failed'
assert 350<mesh.get_bounds().box_extent.z<500, 'FBX reimport changed centimetre scale'
mesh.set_editor_property('physics_asset',old.get_editor_property('physics_asset'))
# The rig is unchanged. Reuse its full-body physics bounds rather than the
# partial arm-only bodies that automatic fitting produced for the new dress.
reference=u.SkeletonModifier();reference.set_skeletal_mesh(old)
candidate=u.SkeletonModifier();candidate.set_skeletal_mesh(mesh)
for bone in ('dawnroot','head','hips'):
    a=reference.get_bone_transform(bone,True);b=candidate.get_bone_transform(bone,True)
    assert (a.translation-b.translation).length()<.01 and (a.scale3d-b.scale3d).length()<.01, 'Bind transform changed: '+bone
slots=list(mesh.get_editor_property('materials'));assigned=[]
for slot in slots:
    name=str(slot.get_editor_property('imported_material_slot_name')).lower()
    key=next((k for k in mats if 'dread'+k in name),'arms')
    slot.set_editor_property('material_interface',mats[key]);assigned.append({'slot':name,'material':mats[key].get_path_name()})
mesh.set_editor_property('materials',slots);u.EditorAssetLibrary.save_loaded_asset(mesh)
levels=u.get_editor_subsystem(u.LevelEditorSubsystem);assert levels.load_level('/Game/Maps/House')
found=False
for actor in u.get_editor_subsystem(u.EditorActorSubsystem).get_all_level_actors():
    if actor.get_actor_label()!='Eleanor':continue
    actor.mesh.set_editor_property('override_materials',[])
    actor.mesh.set_skeletal_mesh_asset(mesh)
    found=True
assert found;assert levels.save_current_level()
u.EditorAssetLibrary.save_directory(DEST,only_if_is_dirty=True,recursive=True)
assert protected_hashes=={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in protected}, 'Import changed a protected animation or skeleton'
extent=mesh.get_bounds().box_extent
generated_hashes={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in (ROOT/'unreal/WaitingForDawn/Content/Eleanor092').glob('*.uasset')}
report={'mesh':mesh.get_path_name(),'skeleton':skeleton.get_path_name(),'physics_asset':mesh.get_editor_property('physics_asset').get_path_name(),'slots':assigned,'bind_extent_cm':[extent.x,extent.y,extent.z],'fbx_sha256':hashlib.sha256((ART/'SK_EleanorDread.fbx').read_bytes()).hexdigest(),'face_source_sha256':hashlib.sha256((ART/'face_projection.png').read_bytes()).hexdigest(),'preserved_animations':True,'protected_asset_hashes':protected_hashes,'generated_asset_hashes':generated_hashes}
(ART/'unreal-import.json').write_text(json.dumps(report,indent=2)+'\n')
print('ELEANOR_092_IMPORTED',json.dumps(report))
