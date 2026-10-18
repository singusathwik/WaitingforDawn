"""Blender round-trip dimensions and native source inspection; separate from Unreal tests."""
from pathlib import Path
import bpy, json, math
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'unreal/Staging'
entries=json.loads((OUT/'assets.json').read_text())
checks=[]
for e in entries:
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
    bpy.ops.import_scene.fbx(filepath=str(OUT/e['fbx']))
    objects=[o for o in bpy.context.scene.objects if o.type=='MESH']
    verts=[o.matrix_world@Vector(v) for o in objects for v in o.bound_box]
    dims=[max(v[i] for v in verts)-min(v[i] for v in verts) for i in range(3)]
    expected=e.get('blender_bounds_m')
    status='PASS' if objects else 'FAIL'
    if expected and any(abs(a-b)>.01 for a,b in zip(sorted(dims),sorted(expected))):status='FAIL'
    checks.append(dict(asset=e['name'],mesh_count=len(objects),bounds_m=dims,dimension_check=status,
                       bone_count=sum(len(o.data.bones) for o in bpy.context.scene.objects if o.type=='ARMATURE')))
assert all(c['dimension_check']=='PASS' for c in checks),checks
bpy.ops.wm.open_mainfile(filepath=str(OUT/'interactive-furniture.blend'),load_ui=False,use_scripts=False)
assert {'SM_cupboard_shell','SM_cupboard_leaf','SM_room_door'}.issubset(bpy.data.objects.keys())
for name in ('SM_cupboard_shell','SM_cupboard_leaf','SM_room_door'):
    assert bpy.data.objects[name].data.vertices
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=24
scene.world.color=(.15,.15,.15)
bpy.ops.object.camera_add(location=(4,-7,3.4));camera=bpy.context.object
camera.rotation_euler=(Vector((.7,0,1))-camera.location).to_track_quat('-Z','Y').to_euler()
camera.data.lens=48;scene.camera=camera
for pos,energy,size in [((1,-4,5),700,5),((-3,-1,3),400,3),((3,3,5),800,3)]:
    bpy.ops.object.light_add(type='AREA',location=pos);light=bpy.context.object;light.data.energy=energy;light.data.shape='DISK';light.data.size=size
    light.rotation_euler=(Vector((.5,0,1))-light.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,-.015))
mat=bpy.data.materials.new('Neutral floor');mat.diffuse_color=(.09,.09,.09,1);bpy.context.object.data.materials.append(mat)
scene.render.resolution_x=1280;scene.render.resolution_y=800;scene.render.resolution_percentage=100
scene.render.filepath=str(OUT/'cupboard-inspection.png');bpy.ops.render.render(write_still=True)
(OUT/'roundtrip-audit.json').write_text(json.dumps({'checks':checks,'native_reopen':'PASS','scope':'Blender FBX round trip and native source only'},indent=2))
print('WD_EXPORT_AUDIT_PASS',len(checks))
