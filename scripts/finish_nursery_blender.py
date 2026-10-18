"""Approved Function -> editable Form-stage room. No GLB/game export or deployment."""
from pathlib import Path
import bpy
import json
import math
import bmesh
from mathutils import Vector, Matrix

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'design/rooms/eleanors-nursery'
approval=json.loads((OUT/'function-approval.json').read_text())
assert approval['status']=='approved'
bpy.ops.wm.open_mainfile(filepath=str(OUT/'nursery-concept.blend'))
# Keep the floor flush with both existing stair landings; an overhang traps capsules.
bpy.data.objects['floor'].dimensions.x=21.0
scene=bpy.context.scene
scene.render.engine='CYCLES';scene.cycles.samples=28;scene.cycles.use_denoising=True
scene.view_settings.view_transform='AgX';scene.view_settings.look='AgX - Medium High Contrast'
scene.view_settings.exposure=.7
scene.world.use_nodes=True
scene.world.node_tree.nodes.get('Background').inputs['Color'].default_value=(.13,.19,.29,1)
scene.world.node_tree.nodes.get('Background').inputs['Strength'].default_value=.12

def shader(name,color=(.2,.2,.2,1),rough=.75,metal=0):
    m=bpy.data.materials.new(name);m.use_nodes=True;m.diffuse_color=color
    p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=color
    p.inputs['Roughness'].default_value=rough;p.inputs['Metallic'].default_value=metal
    return m,p,m.node_tree.nodes,m.node_tree.links

def image_node(nodes,path,noncolor=False):
    n=nodes.new('ShaderNodeTexImage');n.image=bpy.data.images.load(str(path),check_existing=True)
    if noncolor:n.image.colorspace_settings.name='Non-Color'
    return n

def pbr(name,folder,scale=1):
    m,p,n,l=shader(name)
    coord=n.new('ShaderNodeTexCoord');mapping=n.new('ShaderNodeVectorMath');mapping.operation='SCALE';mapping.inputs[3].default_value=scale
    l.new(coord.outputs['Object'],mapping.inputs[0])
    for file,socket in [('diff.jpg','Base Color'),('rough.jpg','Roughness'),('nor_gl.jpg','Normal')]:
        tex=image_node(n,ROOT/'assets/textures'/folder/file,file!='diff.jpg');tex.projection='BOX';tex.projection_blend=.18
        l.new(mapping.outputs[0],tex.inputs['Vector'])
        if file=='nor_gl.jpg':
            # Box-projected scanned normals are for native review. Delivery gets a tangent-space bake.
            bump=n.new('ShaderNodeNormalMap');bump.inputs['Strength'].default_value=.35;l.new(tex.outputs['Color'],bump.inputs['Color']);l.new(bump.outputs[0],p.inputs[socket])
        else:l.new(tex.outputs['Color'],p.inputs[socket])
    return m

