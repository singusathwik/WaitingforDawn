"""Function-stage Blender prototype only; never exports or changes the live game.

Run with Blender --background --python scripts/build_nursery_concept.py.
Local axes: X east, Y north, Z up. Godot = (75 + X, 5 + Z, 9 - Y).
All dimensions are metres. Keep separate drawers/door leaves for future animation.
"""
from pathlib import Path
import bpy
import json
import math
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'design/rooms/eleanors-nursery'
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
scene = bpy.context.scene
scene.unit_settings.system = 'METRIC'
scene.unit_settings.scale_length = 1
scene.render.engine = 'CYCLES'
scene.cycles.samples = 20
scene.cycles.use_denoising = True
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = 'PNG'
scene.render.film_transparent = False
scene.world.color = (.45, .45, .45)
scene.view_settings.view_transform = 'AgX'
scene.view_settings.look = 'AgX - Medium High Contrast'

def mat(name, gray):
    m = bpy.data.materials.new(name)
    m.diffuse_color = (gray, gray, gray, 1)
    m.use_nodes = True
    p = m.node_tree.nodes.get('Principled BSDF')
    p.inputs['Base Color'].default_value = (gray, gray, gray, 1)
    p.inputs['Roughness'].default_value = .72
    return m

wallmat, wood, iron, fabric, paper = [mat(n, c) for n,c in [('Clay plaster',.72),('Clay timber',.34),('Clay hardware',.16),('Clay fabric',.58),('Clay pages',.8)]]
groups = {}

def group(name):
    c = bpy.data.collections.new(name)
    scene.collection.children.link(c)
    groups[name] = c
    return c

shell, ceiling, trim, props, fixtures, routes = [group(n) for n in ['Shell','Ceiling','Joinery','Furniture prototypes','Preserved fixtures','Circulation review only']]

def put(o, name, collection, material):
    o.name = name
    for c in list(o.users_collection): c.objects.unlink(o)
    collection.objects.link(o)
    if material: o.data.materials.append(material)
    return o

def box(name, loc, size, material=wood, collection=props, bevel=.014):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    o = put(bpy.context.object,name,collection,material)
    o.dimensions = size
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    if bevel:
        m = o.modifiers.new('Physical edge radius','BEVEL'); m.width = bevel; m.segments = 2
        m = o.modifiers.new('Weighted corners','WEIGHTED_NORMAL')
    return o

def lathe(name, x,y,z, profile, material=wood, collection=props, segments=12):
    verts, faces = [], []
    for height,r in profile:
        verts += [(x+r*math.cos(i*math.tau/segments),y+r*math.sin(i*math.tau/segments),z+height) for i in range(segments)]
    for j in range(len(profile)-1):
        for i in range(segments):
            a=j*segments+i; b=j*segments+(i+1)%segments
            faces.append((a,b,b+segments,a+segments))
    faces += [tuple(reversed(range(segments))),tuple((len(profile)-1)*segments+i for i in range(segments))]
    mesh=bpy.data.meshes.new(name); mesh.from_pydata(verts,[],faces); mesh.update()
    o=bpy.data.objects.new(name,mesh); collection.objects.link(o); mesh.materials.append(material)
    for f in mesh.polygons: f.use_smooth=True
    return o

def rail(name, points, radius=.024, material=wood, collection=props):
    curve=bpy.data.curves.new(name,'CURVE'); curve.dimensions='3D'; curve.resolution_u=2
    curve.bevel_depth=radius; curve.bevel_resolution=2
    spline=curve.splines.new('POLY'); spline.points.add(len(points)-1)
    for p,v in zip(spline.points,points): p.co=(*v,1)
    o=bpy.data.objects.new(name,curve); collection.objects.link(o); curve.materials.append(material)
    return o

def panel(name,x,y,z,w,h):
    box(name+' field',(x,y,z),(w,.055,h),wood)
    for px in [x-w/2+.04,x+w/2-.04]: box(name+' stile',(px,y-.042,z),(.055,.045,h),wood)
    for pz in [z-h/2+.04,z+h/2-.04]: box(name+' rail',(x,y-.042,pz),(w,.045,.055),wood)

def transform_set(before,x,y,angle):
    for o in set(bpy.data.objects)-before:
        ox,oy,oz=o.location
        # Explicit mesh-coordinate objects also rotate around the world origin.
        from mathutils import Matrix
        o.matrix_world = Matrix.Translation((x,y,0)) @ Matrix.Rotation(angle,4,'Z') @ o.matrix_world

