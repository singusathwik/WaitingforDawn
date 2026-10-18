"""Editable Blender source and actual glTF assets for the 0.8.2 repair."""
from pathlib import Path
import bpy, math, json
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/models/repair';OUT.mkdir(parents=True,exist_ok=True)
SRC=ROOT/'design/repair-082';SRC.mkdir(parents=True,exist_ok=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
def mat(name,color,metal=0,rough=.8):
 m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True
 p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1);p.inputs['Metallic'].default_value=metal;p.inputs['Roughness'].default_value=rough
 return m
wood=mat('Worn oak',(.18,.095,.04));cloth=mat('Old textile',(.23,.2,.15));iron=mat('Blackened iron',(.045,.048,.045),.65);brass=mat('Tarnished brass',(.3,.22,.1),.8);paint=mat('Faded green enamel',(.12,.19,.16),.6,.4);glass=mat('Dusty glass',(.055,.085,.095),.35,.22);rubber=mat('Rubber',(.016,.018,.017));porcelain=mat('Stained porcelain',(.46,.45,.36),0,.32);paper=mat('Old papers',(.33,.29,.2))
groups={};current=''
def finish(o,name,m):
 o.name=name;o.data.materials.append(m);groups[current].append(o)
 return o
def cube(name,p,s,m=wood,bevel=.015):
 bpy.ops.mesh.primitive_cube_add(size=1,location=p);o=bpy.context.object;o.dimensions=s
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 if bevel:
  b=o.modifiers.new('Rounded worn edges','BEVEL');b.width=bevel;b.segments=2
  bpy.ops.object.modifier_apply(modifier=b.name)
  n=o.modifiers.new('Weighted face normals','WEIGHTED_NORMAL');bpy.ops.object.modifier_apply(modifier=n.name)
 return finish(o,name,m)
def cyl(name,p,r,d,m=iron,axis='Z',vertices=20):
 bpy.ops.mesh.primitive_cylinder_add(vertices=vertices,radius=r,depth=d,location=p);o=bpy.context.object
 if axis=='X':o.rotation_euler.y=math.pi/2
 if axis=='Y':o.rotation_euler.x=math.pi/2
 for f in o.data.polygons:f.use_smooth=True
 return finish(o,name,m)
def torus(name,p,major,minor,m=brass,axis='Z'):
 bpy.ops.mesh.primitive_torus_add(major_radius=major,minor_radius=minor,major_segments=24,minor_segments=8,location=p);o=bpy.context.object
 if axis=='X':o.rotation_euler.y=math.pi/2
 if axis=='Y':o.rotation_euler.x=math.pi/2
 return finish(o,name,m)
def begin(name):
 global current
 current=name;groups[name]=[]
def panels(width,height,depth,z=0):
 for x in [-width/2,width/2]:cube('Side stile',(x,0,z+height/2),(.07,depth,height))
 for y in [-depth/2,depth/2]:cube('End panel',(0,y,z+height/2),(width,.055,height))
 cube('Tray bottom',(0,0,z+.025),(width,depth,.05))
begin('drawer')
panels(1,.58,.75,-.29)
for x in [-.39,.39]:cube('Raised front stile',(x,-.405,0),(.05,.035,.46))
for z in [-.21,.21]:cube('Raised front rail',(0,-.405,z),(.8,.035,.05))
for x in [-.14,.14]:cyl('Handle mounts',(x,-.45,0),.035,.06,brass,'Y')
cyl('Drawer pull',(0,-.49,0),.025,.28,brass,'X')
begin('dresser')
for x in [-1.72,1.72]:cube('Solid side',(x,.18,.85),(.12,1.1,1.7))
cube('Cabinet back',(0,.7,.85),(3.5,.07,1.7))
for z in [.12,.8,1.5,1.68]:cube('Frame rail',(0,.16,z),(3.55,1.14,.09))
for x in [-.55,.55]:cube('Drawer partitions',(x,.18,.8),(.07,1,1.5))
for x in [-1.55,1.55]:
 for y in [-.3,.6]:cyl('Turned foot',(x,y,.1),.09,.2,wood)
