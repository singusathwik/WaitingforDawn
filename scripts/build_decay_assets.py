"""Original, metre-scale Blender furniture. Retains editable parts in the .blend."""
from pathlib import Path
import bpy, math, random, json
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/models/decay';OUT.mkdir(parents=True,exist_ok=True)
SRC=ROOT/'design/repair-083';SRC.mkdir(parents=True,exist_ok=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
random.seed(83)
groups={};current=''
def material(name,color,texture=None,metal=0):
 m=bpy.data.materials.new(name);m.use_nodes=True;m.diffuse_color=(*color,1)
 bs=m.node_tree.nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=(*color,1);bs.inputs['Roughness'].default_value=.92;bs.inputs['Metallic'].default_value=metal
 if texture:
  t=m.node_tree.nodes.new('ShaderNodeTexImage');t.image=bpy.data.images.load(str(ROOT/texture));m.node_tree.links.new(t.outputs['Color'],bs.inputs['Base Color'])
 return m
wood=material('Splintered oak',(.16,.10,.05),'assets/textures/worn-oak.png')
cloth=material('Faded upholstery',(.19,.16,.10),'assets/textures/quatrefoil_jacquard_fabric/diff.jpg')
paper=material('Dusty pages',(.35,.31,.22));leather=material('Book leather',(.09,.055,.035));metal=material('Oxidized iron',(.08,.09,.08),metal=.5);ceramic=material('Old ceramic',(.38,.36,.28))
def keep(o,name,m):
 o.name=name;o.data.materials.append(m);groups[current].append(o);return o
def box(name,p,s,m=wood,bevel=.025):
 bpy.ops.mesh.primitive_cube_add(size=1,location=p);o=bpy.context.object;o.dimensions=s
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 if bevel:
  b=o.modifiers.new('Soft worn edges','BEVEL');b.width=bevel;b.segments=3
  o.modifiers.new('Face normals','WEIGHTED_NORMAL')
 return keep(o,name,m)
def sphere(name,p,s,m):
 bpy.ops.mesh.primitive_uv_sphere_add(segments=20,ring_count=10,location=p);o=bpy.context.object;o.scale=s
 for f in o.data.polygons:f.use_smooth=True
 return keep(o,name,m)
def cylinder(name,a,b,r,m=wood):
 a,b=Vector(a),Vector(b);bpy.ops.mesh.primitive_cylinder_add(vertices=16,radius=r,depth=(b-a).length,location=(a+b)/2);o=bpy.context.object;o.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler();return keep(o,name,m)
def begin(name):
 global current
 current=name;groups[name]=[]
def book(p,angle=0):
 for dz,s,m in [(0,(.28,.39,.035),leather),(.043,(.26,.37,.06),paper),(.085,(.28,.39,.025),leather)]:
  o=box('Scattered volume',(p[0],p[1],p[2]+dz),s,m,.006);o.rotation_euler.z=angle
def fabric(name,p,w,d,zbase,drop):
 verts=[];faces=[];n=20
 for y in range(n+1):
  for x in range(n+1):
   u=(x/n-.5)*w;v=(y/n-.5)*d
   sag=drop*max(0,abs(u)/(w*.5)-.67)**.65+drop*max(0,abs(v)/(d*.5)-.60)**.65
   verts.append((p[0]+u,p[1]+v,p[2]+zbase-sag+.025*math.sin(u*32+v*5)))
 for y in range(n):
  for x in range(n):
   i=y*(n+1)+x;faces.append((i,i+1,i+n+2,i+n+1))
 mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],faces);mesh.update();o=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(o);keep(o,name,cloth)
 sol=o.modifiers.new('Fabric hem thickness','SOLIDIFY');sol.thickness=.008
 for f in mesh.polygons:f.use_smooth=True
begin('sofa')
for x in [-1.05,1.05]:
 for y in [-.37,.37]:cylinder('Turned foot',(x,y,0),(x,y,.27),.075)
box('Upholstered base',(0,0,.34),(2.6,1,.28),cloth,.12)
box('Sloped back',(0,.38,.87),(2.5,.23,.9),cloth,.10).rotation_euler.x=-.13
for x in [-1.25,1.25]:
 sphere('Rolled arm',(x,-.02,.68),(.20,.58,.25),cloth)
 box('Arm support',(x,0,.47),(.24,.93,.45),wood,.10)
for x in [-.79,0,.79]:
 o=box('Sunken seat',(x,-.14,.56),(.77,.77,.23),cloth,.09);o.rotation_euler.y=x*.035
 for z in [.85,1.07]:sphere('Tuft button',(x,.22,z),(.032,.018,.032),leather)
