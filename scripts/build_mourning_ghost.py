"""Add an original, skinned mourning veil and ragged dress to the credited Rosswet rig."""
import bpy, math
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(ROOT/'assets/models/wraith.glb'))
arm=next(o for o in bpy.data.objects if o.type=='ARMATURE')
cloth=bpy.data.materials.new('Eleanor worn mourning cloth');cloth.use_nodes=True
bsdf=cloth.node_tree.nodes.get('Principled BSDF')
bsdf.inputs['Base Color'].default_value=(.075,.065,.057,1)
bsdf.inputs['Roughness'].default_value=.98
tex=cloth.node_tree.nodes.new('ShaderNodeTexImage')
tex.image=bpy.data.images.load(str(ROOT/'assets/textures/quatrefoil_jacquard_fabric/diff.jpg'));tex.image.pack()
mix=cloth.node_tree.nodes.new('ShaderNodeMixRGB');mix.blend_type='MULTIPLY';mix.inputs[0].default_value=1;mix.inputs[2].default_value=(.10,.12,.14,1)
cloth.node_tree.links.new(tex.outputs['Color'],mix.inputs[1]);cloth.node_tree.links.new(mix.outputs[0],bsdf.inputs['Base Color'])
def fabric(name,rings,columns,bone,arc=2*math.pi,start=0):
    vertices=[];faces=[]
    for row,(height,radius,y) in enumerate(rings):
        for col in range(columns+1):
            a=start+arc*col/columns
            r=radius*(1+.045*math.sin(col*2.9+row*.4))
            z=height-(.18*(.5+.5*math.sin(col*4.3)) if row==len(rings)-1 else 0)
            vertices.append((math.cos(a)*r,math.sin(a)*r+y,z))
    for row in range(len(rings)-1):
        for col in range(columns):
            i=row*(columns+1)+col;faces.append((i,i+1,i+columns+2,i+columns+1))
    mesh=bpy.data.meshes.new(name);mesh.from_pydata(vertices,[],faces);mesh.update()
    obj=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(obj)
    obj.data.materials.append(cloth)
    for face in mesh.polygons:face.use_smooth=True
    uv=mesh.uv_layers.new()
    for face in mesh.polygons:
        for loop in face.loop_indices:
            vi=mesh.loops[loop].vertex_index;uv.data[loop].uv=(vi%(columns+1)/columns,vi//(columns+1)/(len(rings)-1))
    group=obj.vertex_groups.new(name=bone);group.add(list(range(len(vertices))),1,'REPLACE')
    mod=obj.modifiers.new('Follow skeletal animation','ARMATURE');mod.object=arm
    obj.parent=arm
    obj.matrix_parent_inverse=arm.matrix_world.inverted()
    cloth.use_backface_culling=False
fabric('Ragged mourning skirt',[(4.45,.85,.07),(3.7,1.0,.07),(2.8,1.20,.07),(1.8,1.42,.07),(.3,1.6,.07)],32,'hips')
fabric('Mourning bodice',[(6.55,.85,.1),(6.05,1.02,.1),(5.3,.94,.1),(4.25,.82,.1)],32,'spine')
# Open front, uneven pleats: this is geometry attached to the head, not a billboard.
fabric('Torn funeral veil',[(7.95,.18,-.08),(7.75,.58,-.08),(7.2,.66,-.06),(6.5,.76,.05),(5.65,.91,.15)],32,'head',math.pi*1.55,-math.pi*.275)
for o in bpy.data.objects:o.select_set(True)
bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets/models/mourning_ghost.glb'),export_format='GLB',export_animations=True,export_animation_mode='ACTIONS',export_skins=True,export_yup=True)
print('Exported mourning ghost: original veil and skirt, retained credited animated base')