cube('Cornice top',(0,.16,1.77),(3.72,1.25,.10))
begin('door')
cube('Door leaf',(1.35,0,1.65),(2.7,.12,3.3))
for x in [.13,2.57]:cube('Door stile',(x,-.09,1.65),(.13,.07,3.17))
for z in [.18,1.16,2.1,3.12]:cube('Door rail',(1.35,-.09,z),(2.5,.07,.12))
for z in [.65,1.65,2.65]:cube('Recessed field',(1.35,-.075,z),(2.2,.045,.75))
for y in [-.14,.14]:
 cube('Handle plate',(2.38,y,1.3),(.15,.025,.4),brass)
 cyl('Door handle',(2.25,y*1.5,1.4),.035,.35,brass,'X')
 cyl('Keyhole',(2.38,y*1.12,1.2),.034,.012,iron,'Y')
begin('bed')
for x in [-.85,.85]:
 for y in [-1.3,1.3]:cyl('Bed post',(x,y,.58),.075,1.16,wood)
cube('Bed rails',(0,0,.70),(1.9,2.85,.12))
cube('Tufted mattress',(0,0,.94),(1.8,2.7,.33),cloth,.12)
cube('Pillow',(0,.93,1.16),(1.2,.5,.20),porcelain,.09)
cube('Headboard',(0,1.4,1.15),(1.95,.12,1.35),wood,.05)
for x in [-.65,0,.65]:cube('Headboard panel',(x,1.32,1.3),(.53,.04,.7),wood)
for i in range(12):cube('Blanket folds',((i-5.5)*.147,-.45,1.12+abs(math.sin(i))* .012),(.16,1.65,.045),cloth,.02)
begin('car')
# A continuous shaped body, with bonnet, boot, roof pillars and separate glazing.
sections=[(-2.55,.80,.45,.78),(-2.3,.94,.35,.93),(-1.5,.96,.34,1.0),(-.65,.93,.36,1.0),(.8,.94,.36,1.04),(2.1,.9,.4,.95),(2.4,.78,.48,.82)]
verts=[]
for y,w,b,t in sections:verts.extend([(-w*.88,y,b),(-w,y,t-.12),(-w*.88,y,t),(w*.88,y,t),(w,y,t-.12),(w*.88,y,b)])
faces=[]
for i in range(len(sections)-1):
 for j in range(6):faces.append((i*6+j,i*6+(j+1)%6,(i+1)*6+(j+1)%6,(i+1)*6+j))
faces += [tuple(range(5,-1,-1)),tuple((len(sections)-1)*6+j for j in range(6))]
mesh=bpy.data.meshes.new('Welded car body');mesh.from_pydata(verts,[],faces);mesh.update();o=bpy.data.objects.new('Car shaped body',mesh);bpy.context.collection.objects.link(o);finish(o,o.name,paint)
# Sloping windshield and trapezoid side glass; a separate cabin provides real depth.
def quad(name,points,m):
 mesh=bpy.data.meshes.new(name);mesh.from_pydata(points,[],[tuple(range(len(points)))]);mesh.update()
 o=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(o);return finish(o,name,m)
def bar(name,a,b,r,m):
 o=cyl(name,(Vector(a)+Vector(b))/2,r,(Vector(b)-Vector(a)).length,m)
 o.rotation_euler=(Vector(b)-Vector(a)).to_track_quat('Z','Y').to_euler();return o
cube('Roof',(0,.28,1.64),(1.5,1.9,.10),paint,.09)
for x in [-1,1]:
 for bottom,top in [((x*.88,-1.23,1.02),(x*.72,-.64,1.59)),((x*.88,.30,1.02),(x*.72,.30,1.59)),((x*.88,1.53,1.02),(x*.72,1.2,1.59))]:bar('Pillar',bottom,top,.035,paint)
 quad('Front side glass',[(x*.884,-1.18,1.04),(x*.884,.24,1.04),(x*.725,.24,1.58),(x*.725,-.62,1.58)],glass)
 quad('Rear side glass',[(x*.884,.36,1.04),(x*.884,1.49,1.04),(x*.725,1.18,1.58),(x*.725,.36,1.58)],glass)
 for y in [-.47,.9]:
  cube('Door seam',(x*.947,y,.78),(.012,1.18,.40),iron,.005)
  cube('Door panel',(x*.956,y,.78),(.022,1.15,.37),paint,.02)
  cube('Chrome handle',(x*.976,y+.3,.98),(.035,.19,.04),brass)