wood,p,n,l=shader('Aged walnut / generated albedo',(.17,.09,.045,1),.69)
coord=n.new('ShaderNodeTexCoord');mapping=n.new('ShaderNodeVectorMath');mapping.operation='SCALE';mapping.inputs[3].default_value=1.4;l.new(coord.outputs['Object'],mapping.inputs[0])
tex=image_node(n,OUT/'textures/walnut-albedo.png');tex.projection='BOX';tex.projection_blend=.12;l.new(mapping.outputs[0],tex.inputs['Vector'])
l.new(tex.outputs['Color'],p.inputs['Base Color'])
bump=n.new('ShaderNodeBump');bump.inputs['Strength'].default_value=.16;bump.inputs['Distance'].default_value=.003
l.new(tex.outputs['Color'],bump.inputs['Height']);l.new(bump.outputs['Normal'],p.inputs['Normal'])
floor=pbr('Old oak floor / Poly Haven','old_wooden_floor_01',.33)
# Keep aged boards matte; the source roughness still supplies local variation.
fn=floor.node_tree.nodes;fl=floor.node_tree.links;fp=fn.get('Principled BSDF')
old=fp.inputs['Roughness'].links[0].from_socket
for link in list(fp.inputs['Roughness'].links):fl.remove(link)
remap=fn.new('ShaderNodeMapRange');remap.inputs['To Min'].default_value=.72;remap.inputs['To Max'].default_value=.98
fl.new(old,remap.inputs['Value']);fl.new(remap.outputs['Result'],fp.inputs['Roughness'])
wallpaper=pbr('Decrepit wallpaper / Poly Haven','decrepit_wallpaper',.48)
plaster=pbr('Cracked ceiling plaster / Poly Haven','rough_plaster_broken',.5)
brass,p,n,l=shader('Tarnished brass',(.24,.15,.056,1),.55,.72)
noise=n.new('ShaderNodeTexNoise');noise.inputs['Scale'].default_value=35
ramp=n.new('ShaderNodeValToRGB');ramp.color_ramp.elements[0].color=(.045,.032,.012,1);ramp.color_ramp.elements[1].color=(.36,.23,.075,1)
l.new(noise.outputs['Fac'],ramp.inputs[0]);l.new(ramp.outputs[0],p.inputs['Base Color'])
linen,p,n,l=shader('Faded striped linen',(.38,.32,.22,1),.95)
coord=n.new('ShaderNodeTexCoord');wave=n.new('ShaderNodeTexWave');wave.wave_type='BANDS';wave.bands_direction='X';wave.inputs['Scale'].default_value=14;wave.inputs['Distortion'].default_value=.2
l.new(coord.outputs['Generated'],wave.inputs['Vector'])
ramp=n.new('ShaderNodeValToRGB');ramp.color_ramp.elements[0].position=.3;ramp.color_ramp.elements[0].color=(.19,.17,.13,1);ramp.color_ramp.elements[1].position=.42;ramp.color_ramp.elements[1].color=(.48,.42,.31,1)
l.new(wave.outputs['Color'],ramp.inputs['Fac']);l.new(ramp.outputs['Color'],p.inputs['Base Color'])
noise=n.new('ShaderNodeTexNoise');noise.inputs['Scale'].default_value=190
bump=n.new('ShaderNodeBump');bump.inputs['Distance'].default_value=.001;bump.inputs['Strength'].default_value=.18;l.new(noise.outputs['Fac'],bump.inputs['Height']);l.new(bump.outputs[0],p.inputs['Normal'])
paper=shader('Old paper and faded cream paint',(.42,.35,.22,1),.9)[0]
red=shader('Oxidized red book cloth',(.105,.027,.021,1),.88)[0]
blue=shader('Faded blue book cloth',(.03,.065,.075,1),.9)[0]
glass,p,n,l=shader('Clouded sealed window',(.065,.10,.14,1),.28)
p.inputs['Metallic'].default_value=.12
black=shader('Recess darkness',(.008,.012,.014,1),1)[0]
replacement={'Clay timber':wood,'Clay hardware':brass,'Clay fabric':linen,'Clay pages':paper,'Clay plaster':wallpaper}
for obj in bpy.data.objects:
    if obj.type not in {'MESH','CURVE'}:continue
    for i,material in enumerate(obj.data.materials):
        if material and material.name in replacement:obj.data.materials[i]=replacement[material.name]
    if obj.name=='floor' or obj.name.startswith('Entrance apron'):
        obj.data.materials.clear();obj.data.materials.append(floor)
    if obj.name=='ceiling':obj.data.materials.clear();obj.data.materials.append(plaster)
    if obj.name.startswith('Exterior backing'):obj.data.materials.clear();obj.data.materials.append(glass)
    if obj.name.startswith('Shelf book'):
        obj.data.materials.clear();obj.data.materials.append([red,blue,paper][sum(map(ord,obj.name))%3])
    if obj.name.startswith('Lamp shade') and obj.type=='MESH':
        bm=bmesh.new();bm.from_mesh(obj.data)
        bmesh.ops.delete(bm,geom=[f for f in bm.faces if len(f.verts)>4],context='FACES')
        bm.to_mesh(obj.data);bm.free()
    if obj.name.startswith('Cradle'):obj.location.z-=.035
    if obj.name=='Preserved under-bed search box':obj.location.z=.4
    if obj.name.startswith('Shelf book'):obj.location.z-=.01
    if obj.name.startswith('Book on diary table'):obj.location.y=-2.8
    if obj.name=='Diary interaction anchor':obj.location=( -6,-3.15,1.125)

