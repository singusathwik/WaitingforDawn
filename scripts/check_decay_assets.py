from pathlib import Path
import bpy,json
ROOT=Path(__file__).resolve().parents[1]
source=ROOT/'design/repair-083/decay-furniture.blend'
bpy.ops.wm.open_mainfile(filepath=str(source),load_ui=False,use_scripts=False)
report={'source_parts':len(bpy.data.objects),'modifiers':sum(len(o.modifiers) for o in bpy.data.objects),'packed_images':sum(bool(i.packed_file) for i in bpy.data.images),'exports':{}}
for path in (ROOT/'assets/models/decay').glob('*.glb'):
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
 bpy.ops.import_scene.gltf(filepath=str(path))
 meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
 verts=[o.matrix_world@v.co for o in meshes for v in o.data.vertices]
 size=[max(v[i] for v in verts)-min(v[i] for v in verts) for i in range(3)]
 assert all(s>0 for s in size) and max(size)<6
 report['exports'][path.name]={'meshes':len(meshes),'dimensions_m':size,'triangles':sum(len(p.vertices)-2 for o in meshes for p in o.data.polygons)}
assert report['source_parts']==120 and report['modifiers']>50 and report['packed_images']==2
(ROOT/'design/repair-083/reimport-check.json').write_text(json.dumps(report,indent=2))
print('SOURCE_REOPEN_AND_GLB_REIMPORT_PASS',report)
