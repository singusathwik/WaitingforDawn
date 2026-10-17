"""Author a detailed reusable window surround as an exported mesh module."""
import bpy,math
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1]
bpy.ops.wm.read_factory_settings(use_empty=True)
# Profiled oak architrave, with recessed steps and rounded bead detail.
profile=[(-.08,0),(-.08,.035),(-.065,.05),(-.045,.055),(-.025,.035),(0,.03),(.02,.07),(.035,.085),(.05,.075),(.065,.03),(.08,.02),(.08,0)]
path=[(-1.12,.86),(-1.12,2.87),(-1.06,2.95),(1.06,2.95),(1.12,2.87),(1.12,.86)]
verts=[];faces=[]
for i,(x,z) in enumerate(path):
 prev=Vector(path[max(i-1,0)]);nxt=Vector(path[min(i+1,len(path)-1)])
 tangent=(nxt-prev).normalized();normal=Vector((-tangent.y,tangent.x))
 for offset,depth in profile:verts.append((x+normal.x*offset,-depth,z+normal.y*offset))
N=len(profile)
for i in range(len(path)-1):
 for j in range(N-1):a=i*N+j;faces.append((a,a+1,a+N+1,a+N))
mesh=bpy.data.meshes.new('Carved window casing');mesh.from_pydata(verts,[],faces);mesh.update()
o=bpy.data.objects.new('Carved oak casing',mesh);bpy.context.collection.objects.link(o)
for poly in mesh.polygons:poly.use_smooth=True
# Bevelled sill and sash joinery have real depth and softer silhouette.
def piece(name,loc,size,bevel=.018):
 bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.name=name;o.dimensions=size
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 mod=o.modifiers.new('Worn edge bevel','BEVEL');mod.width=bevel;mod.segments=3
 o.modifiers.new('Weighted normals','WEIGHTED_NORMAL')
for x in [-1.02,0,1.02]:piece('Sash stile',(x,-.025,1.94),(.065,.12,1.95))
for z in [.96,1.94,2.91]:piece('Sash rail',(0,-.025,z),(2.1,.12,.065))
piece('Deep moulded sill',(0,-.06,.84),(2.5,.38,.13),.025)
piece('Apron',(0,.015,.71),(2.18,.12,.16))
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.convert(target='MESH')
bpy.ops.object.join()
bpy.context.object.name='Victorian window surround'
# Dense pleated hanging cloth, distinct UV-mapped meshes for subtle runtime sway.
for side in [-1,1]:
 verts=[];faces=[];cols=24;rows=32
 for j in range(rows):
  t=j/(rows-1)
  for i in range(cols):
   u=i/(cols-1)
   x=side*(1.12+u*.44)+(math.sin(t*math.pi)*.06*side)
   depth=-.16-math.sin(u*math.pi*10)*(.035+.055*t)
   z=3.14-t*2.54+math.sin(u*math.pi*10)*.025*t
   verts.append((x,depth,z))
 for j in range(rows-1):
  for i in range(cols-1):
   a=j*cols+i;faces.append((a,a+1,a+cols+1,a+cols))
 mesh=bpy.data.meshes.new('Pleated cloth');mesh.from_pydata(verts,[],faces);mesh.update()
 obj=bpy.data.objects.new('Curtain'+str(side),mesh);bpy.context.collection.objects.link(obj)
 for poly in mesh.polygons:poly.use_smooth=True
bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets/models/architecture.glb'),export_format='GLB',export_animations=False,export_yup=True)
print('Architecture module exported')