def dresser(x,y,name):
    before=set(bpy.data.objects)
    for sx in [-1.5,0,1.5]:
        for sy in [-.29,.29]: lathe(name+' turned foot',sx,sy,0,[(0,.1),(.05,.14),(.11,.15),(.18,.11),(.23,.1)])
    for sx in [-1.69,1.69]: box(name+' end',(sx,0,.94),(.12,.8,1.36))
    box(name+' back',(0,.36,.95),(3.3,.07,1.35))
    for sz,w,d in [(.24,3.5,.84),(1.61,3.5,.84),(1.67,3.58,.88)]: box(name+' cornice',(0,0,sz),(w,d,.06))
    for col in range(3):
        for row in range(2):
            xx=(col-1)*1.1; zz=.58+row*.64; yy=-.37
            ident=f'{name} drawer {row*3+col+1}'
            panel(ident,xx,yy,zz,1.055,.58)
            box(ident+' bottom',(xx,0,zz-.255),(1,.68,.045))
            for dx in [-.49,.49]: box(ident+' side',(xx+dx,0,zz),(.04,.68,.5))
            box(ident+' back',(xx,.31,zz),(1,.04,.5))
            box(ident+' escutcheon',(xx,yy-.071,zz-.14),(.05,.02,.07),iron)
            pts=[(xx+.055*math.sin(i*math.tau/20), yy-.085,zz+.055*math.cos(i*math.tau/20)) for i in range(21)]
            rail(ident+' ring pull',pts,.009,iron)
    transform_set(before,x,y,0)

def wardrobe(x,y,angle):
    before=set(bpy.data.objects)
    for sx in [-.72,.72]:
        for sy in [-.63,.63]: lathe('Wardrobe bun foot',sx,sy,0,[(0,.08),(.04,.11),(.1,.12),(.15,.09)])
    for sx in [-.87,.87]: box('Wardrobe side',(sx,0,1.22),(.11,1.5,2.15))
    box('Wardrobe back',(0,.73,1.23),(1.7,.08,2.15))
    box('Wardrobe floor',(0,0,.17),(1.75,1.55,.08))
    for z,w,d in [(2.28,1.85,1.6),(2.34,1.93,1.64),(2.39,2,1.68)]: box('Wardrobe stepped crown',(0,0,z),(w,d,.06))
    # Two doors deliberately leave a 50 mm eye slit at local height 1.51 m.
    for sx in [-.418,.418]:
        panel('Wardrobe lower door',sx,-.76,.85,.81,1.26)
        panel('Wardrobe upper door',sx,-.76,1.91,.81,.75)
        box('Wardrobe handle',(sx+(.23 if sx<0 else -.23),-.84,1.09),(.025,.05,.18),iron)
    rail('Wardrobe hanging rod',[(-.8,0,2.07),(.8,0,2.07)],.022,iron)
    transform_set(before,x,y,angle)

def cradle(x,y):
    before=set(bpy.data.objects)
    for sx in [-.71,.71]:
        # A solid curved runner with visible thickness and a real support surface.
        verts=[]
        for sy in [-.58+i*1.16/24 for i in range(25)]:
            z=.035+.25*(sy/.58)**2
            verts += [(sx-.035,sy,z),(sx+.035,sy,z),(sx-.035,sy,z+.10),(sx+.035,sy,z+.10)]
        faces=[]
        for i in range(24):
            a=i*4;b=a+4
            faces += [(a,b,b+1,a+1),(a+2,a+3,b+3,b+2),(a,a+2,b+2,b),(a+1,b+1,b+3,a+3)]
        faces += [(0,1,3,2),(96,98,99,97)]
        me=bpy.data.meshes.new('Runner');me.from_pydata(verts,[],faces);me.update()
        o=bpy.data.objects.new('Cradle curved runner',me);props.objects.link(o);me.materials.append(wood)
        for sy in [-.36,.36]:
            lathe('Cradle turned corner',sx,sy,.18,[(0,.045),(.06,.06),(.12,.04),(.45,.035),(.58,.055),(.64,.035),(.89,.04),(.94,.06),(.98,.025)],segments=16)
    box('Cradle slatted base',(0,0,.42),(1.48,.8,.1))
    box('Cradle ticking mattress',(0,0,.51),(1.37,.69,.14),fabric,bevel=.065)
    for sy in [-.38,.38]:
        rail('Cradle curved top rail',[(xx,sy,.99+.12*(xx/.71)**2) for xx in [-.71+i*1.42/24 for i in range(25)]],.034)
        for i in range(13):
            xx=-.64+i*1.28/12; height=.5+.12*(xx/.71)**2
            lathe('Cradle spindle',xx,sy,.46,[(0,.014),(.04,.019),(.1,.013),(height-.09,.013),(height-.04,.019),(height,.014)],segments=8)
    for sx in [-.71,.71]:
        rail('Cradle end rail',[(sx,sy,1.10+.055*math.cos(sy/.36*math.pi/2)) for sy in [-.36+i*.72/16 for i in range(17)]],.036)
        for sy in [-.24,-.12,0,.12,.24]: rail('Cradle end slat',[(sx,sy,.46),(sx,sy,1.11)],.015)
    transform_set(before,x,y,0)