fabric('Abandoned throw',(.65,-.05,.60),1.0,1.35,.10,.38)
begin('dining')
for x in [-.95,.95]:
 for y in [-.48,.48]:
  cylinder('Dining leg',(x,y,0),(x*.95,y*.95,.83),.07)
box('Table apron',(0,0,.72),(2.15,1.10,.18));box('Table top',(0,0,.85),(2.4,1.3,.10),wood,.04)
fabric('Stained linen',(.15,.0,0),2.5,1.7,.92,.55)
for x,y in [(-.65,0),(.6,.2)]:
 sphere('Chipped dinner plate',(x,y,.94),(.25,.25,.025),ceramic)
 cylinder('Cutlery',(x+.29,y-.13,.94),(x+.29,y+.17,.94),.012,metal)
book((.1,.1,.95),.2)
begin('litter')
for i in range(13):
 x=random.uniform(-1.5,1.5);y=random.uniform(-.8,.8)
 if i%3==0:book((x,y,.02),random.uniform(-3,3))
 else:
  o=box('Broken board',(x,y,.025),(.12,random.uniform(.4,.9),.035),wood,.003);o.rotation_euler.z=random.uniform(-3,3)
for i in range(18):
 x,y=random.uniform(-1.4,1.4),random.uniform(-.75,.75)
 bpy.ops.mesh.primitive_circle_add(vertices=3,radius=random.uniform(.07,.18),fill_type='NGON',location=(x,y,.017))
 o=bpy.context.object;o.rotation_euler.z=random.random()*6.28;keep(o,'Broken crockery shard',ceramic)
begin('fallen_chair')
for x in [-.3,.3]:
 for y in [-.3,.3]:cylinder('Chair leg',(x,y,0),(x*.9,y*.9,.5),.035)
box('Seat',(0,0,.52),(.75,.75,.10))
for x in [-.3,.3]:cylinder('Back post',(x,.3,.4),(x,.35,1.25),.035)
for x in [-.16,0,.16]:cylinder('Back spindle',(x,.3,.55),(x,.35,1.18),.018)
box('Curved top rail',(0,.35,1.25),(.72,.09,.13),wood,.05)
# Tip all parts as one coherent assembly, resting on the side rail.
from mathutils import Matrix
R=Matrix.Rotation(math.pi/2,4,'Y')
for o in groups[current]:o.matrix_world=Matrix.Translation((0,0,.37))@R@o.matrix_world
begin('nursery_litter')
for i in range(18):
 x,y=random.uniform(-1.3,1.3),random.uniform(-.7,.7)
 o=box('Wooden alphabet block',(x,y,.08),(.16,.16,.16),wood,.015);o.rotation_euler.z=random.random()*6
for i in range(4):book((random.uniform(-1,1),random.uniform(-.5,.5),.01),random.random()*6)
sphere('Forgotten rag doll head',(.4,.1,.16),(.15,.13,.15),cloth)
box('Rag doll torso',(.4,-.22,.1),(.24,.37,.16),cloth,.06)
for x in [.16,.64]:cylinder('Rag doll limb',(x,-.15,.07),(x,-.5,.07),.05,cloth)
stats={}
for name,objects in groups.items():
 bpy.ops.object.select_all(action='DESELECT')
 copies=[]
 for o in objects:
  c=o.copy();c.data=o.data.copy();bpy.context.collection.objects.link(c);c.select_set(True);copies.append(c)
 bpy.context.view_layer.objects.active=copies[0]
 bpy.ops.object.convert(target='MESH');bpy.ops.object.join();delivery=bpy.context.object;delivery.name=name
 bpy.context.scene.cursor.location=(0,0,0);bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
 bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.uv.cube_project(cube_size=1);bpy.ops.object.mode_set(mode='OBJECT')
 # Runtime binds the already installed shared maps by material name. Do not
 # duplicate the same 2K wood/fabric textures into every exported GLB.
 bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB',use_selection=True,export_image_format='NONE')
 stats[name]={'triangles':sum(len(p.vertices)-2 for p in delivery.data.polygons),'editable_parts':len(objects)}
 bpy.data.objects.remove(delivery,do_unlink=True)
 for o in objects:o.location.x+=list(groups).index(name)*5
bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(SRC/'decay-furniture.blend'))
(SRC/'asset-metrics.json').write_text(json.dumps(stats,indent=2))
print('DECAY_ASSETS',stats)
