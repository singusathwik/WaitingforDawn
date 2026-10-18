"""Run in Blender: convert existing credited models into independent FBX imports.
Produces real meshes, not .uasset placeholders. Engine imports must still be validated.
"""
from pathlib import Path
import bpy, json, hashlib, math
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'unreal/Staging'; OUT.mkdir(parents=True,exist_ok=True)
SOURCES={
    **{n:f'assets/models/decay/{n}.glb' for n in ('sofa','dining','fallen_chair','litter','nursery_litter')},
    **{n:f'assets/models/repair/{n}.glb' for n in ('bed','shelf','radiator','key')},
}
records=[]
for name,rel in SOURCES.items():
    bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
    bpy.ops.import_scene.gltf(filepath=str(ROOT/rel))
    meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
    for o in meshes:
        o.select_set(True)
    for o in bpy.context.selected_objects:
        if o.type!='MESH': o.select_set(False)
    bpy.context.view_layer.objects.active=meshes[0]
    bpy.ops.object.join()
    obj=bpy.context.object; obj.name='SM_'+name
    bpy.context.scene.cursor.location=(0,0,0)
    bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
    bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
    # Source Blender geometry uses metres; FBX unit metadata performs the centimetre conversion.
    bpy.context.scene.unit_settings.system='METRIC'; bpy.context.scene.unit_settings.scale_length=1.0
    obj.data.calc_loop_triangles()
    target=OUT/f'SM_{name}.fbx'
    bpy.ops.export_scene.fbx(filepath=str(target),use_selection=True,object_types={'MESH'},
        apply_unit_scale=True,apply_scale_options='FBX_SCALE_UNITS',axis_forward='-Y',axis_up='Z',
        bake_anim=False,add_leaf_bones=False,path_mode='COPY',embed_textures=True,use_mesh_modifiers=True)
    records.append(dict(name=name,source=rel,source_sha256=hashlib.sha256((ROOT/rel).read_bytes()).hexdigest(),
        fbx=target.name,sha256=hashlib.sha256(target.read_bytes()).hexdigest(),
        triangles=len(obj.data.loop_triangles),blender_bounds_m=list(obj.dimensions)))
# Purpose-built hollow cupboard and a separate leaf: human-scale, clear front and hinge.
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
wood=bpy.data.materials.new('WornOak');wood.diffuse_color=(.12,.065,.025,1);wood.use_nodes=True
wood.node_tree.nodes['Principled BSDF'].inputs['Roughness'].default_value=.92
texture=wood.node_tree.nodes.new('ShaderNodeTexImage')
texture.image=bpy.data.images.load(str(ROOT/'assets/textures/worn-oak.png'))
wood.node_tree.links.new(texture.outputs['Color'],wood.node_tree.nodes['Principled BSDF'].inputs['Base Color'])
def cube(name,centre,size):
    bpy.ops.mesh.primitive_cube_add(size=1,location=centre);o=bpy.context.object;o.name=name;o.dimensions=size
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    o.data.materials.append(wood)
    bevel=o.modifiers.new('Worn edges','BEVEL');bevel.width=.012;bevel.segments=2
    bpy.ops.object.modifier_apply(modifier=bevel.name)
    return o
def export_group(name,objects):
    bpy.ops.object.select_all(action='DESELECT')
    for o in objects:o.select_set(True)
    bpy.context.view_layer.objects.active=objects[0];bpy.ops.object.join();o=bpy.context.object;o.name='SM_'+name
    bpy.context.scene.cursor.location=(0,0,0);bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
    o.data.calc_loop_triangles();target=OUT/f'SM_{name}.fbx'
    bpy.ops.export_scene.fbx(filepath=str(target),use_selection=True,object_types={'MESH'},apply_unit_scale=True,
        apply_scale_options='FBX_SCALE_UNITS',axis_forward='-Y',axis_up='Z',bake_anim=False,add_leaf_bones=False,
        path_mode='COPY',embed_textures=True)
    records.append(dict(name=name,source='original Blender geometry in unreal/tools/prepare_assets.py',
        fbx=target.name,sha256=hashlib.sha256(target.read_bytes()).hexdigest(),triangles=len(o.data.loop_triangles),blender_bounds_m=list(o.dimensions)))
shell=[]
for x in (-.48,.48):shell.append(cube('Side',(x,0,1.0),(.06,.58,2)))
shell.append(cube('Back',(0,.27,1),(.96,.04,2)))
for z in (.06,.70,1.35,1.96):shell.append(cube('Shelf',(0,0,z),(.96,.58,.06)))
export_group('cupboard_shell',shell)
leaf=[cube('Leaf',(.47,0,1),(.94,.06,1.88))]
for x in (.06,.88):leaf.append(cube('Stile',(x,-.045,1),(.065,.04,1.8)))
for z in (.15,1,1.85):leaf.append(cube('Rail',(.47,-.045,z),(.85,.04,.07)))
leaf.append(cube('Handle',(.82,-.09,.98),(.035,.08,.20)))
export_group('cupboard_leaf',leaf)
door=[cube('Door panel',(.55,0,1.19),(1.1,.06,2.38))]
for x in (.06,1.04):door.append(cube('Door stile',(x,-.045,1.19),(.08,.03,2.28)))
for z in (.12,1.05,2.26):door.append(cube('Door rail',(.55,-.045,z),(1.0,.03,.08)))
door.append(cube('Brass handle',(.98,-.11,1.05),(.13,.07,.035)))
export_group('room_door',door)
# Save a readable assembly, with door pivots intact; each FBX above remains at its own origin.
bpy.data.objects['SM_cupboard_leaf'].location=(-.47,-.32,0)
bpy.data.objects['SM_cupboard_leaf'].rotation_euler.z=math.radians(-100)
bpy.data.objects['SM_room_door'].location=(2,0,0)
bpy.ops.file.pack_all()
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'interactive-furniture.blend'))
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=str(ROOT/'assets/models/mourning_ghost.glb'))
bpy.ops.object.select_all(action='SELECT')
vertices=[o.matrix_world@Vector(v) for o in bpy.context.scene.objects if o.type=='MESH' for v in o.bound_box]
ghost_min_z=min(v.z for v in vertices)
ghost_height=max(v.z for v in vertices)-ghost_min_z
target=OUT/'SK_mourning_ghost.fbx'
bpy.ops.export_scene.fbx(filepath=str(target),use_selection=True,object_types={'MESH','ARMATURE'},
    apply_unit_scale=True,apply_scale_options='FBX_SCALE_UNITS',axis_forward='-Y',axis_up='Z',
    bake_anim=True,bake_anim_use_all_actions=True,bake_anim_use_nla_strips=True,add_leaf_bones=False,
    path_mode='COPY',embed_textures=True)
records.append(dict(name='mourning_ghost',source='assets/models/mourning_ghost.glb',
    source_sha256=hashlib.sha256((ROOT/'assets/models/mourning_ghost.glb').read_bytes()).hexdigest(),
    fbx=target.name,sha256=hashlib.sha256(target.read_bytes()).hexdigest(),skeletal=True,
    source_min_z_m=ghost_min_z,source_height_m=ghost_height,target_height_cm=235,
    attribution='Thin Zombie by Rosswet Mobile, submitted by dogchicken; adapted veil and skirt; CC BY 3.0; see ASSETS.md'))
(OUT/'assets.json').write_text(json.dumps(records,indent=2),encoding='utf-8')
print('WD_ASSETS_READY',len(records),sum(r.get('triangles',0) for r in records))
