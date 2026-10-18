"""Read-only geometry preflight for the saved concept, not a runtime certificate."""
import bpy
import bmesh
import json
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'design/rooms/eleanors-nursery'
scene=bpy.context.scene
deps=bpy.context.evaluated_depsgraph_get()
schedule=json.loads((OUT/'openings.json').read_text())
checks=[]
for op in schedule['openings']:
    obj=bpy.data.objects[op['wallId']]
    bvh=BVHTree.FromObject(obj,deps)
    inv=obj.matrix_world.inverted()
    normal=Vector((1,0,0) if op['cutterDimensions'][0]<op['cutterDimensions'][1] else (0,1,0))
    tangent=Vector((0,1,0) if normal.x else (1,0,0))
    tested=0;blocked=0
    for frac in [-.4,0,.4]:
        for h in [-.4,0,.4]:
            point=Vector(op['location'])+tangent*(frac*op['widthMeters'])+Vector((0,0,h*op['heightMeters']))
            hit=bvh.ray_cast(inv@(point-normal),inv.to_3x3()@normal,2)[0]
            tested+=1;blocked+=int(hit is not None)
    checks.append({'opening':op['id'],'rays':tested,'blocked':blocked,'result':'PASS' if not blocked else 'FAIL'})
shell=[]
for obj in bpy.data.collections['Shell'].objects:
    if obj.type!='MESH':continue
    bm=bmesh.new();bm.from_mesh(obj.data)
    count=sum(not e.is_manifold for e in bm.edges);bm.free()
    shell.append({'object':obj.name,'nonManifoldEdges':count})

def bounds(prefix):
    points=[o.matrix_world@Vector(c) for o in bpy.data.objects if o.type=='MESH' and o.name.startswith(prefix) for c in o.bound_box]
    return [[min(v[i] for v in points) for i in range(3)],[max(v[i] for v in points) for i in range(3)]]
bed=bounds('Preserved bed');dresser=bounds('Toy drawers')
gap=dresser[0][0]-bed[1][0]
report={'stage':'Function-stage concept preflight only','fileReopened':True,'openingApertures':checks,'shellMeshes':shell,'bedToDresserGapMeters':round(gap,4),'bedToDresser':'PASS' if gap>=.05 else 'FAIL','shaderMaterials':'Neutral clay; final PBR not authored','functionApproval':'PENDING','formApproval':'NOT_STARTED','runtimePerformance':'NOT_CHECKED','runtimeCollisionNavigation':'NOT_CHECKED','mobileScreenshots':'NOT_CHECKED','paidMeshyRequests':0}
report['technicalPreflight']='PASS' if all(c['result']=='PASS' for c in checks) and all(c['nonManifoldEdges']==0 for c in shell) and gap>=.05 else 'FAIL'
(OUT/'geometry-preflight.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print(json.dumps(report))
if report['technicalPreflight']!='PASS':raise RuntimeError('Concept geometry preflight failed')