# Restore the actual scanned materials of preserved console/chair meshes.
def imported_material(asset):
    folder=ROOT/'assets/models'/asset
    m,p,n,l=shader(asset+' original scanned PBR')
    diffuse=next(folder.rglob('*diff_1k.jpg'));normal=next(folder.rglob('*nor_gl_1k.jpg'));arm=next(folder.rglob('*arm_1k.jpg'))
    t=image_node(n,diffuse);l.new(t.outputs['Color'],p.inputs['Base Color'])
    t=image_node(n,normal,True);nn=n.new('ShaderNodeNormalMap');l.new(t.outputs['Color'],nn.inputs['Color']);l.new(nn.outputs[0],p.inputs['Normal'])
    t=image_node(n,arm,True);sep=n.new('ShaderNodeSeparateColor');l.new(t.outputs['Color'],sep.inputs[0]);l.new(sep.outputs['Green'],p.inputs['Roughness']);l.new(sep.outputs['Blue'],p.inputs['Metallic'])
    return m
console=imported_material('ClassicConsole_01');chair=imported_material('ArmChair_01')
for obj in bpy.data.collections['Preserved fixtures'].objects:
    if obj.type!='MESH':continue
    if obj.name.startswith('ClassicConsole_01'):obj.data.materials.clear();obj.data.materials.append(console)
    if obj.name.startswith('ArmChair_01'):obj.data.materials.clear();obj.data.materials.append(chair)
table=bpy.data.objects.get('ClassicConsole_01.001')
if table:table.location.y+=1.8
reading_chair=bpy.data.objects.get('ArmChair_01.001')
if reading_chair:
    pivot=Vector((-7,-7,0))
    reading_chair.matrix_world=Matrix.Translation(pivot)@Matrix.Rotation(math.atan2(4,1)+.4,4,'Z')@Matrix.Translation(-pivot)@reading_chair.matrix_world

def box(name,location,size,material,collection='Joinery',bevel=.012):
    bpy.ops.mesh.primitive_cube_add(size=1,location=location);o=bpy.context.object;o.name=name;o.dimensions=size
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    for c in list(o.users_collection):c.objects.unlink(o)
    bpy.data.collections[collection].objects.link(o);o.data.materials.append(material)
    if bevel:m=o.modifiers.new('Worn edge radius','BEVEL');m.width=bevel;m.segments=2;o.modifiers.new('Weighted normals','WEIGHTED_NORMAL')
    return o

# Real frame profiles terminate at the approved apertures. They are dressing over cut walls.
schedule=json.loads((OUT/'openings.json').read_text())['openings']
for op in schedule:
    if op['kind']!='door':continue
    x,y,z=op['location'];w=op['widthMeters'];h=op['heightMeters'];along_x=op['cutterDimensions'][0]>op['cutterDimensions'][1]
    for side in [-1,1]:
        loc=(x+side*(w/2+.055),y,h/2) if along_x else (x,y+side*(w/2+.055),h/2)
        size=(.11,.25,h) if along_x else (.25,.11,h)
        box('Door jamb '+op['id'],loc,size,wood)
    box('Door lintel '+op['id'],(x,y,h+.055),(w+.22,.26,.11) if along_x else (.26,w+.22,.11),wood)

# Keep the supplied silhouette but add controlled mattress surface variation.
for name in ['Cradle ticking mattress','Preserved bed mattress','Preserved pillow']:
    o=bpy.data.objects.get(name)
    if not o:continue
    sub=o.modifiers.new('Cloth surface subdivisions','SUBSURF');sub.subdivision_type='SIMPLE';sub.levels=2
    tx=bpy.data.textures.new(name+' textile waviness',type='CLOUDS');tx.noise_scale=.28;tx.noise_depth=1
    dis=o.modifiers.new('Small fabric unevenness','DISPLACE');dis.texture=tx;dis.strength=.018;dis.texture_coords='GLOBAL'

# Keeper uses the existing imported character, not a box proxy.
proxy=bpy.data.objects.get('Keeper discovery reserve')
if proxy:bpy.data.objects.remove(proxy,do_unlink=True)
before=set(bpy.data.objects);bpy.ops.import_scene.gltf(filepath=str(ROOT/'assets/models/wraith.glb'))
added=set(bpy.data.objects)-before
for o in list(added):
    if o.type=='MESH' and o.name=='Icosphere':
        added.remove(o);bpy.data.objects.remove(o,do_unlink=True)
