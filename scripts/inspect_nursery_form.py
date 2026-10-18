"""Read-only Form-stage geometric evidence; never grants human approval."""
from pathlib import Path
import bpy,bmesh,json,math
from mathutils import Vector
from mathutils.bvhtree import BVHTree
from bpy_extras.object_utils import world_to_camera_view

ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'design/rooms/eleanors-nursery'
scene=bpy.context.scene;deps=bpy.context.evaluated_depsgraph_get()
def points(objects):
    result=[]
    for o in objects:
        if o.type not in {'MESH','CURVE'}:continue
        ev=o.evaluated_get(deps);me=ev.to_mesh()
        result += [o.matrix_world@v.co for v in me.vertices]
        ev.to_mesh_clear()
    return result
def bounds(objects):
    ps=points(objects)
    return [[min(p[i] for p in ps) for i in range(3)],[max(p[i] for p in ps) for i in range(3)]]
def pref(name):return [o for o in bpy.data.objects if o.name.startswith(name)]
names=['Cradle','Wardrobe','Nursery dresser','Toy drawers','Preserved bed','Preserved under-bed search box','ClassicConsole_01','ArmChair_01','Keeper__']
contacts=[]
for name in names:
    bb=bounds(pref(name));bottom=bb[0][2]
    contacts.append(dict(group=name,bounds=bb,floorContactMeters=round(bottom,5),result='PASS' if -.005<=bottom<=.005 else 'FAIL'))
def tree(objects):
    vertices=[];faces=[]
    for o in objects:
        if o.type not in {'MESH','CURVE'}:continue
        ev=o.evaluated_get(deps);me=ev.to_mesh();me.calc_loop_triangles();offset=len(vertices)
        vertices.extend(o.matrix_world@v.co for v in me.vertices)
        faces.extend(tuple(offset+i for i in f.vertices) for f in me.loop_triangles)
        ev.to_mesh_clear()
    return BVHTree.FromPolygons(vertices,faces,all_triangles=True)
trees={name:tree(pref(name)) for name in names[:-1]}
intersections=[]
for i,a in enumerate(trees):
    for b in list(trees)[i+1:]:
        count=len(trees[a].overlap(trees[b]));intersections.append(dict(a=a,b=b,intersectingFacePairs=count,result='PASS' if count==0 else 'FAIL'))
shell=[]
for o in bpy.data.collections['Shell'].objects:
    if o.type!='MESH':continue
    bm=bmesh.new();bm.from_mesh(o.data);bad=sum(not e.is_manifold for e in bm.edges);bm.free()
    shell.append(dict(id=o.name,nonManifoldEdges=bad,result='PASS' if bad==0 else 'FAIL'))
apertures=[]
for op in json.loads((OUT/'openings.json').read_text())['openings']:
    obj=bpy.data.objects[op['wallId']];bvh=BVHTree.FromObject(obj,deps);inv=obj.matrix_world.inverted()
    normal=Vector((1,0,0) if op['cutterDimensions'][0]<op['cutterDimensions'][1] else (0,1,0));tangent=Vector((0,1,0) if normal.x else (1,0,0))
    blocked=0
    for x in [-.4,0,.4]:
        for y in [-.4,0,.4]:
            p=Vector(op['location'])+x*op['widthMeters']*tangent+Vector((0,0,y*op['heightMeters']))
            blocked+=int(bvh.ray_cast(inv@(p-normal),inv.to_3x3()@normal,2)[0] is not None)
    apertures.append(dict(id=op['id'],rays=9,blocked=blocked,result='PASS' if not blocked else 'FAIL'))
    if op['kind']=='door':
        combined=tree([obj]+[o for o in bpy.data.objects if o.name.startswith(op['wallId']+' trim')])
        blocked=0
        for x in [-.3,0,.3]:
            for height in [.08,.25,.9,1.65]:
                p=Vector(op['location'])+x*op['widthMeters']*tangent;p.z=height
                blocked+=int(combined.ray_cast(p-normal,normal,2)[0] is not None)
        apertures.append(dict(id=op['id']+'-with-trim',rays=12,blocked=blocked,result='PASS' if not blocked else 'FAIL'))