def preserved_bed():
    before=set(bpy.data.objects)
    for x in [-.85,.85]:
        for y in [-.99,.99]: lathe('Preserved bed leg',x,y,0,[(0,.055),(.1,.08),(.2,.05),(.7,.06),(.84,.075)],collection=fixtures)
    box('Preserved bed frame',(0,0,.72),(1.9,2.2,.15),wood,fixtures)
    box('Preserved bed mattress',(0,0,.91),(1.8,2.1,.25),fabric,fixtures,.08)
    box('Preserved pillow',(0,.66,1.09),(1.2,.55,.15),paper,fixtures,.07)
    box('Preserved bed headboard',(0,1.1,1.1),(2,.12,1.3),wood,fixtures)
    transform_set(before,3,-6,-math.pi/2)

layout=json.loads((OUT/'room-layout.json').read_text())
openings=json.loads((OUT/'openings.json').read_text())['openings']
for s in layout['surfaces']:
    o=box(s['id'],s['location'],s['dimensions'],wallmat,ceiling if s.get('ceiling') else shell,0)
    for op in [a for a in openings if a['wallId']==s['id']]:
        c=box('Temporary opening cutter',op['location'],op['cutterDimensions'],None,shell,0)
        m=o.modifiers.new(op['id'],'BOOLEAN');m.operation='DIFFERENCE';m.solver='EXACT';m.object=c
        bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=m.name)
        bpy.data.objects.remove(c,do_unlink=True)
        o['opening_ids']=','.join(a['id'] for a in openings if a['wallId']==s['id'])
    # Low baseboards and upper picture rails follow each evaluated wall.
    if s.get('wall'):
        for z,height in [(.14,.28),(2.55,.05),(3.48,.09)]:
            size=list(s['dimensions']); size[2]=height
            q=box(s['id']+' trim',(*s['location'][:2],z),size,wood,trim,.012)
            bpy.context.view_layer.objects.active=q
            for modifier in list(q.modifiers):bpy.ops.object.modifier_apply(modifier=modifier.name)
            for op in [a for a in openings if a['wallId']==s['id'] and a['kind']=='door']:
                location=list(op['location']);dimensions=list(op['cutterDimensions'])
                location[2]-=.05;dimensions[2]+=.1
                c=box('Trim cutter',location,dimensions,None,shell,0)
                m=q.modifiers.new(op['id'],'BOOLEAN');m.operation='DIFFERENCE';m.object=c;m.solver='EXACT'
                bpy.context.view_layer.objects.active=q;bpy.ops.object.modifier_apply(modifier=m.name)
                bpy.data.objects.remove(c,do_unlink=True)

for op in openings:
    if op['kind']!='window': continue
    x,y,z=op['location'];w=op['widthMeters'];h=op['heightMeters']
    for xx in [x-w/2,x,x+w/2]: box('Window mullion '+op['id'],(xx,y,z),(.075,.25,h+.12),wood,trim)
    for zz in [z-h/2,z,z+h/2]: box('Window rail '+op['id'],(x,y,zz),(w+.12,.25,.075),wood,trim)
    box('Window deep sill '+op['id'],(x,y-.04,z-h/2-.06),(w+.28,.5,.12),wood,trim)
    # The blocked exterior is intentional; no false traversable exit.
    box('Exterior backing '+op['id'],(x,y+(.4 if y>0 else -.4),z),(w+.4,.12,h+.3),iron,fixtures)

dresser(-3,6,'Nursery dresser')
dresser(6,-6,'Toy drawers')
wardrobe(-6,3,math.pi/2)
cradle(6,6)
preserved_bed()
box('Preserved under-bed search box',(-3,-6,.65),(1,.8,.8),wood,fixtures)