skin,p,n,l=shader('Keeper / Rosswet original skin',rough=.91)
t=image_node(n,ROOT/'source_art/rosswet/new_thin_zombie.png');l.new(t.outputs['Color'],p.inputs['Base Color'])
for o in added:
    if o.type=='MESH':o.data.materials.clear();o.data.materials.append(skin)
points=[o.matrix_world@Vector(c) for o in added if o.type=='MESH' for c in o.bound_box]
lo=Vector(tuple(min(p[i] for p in points) for i in range(3)));hi=Vector(tuple(max(p[i] for p in points) for i in range(3)))
scale=2.05/(hi.z-lo.z)
center=(lo+hi)/2
matrix=Matrix.Translation((6,3,.25))@Matrix.Rotation(-math.pi/2,4,'X')@Matrix.Scale(scale,4)@Matrix.Translation(-center)
for o in added:
    if o.parent not in added:o.matrix_world=matrix@o.matrix_world
    o.name='Keeper__'+o.name
    for c in list(o.users_collection):c.objects.unlink(o)
    bpy.data.collections['Preserved fixtures'].objects.link(o)
bpy.context.view_layer.update()
lowest=min((o.matrix_world@Vector(c)).z for o in added if o.type=='MESH' for c in o.bound_box)
for o in added:
    if o.parent not in added:o.location.z+=-.002-lowest

# One shared fixture manifest is consumed by the native lighting and later game importer.
for o in list(bpy.data.objects):
    if o.type=='LIGHT':bpy.data.objects.remove(o,do_unlink=True)
fixtures=[]
def light(id,kind,loc,color,energy,size,target=None,role='practical'):
    d=bpy.data.lights.new(id,kind);d.color=color;d.energy=energy
    if kind=='AREA':d.shape='DISK';d.size=size
    else:d.shadow_soft_size=size
    o=bpy.data.objects.new(id,d);scene.collection.objects.link(o);o.location=loc
    if target:o.rotation_euler=(Vector(target)-o.location).to_track_quat('-Z','Y').to_euler()
    fixtures.append(dict(id=id,type=kind,location=list(loc),color=list(color),energyWatts=energy,sizeMeters=size,role=role))
    return o
for i,(x,y) in enumerate([(-5,5),(5,5),(-5,-5),(5,-5),(0,0)]):
    central=x==0 and y==0
    z=2.64 if central else 2.92
    light('Practical-'+str(i),'POINT',(x,y,z),(1,.62,.28),35 if i!=1 else 25,.08)
    glow,p,n,l=shader('Filament '+str(i),(1,.63,.24,1),.35)
    p.inputs['Emission Color'].default_value=(1,.37,.07,1);p.inputs['Emission Strength'].default_value=2
    box('Visible filament '+str(i),(x,y,z),(.045,.045,.065),glow,'Ceiling',.016)
    if central:
        for o in bpy.data.collections['Ceiling'].objects:
            if o.name.startswith(('Ceiling rose','Lamp suspension','Lamp shade')) and abs(o.location.x)<.01 and abs(o.location.y)<.01:
                # Some generated curves carry coordinates in their data rather than object transforms.
                if o.type=='MESH' and o.name.startswith('Ceiling rose'):
                    xs=[v.co.x for v in o.data.vertices];ys=[v.co.y for v in o.data.vertices]
                    if abs(sum(xs)/len(xs))<.01 and abs(sum(ys)/len(ys))<.01 and min(v.co.z for v in o.data.vertices)>3.5:
                        for v in o.data.vertices:v.co.z-=.28
                elif o.type=='MESH' and o.name.startswith('Lamp shade'):
                    if min(v.co.z for v in o.data.vertices)>2.9:
                        # Only the fixture whose evaluated XY bounds are at the origin.
                        xs=[v.co.x for v in o.data.vertices];ys=[v.co.y for v in o.data.vertices]
                        if abs(sum(xs)/len(xs))<.01 and abs(sum(ys)/len(ys))<.01:
                            for v in o.data.vertices:v.co.z-=.28
                elif o.type=='CURVE':
                    pts=o.data.splines[0].points
                    if abs(pts[0].co.x)<.01 and abs(pts[0].co.y)<.01:
                        for pnt in pts:pnt.co.z-=.28
