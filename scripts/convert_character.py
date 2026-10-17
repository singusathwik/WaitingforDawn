"""Convert CC-BY Rosswet Mobile character to embedded glTF with selected skeletal clips."""
import bpy,sys,math,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
source=ROOT/'source_art/rosswet'
bpy.ops.wm.open_mainfile(filepath=str(source/'new_thin_zombie.blend'))
for o in list(bpy.data.objects):
 if o.type not in {'MESH','ARMATURE'}:bpy.data.objects.remove(o,do_unlink=True)
mesh=next(o for o in bpy.data.objects if o.type=='MESH')
arm=next(o for o in bpy.data.objects if o.type=='ARMATURE')
# Rebuild the legacy Blender Internal material as a standard texture-based PBR material.
mat=bpy.data.materials.new('Spectral skin - Rosswet Mobile');mat.use_nodes=True
nodes=mat.node_tree.nodes;links=mat.node_tree.links
bsdf=nodes.get('Principled BSDF');bsdf.inputs['Roughness'].default_value=.91
image=bpy.data.images.load(str(source/'new_thin_zombie.png'));image.pack()
tex=nodes.new('ShaderNodeTexImage');tex.image=image
links.new(tex.outputs['Color'],bsdf.inputs['Base Color'])
mesh.data.materials.clear();mesh.data.materials.append(mat)
for poly in mesh.data.polygons:poly.use_smooth=True
keep={'idle','walk','run','attack1_l','attack2'}
for action in list(bpy.data.actions):
 if action.name not in keep:bpy.data.actions.remove(action)
arm.animation_data.action=bpy.data.actions['idle']
if arm.animation_data:
 for track in list(arm.animation_data.nla_tracks):arm.animation_data.nla_tracks.remove(track)
bpy.context.scene.frame_set(0)
bpy.context.scene.render.fps=30
for o in bpy.data.objects:o.select_set(True)
ROOT.joinpath('assets/models').mkdir(parents=True,exist_ok=True)
bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets/models/wraith.glb'),export_format='GLB',export_animations=True,export_animation_mode='ACTIONS',export_force_sampling=True,export_frame_range=False,export_skins=True,export_def_bones=False,export_yup=True)
print('EXPORTED CHARACTER',len(mesh.data.vertices),'vertices',len(mesh.data.polygons),'faces')
print('CLIPS',[a.name for a in bpy.data.actions])