def imported(asset,x,y,height,angle=0):
    before=set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=str(ROOT/'assets/models'/asset/(asset+'.gltf')))
    added=set(bpy.data.objects)-before
    points=[o.matrix_world@Vector(v) for o in added if o.type=='MESH' for v in o.bound_box]
    low=Vector(tuple(min(p[i] for p in points) for i in range(3)))
    high=Vector(tuple(max(p[i] for p in points) for i in range(3)))
    factor=height/(high.z-low.z)
    offset=Vector(((low.x+high.x)/2,(low.y+high.y)/2,low.z))
    from mathutils import Matrix
    matrix=Matrix.Translation((x,y,0))@Matrix.Rotation(angle,4,'Z')@Matrix.Scale(factor,4)@Matrix.Translation(-offset)
    for o in added:
        if o.parent not in added: o.matrix_world=matrix@o.matrix_world
        for c in list(o.users_collection): c.objects.unlink(o)
        fixtures.objects.link(o)
        if o.type=='MESH': o.data.materials.clear();o.data.materials.append(wood)

imported('ClassicConsole_01',-5,8,1.1)
imported('ArmChair_01',9,6,1.4,math.pi)
imported('ClassicConsole_01',-6,-4.8,1.1)
imported('ArmChair_01',-7,-7,1.4,-.4)
for i in range(7):
    box('Book on diary table',(-6+(i-3)*.2,-4.8,1.15),(.17,.29,.1),paper,fixtures)
box('Diary interaction anchor',(-6,-3,.82),(.34,.26,.05),paper,fixtures)
# The keeper is a location marker, not a new humanoid/monster design claim.
box('Keeper discovery reserve',(6,3,.22),(.75,2.1,.44),fabric,fixtures,.18)
# Built-in toy shelves: repeated supports and objects, never block navigation lanes.
for x in [-9.7,9.7]:
    for yy in [-6,6]:
        for h in [.2,.9,1.6,2.3]: box('Built-in book shelf',(x,yy,h),(.45,2.4,.06),wood,trim)
        for off in [-1.2,1.2]: box('Shelf upright',(x,yy+off,1.2),(.45,.08,2.4),wood,trim)
        for k in range(8): box('Shelf book',(x,yy-.9+k*.25,.43),(.27,.18,.38),fabric if k%2 else paper,trim,.009)
# Ceiling panels and mounted lights are separate in the reflected plan.
for yy in [-8,-4,0,4,8]: box('Exposed ceiling beam',(0,yy,3.46),(21,.18,.28),wood,ceiling)
for x,y in [(-5,5),(5,5),(-5,-5),(5,-5),(0,0)]:
    lathe('Ceiling rose',x,y,3.55,[(0,.2),(.05,.2)],paper,ceiling,24)
    rail('Lamp suspension',[(x,y,3.55),(x,y,3.12)],.012,iron,ceiling)
    lathe('Lamp shade',x,y,2.98,[(0,.2),(.08,.26),(.19,.10)],paper,ceiling,24)
for x in [-10.5,10.5]: box('Entrance apron',(x+(-1.5 if x<0 else 1.5),0,-.1),(3,3,.2),wallmat,shell,0)
for i in range(10): box('Review circulation dash',(-9+i*2,0,.015),(.7,.08,.025),iron,routes,0)

def light(name,loc,energy,size):
    data=bpy.data.lights.new(name,'AREA');data.energy=energy;data.shape='DISK';data.size=size
    o=bpy.data.objects.new(name,data);scene.collection.objects.link(o);o.location=loc
    return o

lights=[]
for x in [-6,6]:
    for y in [-6,6]: lights.append(light('Neutral review softbox',(x,y,3.35),65,5))
lights.append(light('Plan softbox',(0,0,17),250,18))
camera_data=bpy.data.cameras.new('Function review camera')
camera=bpy.data.objects.new('Function review camera',camera_data);scene.collection.objects.link(camera);scene.camera=camera