for i,(x,y) in enumerate([(-5,10.3),(5,10.3),(-5,-10.3),(5,-10.3)]):
    light('Window bounce-'+str(i),'AREA',(x,y,2.05),(.25,.42,.70),65,2.6,(x,0,1.2),'baked window fill')
# Broad fill is a documented authoring approximation of baked ambient bounce.
for i,(x,y) in enumerate([(-5,5),(5,5),(-5,-5),(5,-5)]):
    light('Indirect preview-'+str(i),'AREA',(x,y,3.3),(.48,.49,.45),48,4,(x,y,0),'authoring-only indirect approximation; bake for mobile')
    front_y=2.5 if y>0 else -2.5
    fill=light('Wall bounce preview-'+str(i),'AREA',(x,front_y,2.3),(.62,.56,.45),32,3,(x,y,1),'authoring-only bounced light approximation; bake for mobile')
    fill.data.specular_factor=0
(OUT/'lighting-manifest.json').write_text(json.dumps(dict(schema='waiting-for-dawn.light-fixtures.v1',roomId='eleanors-nursery',runtimeDynamicBudget=3,notes='Bake window/indirect light; nearest three practicals in Compatibility renderer. Native wattages are not Godot energy values.',fixtures=fixtures),indent=2)+'\n')

# One camera contract for review and subsequent runtime comparison.
camera=scene.camera
camera.data.type='PERSP';camera.data.sensor_fit='VERTICAL';camera.data.sensor_height=24
scene.render.resolution_percentage=100;scene.render.image_settings.file_format='PNG'
def render(name,loc,target,fov=70,width=1200,height=780):
    camera.location=loc;camera.rotation_euler=(Vector(target)-camera.location).to_track_quat('-Z','Y').to_euler()
    camera.data.lens=12/math.tan(math.radians(fov/2))
    scene.render.resolution_x=width;scene.render.resolution_y=height
    scene.render.filepath=str(OUT/'renders'/name);bpy.ops.render.render(write_still=True)

bpy.data.collections['Ceiling'].hide_render=False
bpy.data.collections['Circulation review only'].hide_render=True
scene['stage']='FORM REVIEW - Function approved, Form and Runtime pending'
scene['materials_delivery']='Box projections and procedural wear require a tested tangent-space bake before GLB delivery; no flat fallback permitted.'
# Save portable source before rendering. All used images are packed; no plugin paths required.
used_images={node.image for material in bpy.data.materials if material.users and material.use_nodes for node in material.node_tree.nodes if node.type=='TEX_IMAGE' and node.image}
for image in used_images:
    if image.size[0]==0:raise RuntimeError('Unresolved material image: '+image.name)
    if image.source=='FILE':image.pack()
camera.location=(2.1,3.1,1.65);camera.rotation_euler=(Vector((6,6,.8))-camera.location).to_track_quat('-Z','Y').to_euler()
camera.data.lens=12/math.tan(math.radians(35))
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'nursery-form.blend'))
render('form-nursery.png',(2.1,3.1,1.65),(6,6,.8))
render('form-dresser.png',(-.8,2.3,1.65),(-3,6,1))
render('form-wardrobe.png',(-2.7,1.9,1.65),(-6,3,1.2))
for i,(loc,target) in enumerate([((-9.5,9.5,1.65),(-5,5,1.4)),((9.5,9.5,1.65),(5,5,1.4)),((-9.5,-9.5,1.65),(-5,-5,1.4)),((9.5,-9.5,1.65),(5,-5,1.4))]):render('form-corner-'+str(i+1)+'.png',loc,target,120,1000,700)
render('form-ceiling-up.png',(0,0,1.65),(0,0,3.6),105,1000,700)
render('form-ceiling-a.png',(-8,0,1.65),(0,0,3.2),90,1000,700)
render('form-ceiling-b.png',(8,0,1.65),(0,0,3.2),90,1000,700)
# Close-up at the intended inspection distance, not a macro render hiding the rest of the room.
render('form-cradle-detail.png',(4.7,4.6,1.30),(6,6,.75),65,1000,800)
print('NURSERY_FORM_RENDERED; Form human approval pending; no production export')
