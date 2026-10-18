"""Name animation assemblies and render measured, monochrome Form review views."""
from pathlib import Path
import bpy,json,math
from mathutils import Vector

ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'design/rooms/eleanors-nursery'
bpy.ops.wm.open_mainfile(filepath=str(OUT/'nursery-form.blend'))
scene=bpy.context.scene
def parent(name,objects,location,kind):
    old=bpy.data.objects.get(name)
    if old:return
    root=bpy.data.objects.new(name,None);scene.collection.objects.link(root);root.location=location
    root['game_interaction']=kind;bpy.context.view_layer.update()
    for o in objects:
        matrix=o.matrix_world.copy();o.parent=root;o.matrix_world=matrix
for label,xx,yy,offset in [('Nursery dresser',-3,6,0),('Toy drawers',6,-6,6)]:
    for i in range(6):
        objects=[o for o in bpy.data.objects if o.name.startswith(label+' drawer '+str(i+1)+' ')]
        parent('Drawer_'+str(offset+i),objects,(xx+(i%3-1)*1.1,yy-.37,.58+(i//3)*.64),'search-compartment-'+str(offset+i))
for side in ['left','right']:
    objects=[]
    for o in bpy.data.objects:
        if not o.name.startswith(('Wardrobe lower door','Wardrobe upper door','Wardrobe handle')):continue
        if (o.location.y<3)==(side=='left'):objects.append(o)
    parent('Wardrobe_leaf_'+side,objects,(-5.24,2.16 if side=='left' else 3.84,0),'hiding-door-'+side)
scene['animation_assemblies']='Drawer_0..11 translate along local -Y; Wardrobe_leaf_left/right rotate about Z. Runtime controller binding pending.'
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'nursery-form.blend'))
scene.render.engine='BLENDER_WORKBENCH';scene.world.color=(.9,.9,.9)
shade=scene.display.shading;shade.light='STUDIO';shade.color_type='SINGLE';shade.single_color=(.65,.65,.65);shade.show_shadows=False;shade.show_cavity=True;shade.cavity_type='BOTH';shade.show_object_outline=True;shade.object_outline_color=(.02,.02,.02);shade.background_type='WORLD'
scene.view_settings.view_transform='Standard';scene.view_settings.look='Medium High Contrast';scene.view_settings.exposure=0
cam=scene.camera
def render(file,location,target,scale=None,width=1200,height=1000):
    cam.location=location;cam.rotation_euler=(Vector(target)-cam.location).to_track_quat('-Z','Y').to_euler()
    cam.data.type='ORTHO' if scale else 'PERSP'
    if scale:cam.data.ortho_scale=scale
    else:cam.data.lens=12/math.tan(math.radians(42))
    scene.render.resolution_x=width;scene.render.resolution_y=height;scene.render.filepath=str(OUT/file);bpy.ops.render.render(write_still=True)
ceil=bpy.data.collections['Ceiling'];ceil.hide_render=True
# Camera near clipping would also cut the props. Section only the actual wall meshes.
old=[];temporary=[]
for collection in ['Shell','Joinery']:
    c=bpy.data.collections[collection]
    for o in list(c.objects):
        iswall=o.name in {s['id'] for s in json.loads((OUT/'room-layout.json').read_text())['surfaces'] if s.get('wall')}
        if not (iswall or ' trim' in o.name or o.name.startswith(('Door jamb','Door lintel'))):continue
        o.hide_render=True;old.append(o)
        q=o.copy();q.data=o.data.copy();q.hide_render=False;c.objects.link(q);temporary.append(q)
        bpy.ops.mesh.primitive_cube_add(size=1,location=(0,0,-4.425));cut=bpy.context.object;cut.dimensions=(100,100,11.15)
        bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
        mod=q.modifiers.new('Plan section','BOOLEAN');mod.operation='INTERSECT';mod.solver='EXACT';mod.object=cut
        bpy.context.view_layer.objects.active=q;bpy.ops.object.modifier_apply(modifier=mod.name);bpy.data.objects.remove(cut,do_unlink=True)
render('plans/form-lower-room.png',(0,0,35),(0,0,0),28,1400,1200)
for o in temporary:bpy.data.objects.remove(o,do_unlink=True)
for o in old:o.hide_render=False
for name in ['Shell','Joinery','Furniture prototypes','Preserved fixtures']:bpy.data.collections[name].hide_render=True
ceil.hide_render=False
render('plans/form-reflected-ceiling.png',(0,0,-12),(0,0,3.5),24,1200,1200)
for name in ['Shell','Joinery','Furniture prototypes','Preserved fixtures']:bpy.data.collections[name].hide_render=False
for op in json.loads((OUT/'openings.json').read_text())['openings']:
    p=Vector(op['location']);along_x=op['cutterDimensions'][0]>op['cutterDimensions'][1]
    normal=Vector((0,-1 if p.y>0 else 1,0)) if along_x else Vector((1 if p.x<0 else -1,0,0))
    tangent=Vector((1,0,0)) if along_x else Vector((0,1,0))
    position=p+normal*2.5+tangent*1.1;position.z=1.65
    render('renders/opening-'+op['id']+'.png',position,p,None,500,500)
print('FORM_ANIMATION_ROOTS_AND_ORTHOGRAPHIC_REVIEW_READY')