quad('Windshield',[(-.87,-1.23,1.03),(.87,-1.23,1.03),(.71,-.65,1.60),(-.71,-.65,1.60)],glass)
quad('Rear windscreen',[(-.71,1.21,1.60),(.71,1.21,1.60),(.87,1.54,1.03),(-.87,1.54,1.03)],glass)
for x in [-.42,.42]:
 cube('Seat cushion',(x,.13,.78),(.62,.63,.20),rubber,.07)
 seat=cube('Seat back',(x,.43,1.07),(.64,.20,.67),rubber,.07);seat.rotation_euler.x=-.13
cube('Dashboard',(0,-.88,1.04),(1.55,.33,.19),rubber,.04)
torus('Steering wheel',(.43,-.55,1.12),.17,.023,iron,'Y')
for x in [-.4,.4]:bar('Wiper',(x,-1.26,1.06),(x+.3,-1.02,1.28),.009,iron)
for x in [-.95,.95]:
 for y in [-1.65,1.6]:
  cyl('Tire',(x,y,.44),.44,.24,rubber,'X',32)
  cyl('Steel wheel',(x*1.14,y,.44),.27,.035,iron,'X',24)
  torus('Rim',(x*1.16,y,.44),.24,.025,brass,'X')
  cyl('Hub',(x*1.18,y,.44),.08,.035,brass,'X')
  for i in range(5):
   angle=i*math.tau/5
   cyl('Wheel bolt',(x*1.19,y+math.sin(angle)*.12,.44+math.cos(angle)*.12),.021,.03,brass,'X',8)
for y in [-2.47,2.36]:
 cube('Bumper',(0,y,.53),(1.72,.12,.13),iron)
 cube('Number plate',(0,y*1.025,.66),(.5,.02,.13),porcelain)
 for x in [-.63,.63]:cube('Lamp lens',(x,y,.81),(.37,.055,.17),porcelain if y<0 else brass,.025)
for i in range(7):cube('Grille bar',((i-3)*.12,-2.52,.79),(.055,.025,.15),iron)
for x in [-.98,.98]:cube('Mirror',(x,-.85,1.23),(.19,.24,.12),paint,.04)
begin('radiator')
for i in range(12):
 x=(i-5.5)*.095
 cube('Cast iron fin',(x,0,.52),(.07,.22,.92),iron,.03)
for z in [.12,.88]:cyl('Connecting pipe',(0,0,z),.035,1.24,iron,'X')
begin('shelf')
for x in [-.8,.8]:cube('Shelf side',(x,0,1.2),(.08,.42,2.4))
cube('Shelf back',(0,.21,1.2),(1.6,.06,2.4))
for z in [.1,.65,1.2,1.75,2.38]:cube('Shelf',(0,0,z),(1.65,.48,.07))
for row in range(4):
 for i in range(10):
  h=.25+.16*abs(math.sin(i*8+row)); book=cube('Old book',((i-4.5)*.145,0,.15+row*.55+h/2),(.1,.3,h),cloth if i%3 else paper,.005);book.rotation_euler.y=.07*math.sin(i)
begin('kitchen')
# Open sink and stove appliance; searchable cabinets remain independent.
cube('Stove',(0,0,.57),(1.5,1.25,1.14),iron,.05)
cube('Oven door',(0,-.65,.55),(1.23,.08,.77),paint,.04)
cube('Oven window',(0,-.70,.55),(.94,.02,.48),glass)
cyl('Oven handle',(0,-.78,.96),.03,.95,brass,'X')
for x in [-.38,.38]:
 for y in [-.33,.33]:torus('Burner',(x,y,1.16),.19,.035,iron)
for x in [-.5,-.17,.17,.5]:cyl('Control knob',(x,-.68,1.07),.055,.05,brass,'Y')
begin('debris')
for i in range(9):
 o=cube('Fallen papers',(.6*math.sin(i*9),.55*math.cos(i*5),.01+i*.004),(.27,.36,.008),paper,0);o.rotation_euler.z=i
for i in range(4):
 o=cube('Broken plaster',(.6*math.sin(i*7),.5*math.cos(i*9),.025),(.18,.24,.05),porcelain,.01);o.rotation_euler.z=i*2