def render(name,loc,target,ortho=None,width=1300,height=1000):
    camera.location=loc;camera.rotation_euler=(Vector(target)-camera.location).to_track_quat('-Z','Y').to_euler()
    camera_data.type='ORTHO' if ortho else 'PERSP'
    if ortho: camera_data.ortho_scale=ortho
    else: camera_data.lens=21
    scene.render.resolution_x=width;scene.render.resolution_y=height
    scene.render.filepath=str(OUT/name)
    scene.render.engine='BLENDER_WORKBENCH' if name.startswith('plans/') or 'cutaway' in name else 'CYCLES'
    if scene.render.engine=='BLENDER_WORKBENCH':
        shading=scene.display.shading
        shading.light='STUDIO';shading.color_type='MATERIAL';shading.show_shadows='cutaway' in name
        shading.show_cavity=True;shading.cavity_type='BOTH'
        shading.show_object_outline=True;shading.object_outline_color=(.03,.03,.03)
        shading.background_type='WORLD'
        scene.world.color=(.8,.8,.8)
    else: scene.world.color=(.05,.05,.05)
    bpy.ops.render.render(write_still=True)

ceiling.hide_render=True
# A section at 1.15 m reveals door gaps while retaining full actual prop silhouettes.
section=[];original=[]
for c in [shell,trim]:
    for o in list(c.objects):
        if not (o.name in {s['id'] for s in layout['surfaces'] if s.get('wall')} or ' trim' in o.name):continue
        o.hide_render=True;original.append(o)
        q=o.copy();q.data=o.data.copy();q.hide_render=False;c.objects.link(q);section.append(q)
        cutter=box('Plan section cutter',(0,0,-4.425),(100,100,11.15),None,shell,0)
        m=q.modifiers.new('Actual mesh section at 1.15m','BOOLEAN');m.operation='INTERSECT';m.solver='EXACT';m.object=cutter
        bpy.context.view_layer.objects.active=q;bpy.ops.object.modifier_apply(modifier=m.name)
        bpy.data.objects.remove(cutter,do_unlink=True)
render('plans/lower-room.png',(0,0,35),(0,0,0),28,1400,1200)
for o in section:bpy.data.objects.remove(o,do_unlink=True)
for o in original:o.hide_render=False
# Reflected ceiling projection excludes walls/furniture rather than overlaying them.
for c in [shell,trim,props,fixtures,routes]: c.hide_render=True
ceiling.hide_render=False
render('plans/reflected-ceiling.png',(0,0,-12),(0,0,3.5),24,1200,1200)
for c in [shell,trim,props,fixtures]: c.hide_render=False
routes.hide_render=True;ceiling.hide_render=True
render('renders/concept-cutaway.png',(-26,-29,26),(0,0,.6),36,1500,1100)
ceiling.hide_render=False
render('renders/nursery-eye-level.png',(2.1,3.1,1.65),(6,6,.8),None,1400,900)
render('renders/dresser-eye-level.png',(-.8,2.3,1.65),(-3,6,1),None,1400,900)
ceiling.hide_render=True
for side,loc,target in [('north',(0,-30,1.8),(0,10.5,1.8)),('south',(0,30,1.8),(0,-10.5,1.8))]:
    hidden=[]
    for c in [props,fixtures]: c.hide_render=True
    # Show the wall in isolation; plans remain the authority for other features.
    for c in [shell,trim]:
        for o in c.objects:
            if side not in o.name: o.hide_render=True;hidden.append(o)
    render('plans/elevation-'+side+'.png',loc,target,23,1500,360)
    for o in hidden:o.hide_render=False
    for c in [props,fixtures]:c.hide_render=False
ceiling.hide_render=False
camera.location=(2.1,3.1,1.65);camera.rotation_euler=(Vector((6,6,.8))-camera.location).to_track_quat('-Z','Y').to_euler()
camera_data.type='PERSP';camera_data.lens=21
scene['stage']='FUNCTION CONCEPT - not approved, not a shipped game scene'
scene['godot_transform']='(75 + blender.x, 5 + blender.z, 9 - blender.y)'
scene['generation_cost']='No Meshy calls; hand-authored concept geometry'
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'nursery-concept.blend'))
counts={}
for c in [shell,ceiling,trim,props,fixtures]:
    count=0
    for o in c.objects:
        if o.type not in {'MESH','CURVE'}:continue
        ev=o.evaluated_get(bpy.context.evaluated_depsgraph_get());me=ev.to_mesh();me.calc_loop_triangles();count+=len(me.loop_triangles);ev.to_mesh_clear()
    counts[c.name]=count
(OUT/'concept-metrics.json').write_text(json.dumps({'stage':'FUNCTION prototype only','trianglesByCollection':counts,'totalTriangles':sum(counts.values()),'runtimePerformance':'NOT_CHECKED'},indent=2)+'\n')
print('NURSERY_FUNCTION_CONCEPT_RENDERED',counts)