roses=[]
for o in pref('Ceiling rose'):
    bb=bounds([o]);x=(bb[0][0]+bb[1][0])/2;y=(bb[0][1]+bb[1][1])/2
    support=3.32 if abs(x)<.01 and abs(y)<.01 else 3.6
    distance=bb[1][2]-support
    roses.append(dict(id=o.name,ceilingOrBeamUnderside=support,top=bb[1][2],contactError=distance,result='PASS' if abs(distance)<=.005 else 'FAIL'))
used_images={node.image for mat in bpy.data.materials if mat.users and mat.use_nodes for node in mat.node_tree.nodes if node.type=='TEX_IMAGE' and node.image}
images=[dict(name=i.name,resolution=list(i.size),packed=bool(i.packed_file),result='PASS' if i.size[0]>0 and i.packed_file else 'FAIL') for i in used_images]
triangles=0
for o in bpy.data.objects:
    if o.type not in {'MESH','CURVE'}:continue
    ev=o.evaluated_get(deps);me=ev.to_mesh();me.calc_loop_triangles();triangles+=len(me.loop_triangles);ev.to_mesh_clear()
hero=[world_to_camera_view(scene,scene.camera,p) for p in points(pref('Cradle'))]
hero_frame=dict(minX=min(p.x for p in hero),maxX=max(p.x for p in hero),minY=min(p.y for p in hero),maxY=max(p.y for p in hero))
hero_frame['result']='PASS' if all(.04<v<.96 for v in hero_frame.values() if isinstance(v,(float,int))) else 'FAIL'
bed=bounds(pref('Preserved bed'));toy=bounds(pref('Toy drawers'));gap=toy[0][0]-bed[1][0]
report=dict(stage='FORM evidence; no runtime claims',functionHumanApproval='approved',formHumanApproval='pending',nativeFileReopened=True,triangles=triangles,triangleBudget=250000,contacts=contacts,shell=shell,apertures=apertures,ceilingMounts=roses,usedImages=images,productionHeroFrame=hero_frame,bedToDresserGapMeters=gap,ceilingAndCornerViews='11 review renders scheduled; verify image files separately',runtimeLightingParity='NOT_CHECKED',collisionNavigation='NOT_CHECKED',textureBakeAndGLBReimport='NOT_CHECKED')
report['technicalPreflight']='PASS' if triangles<250000 and gap>=.049 and hero_frame['result']=='PASS' and all(c['result']=='PASS' for c in contacts+shell+apertures+roses+images) else 'FAIL'
report['formHumanApproval']=json.loads((OUT/'milestone-reviews.json').read_text())['form']['status']
report['independentPropIntersections']=intersections
if any(c['result']=='FAIL' for c in intersections):report['technicalPreflight']='FAIL'
assemblies=[]
for name in ['Drawer_'+str(i) for i in range(12)]+['Wardrobe_leaf_left','Wardrobe_leaf_right']:
    obj=bpy.data.objects.get(name)
    children=list(obj.children) if obj else []
    assemblies.append(dict(name=name,childCount=len(children),result='PASS' if children else 'FAIL'))
report['animationAssemblies']=assemblies
if any(c['result']=='FAIL' for c in assemblies):report['technicalPreflight']='FAIL'
(OUT/'form-preflight.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print('FORM_PREFLIGHT',report['technicalPreflight'],'triangles',triangles)
for c in contacts+shell+apertures+roses+images+intersections:
    if c['result']=='FAIL':print('FAIL',c)
if report['technicalPreflight']!='PASS':
    print('HERO',hero_frame,'GAP',gap)
    raise RuntimeError('Native Form preflight failed; inspect form-preflight.json')