begin('key')
torus('Key bow',(0,0,.01),.07,.014,brass)
cube('Key shaft',(0,-.13,.01),(.025,.16,.025),brass,.004)
for y in [-.18,-.21]:cube('Key tooth',(.025,y,.01),(.055,.018,.025),brass,.003)
begin('wardrobe_case')
for x in [-.83,.83]:cube('Side panel',(x,0,1.15),(.12,1.5,2.3))
cube('Back panel',(0,.72,1.15),(1.7,.10,2.3))
for z in [.06,2.3]:cube('Cornice',(0,0,z),(1.85,1.6,.12))
for x in [-.84,.84]:
 for y in [-.73,.73]:cyl('Carved post',(x,y,1.19),.075,2.35,wood)
cube('Crown',(0,0,2.42),(1.97,1.72,.12))
begin('wardrobe_leaf')
# Local hinge at left bottom. Eye slit has real empty geometry.
for z,h in [(.73,1.46),(1.93,.74)]:cube('Door field',(.8,0,z),(1.6,.09,h))
for x in [.06,1.54]:cube('Slit end',(x,0,1.51),(.12,.09,.10))
for x in [.11,1.49]:
 for z in [.65,1.97]:cube('Frame moulding',(x,-.065,z),(.055,.05,.98))
for z in [.19,1.12,1.72,2.20]:cube('Frame cross rail',(.8,-.065,z),(1.4,.05,.05))
for z in [.3,1.8]:cyl('Hinge',(.02,-.06,z),.04,.18,iron)
cube('Handle plate',(1.39,-.1,1.05),(.15,.025,.3),brass)
bar('Handle',(1.39,-.16,.96),(1.39,-.16,1.15),.025,brass)
begin('facade')
plaster=mat('Exterior masonry',(.22,.23,.2));slate=mat('Roof slate',(.08,.10,.11))
# Front and rear enclosing walls, pilasters and cornices. Thin faces stay outside collision shell.
for y in [-2.1,20.1]:
 cube('Exterior wall',(24,-y,7 if y<0 else 9),(51,.22,14 if y<0 else 10),plaster,.01)
 for z in [.25,4.5,9.5,14]:cube('Stone cornice',(24,-y,z),(51.6,.48,.2),plaster)
 for x in [0,24,48]:cube('Facade pier',(x,-y,7),(.4,.5,14),plaster)
 for z in [2,7,12]:
  for x in [6,15,33,42]:
   cube('Window recess',(x,-y+.15 if y<0 else -y-.15,z),(1.9,.035,2.2),glass)
   for side in [-1,1]:cube('Window jamb',(x+side*1,-y+.22 if y<0 else -y-.22,z),(.12,.12,2.45),wood)
   for h in [-1.16,1.16]:cube('Window sill',(x,-y+.22 if y<0 else -y-.22,z+h),(2.2,.18,.12),wood)
   cube('Window mullion',(x,-y+.23 if y<0 else -y-.23,z),(.05,.12,2.2),wood)
for x in [-1.7,49.7]:
 for z_mid,length in [(2.6,9.1),(15.5,9.8)]:cube('Side masonry',(x,-z_mid,9),(.25,length,10),plaster)
for y,angle in [(-3.5,-.32),(-14.5,.32)]:
 roof=cube('Pitched roof',(24,y,15.55),(53,11.6,.22),slate,.02);roof.rotation_euler.x=angle
for x in [8,39]:
 cube('Chimney',(x,-8,16.6),(1.1,1.5,3.2),plaster)
 cube('Chimney cap',(x,-8,18.25),(1.35,1.7,.18),slate)
# Ground-floor garage extension roof.
cube('Garage roof',(24,-30,4.1),(51,21,.25),slate)
# Export each collection with real part geometry; renderer binds shared scanned materials by name.
stats={}
for name,objects in groups.items():
 bpy.ops.object.select_all(action='DESELECT')
 for o in objects:o.select_set(True)
 bpy.context.view_layer.objects.active=objects[0]
 bpy.ops.object.join();obj=bpy.context.object;obj.name=name
 bpy.context.scene.cursor.location=(0,0,0);bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
 bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
 bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.uv.cube_project(cube_size=1);bpy.ops.object.mode_set(mode='OBJECT')
 bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB',use_selection=True)
 stats[name]={'vertices':len(obj.data.vertices),'triangles':sum(len(p.vertices)-2 for p in obj.data.polygons)}
 obj.location.x=list(groups).index(name)*5
bpy.ops.wm.save_as_mainfile(filepath=str(SRC/'repair-assets.blend'))
(SRC/'asset-metrics.json').write_text(json.dumps(stats,indent=2))
print('REPAIR_ASSETS_COMPLETE',stats)
