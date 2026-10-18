"""Extract real approved nursery furniture into editable, independently placeable FBX assets."""
import bpy,json,hashlib
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'unreal/Staging'
source=ROOT/'design/rooms/eleanors-nursery/nursery-form.blend'
bpy.ops.wm.open_mainfile(filepath=str(source),load_ui=False,use_scripts=False)
records=json.loads((OUT/'assets.json').read_text())
records=[r for r in records if r['name'] not in {'cradle','armchair','keeper'}]
for name,prefix in [('cradle','Cradle'),('armchair','ArmChair_01'),('keeper','Keeper__')]:
    bpy.ops.object.select_all(action='DESELECT')
    objects=[o for o in bpy.context.scene.objects if o.type in {'MESH','CURVE'} and (o.name==prefix if name=='armchair' else o.name.startswith(prefix))]
    assert objects
    for o in objects:o.select_set(True)
    bpy.context.view_layer.objects.active=objects[0]
    bpy.ops.object.convert(target='MESH');bpy.ops.object.join();o=bpy.context.object
    vertices=[o.matrix_world@Vector(v) for v in o.bound_box]
    origin=Vector(((min(v.x for v in vertices)+max(v.x for v in vertices))/2,(min(v.y for v in vertices)+max(v.y for v in vertices))/2,min(v.z for v in vertices)))
    bpy.context.scene.cursor.location=origin;bpy.ops.object.origin_set(type='ORIGIN_CURSOR');o.location=(0,0,0)
    bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
    bpy.context.scene.unit_settings.system='METRIC';bpy.context.scene.unit_settings.scale_length=1
    target=OUT/f'SM_{name}.fbx';o.name='SM_'+name;o.data.calc_loop_triangles()
    bpy.ops.export_scene.fbx(filepath=str(target),use_selection=True,object_types={'MESH'},apply_unit_scale=True,apply_scale_options='FBX_SCALE_UNITS',axis_forward='-Y',axis_up='Z',bake_anim=False,path_mode='COPY',embed_textures=True)
    records.append(dict(name=name,source=source.relative_to(ROOT).as_posix(),source_sha256=hashlib.sha256(source.read_bytes()).hexdigest(),fbx=target.name,sha256=hashlib.sha256(target.read_bytes()).hexdigest(),triangles=len(o.data.loop_triangles),blender_bounds_m=list(o.dimensions)))
(OUT/'assets.json').write_text(json.dumps(records,indent=2))
print('NURSERY_PROPS_EXPORTED',len(records))
