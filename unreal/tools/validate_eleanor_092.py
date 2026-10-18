"""Read-only inspection of the delivered Blender character; run with Blender."""
import bpy, hashlib, json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
ART=ROOT/'design/eleanor-092'
source=ART/'Eleanor-Mourning-092.blend'
bpy.ops.wm.open_mainfile(filepath=str(source))
rig=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE')
assert len(rig.data.bones)==42
assert [b.name for b in rig.data.bones if b.parent is None]==['DawnRoot']
meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
triangles=0
for mesh in meshes:
    assert any(m.type=='ARMATURE' and m.object==rig for m in mesh.modifiers),mesh.name
    assert all(v.groups for v in mesh.data.vertices), 'Unweighted vertex in '+mesh.name
    mesh.data.calc_loop_triangles();triangles+=len(mesh.data.loop_triangles)
assert triangles==json.loads((ART/'manifest.json').read_text())['triangles']<35000
face=bpy.data.objects['Eleanor_sculpted_face']
face.data.update()
front=[p.normal.y for p in face.data.polygons if p.center.y<-.2]
assert front and sum(front)<0, 'Front face wound inward: would disappear in Unreal'
maps=[i.name for i in bpy.data.images if i.packed_file]
assert all(any(n in name for name in maps) for n in ('face_albedo','cloth_albedo','face_projection'))
report={'passed':True,'scope':'Blender mesh, skinning, outward face normals and packed-image inspection; runtime tests separate',
        'blend_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'triangles':triangles,'bones':len(rig.data.bones),
        'skinned_mesh_objects':len(meshes),'face_outward_normal_sum':sum(front),'packed_images':maps}
(ROOT/'unreal/docs/evidence/blender-character-092.json').write_text(json.dumps(report,indent=2)+'\n')
print('ELEANOR_INSPECTION',json.dumps(report))
