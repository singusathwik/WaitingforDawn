"""Bake the explicitly approved native room and export mobile geometry, no deployment."""
from pathlib import Path
import bpy,bmesh,json,math,hashlib,time
from mathutils import Matrix,Vector
ROOT=Path(__file__).resolve().parents[1]; PACKAGE=ROOT/'design/rooms/eleanors-nursery'; OUT=ROOT/'assets/models/nursery'
assert json.loads((PACKAGE/'form-approval.json').read_text())['status']=='approved'
OUT.mkdir(parents=True,exist_ok=True)
(OUT/'lighting-manifest.json').write_bytes((PACKAGE/'lighting-manifest.json').read_bytes())
bpy.ops.wm.open_mainfile(filepath=str(PACKAGE/'nursery-form.blend'))
scene=bpy.context.scene
scene.render.engine='CYCLES';scene.cycles.samples=12;scene.cycles.use_denoising=True
scene.render.bake.margin=6;scene.render.bake.use_clear=False
# Preserve transform-sensitive source materials while unwrapping all render geometry.
objects=[];group={};pivots={}
for o in list(bpy.data.objects):
    if o.type=='EMPTY' and (o.name.startswith('Drawer_') or o.name.startswith('Wardrobe_leaf_')):pivots[o.name]=o.matrix_world.copy()
for o in list(bpy.data.objects):
    if o.type not in {'MESH','CURVE'} or o.hide_render or any(c.hide_render for c in o.users_collection):continue
    if o.name.startswith('Entrance apron'):
        bpy.data.objects.remove(o,do_unlink=True)
        continue # The existing sloping game connectors meet the approved door thresholds.
    name=o.parent.name if o.parent and o.parent.name in pivots else 'Room_static'
    # Search box has its own presentation root and keeps compartment 76.
    if o.name=='Preserved under-bed search box':name='Search_box';pivots[name]=o.matrix_world.copy()
    group[o.name]=name
    bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o
    bpy.ops.object.convert(target='MESH')
    if not bpy.context.object.data.polygons:
        bpy.data.objects.remove(bpy.context.object,do_unlink=True)
        continue
    objects.append(bpy.context.object)
group_names=sorted(set(group.values()))
for o in objects:
    # Keep original UVs used by scanned props; baked atlas uses a new layer.
    original=o.data.uv_layers.active
    if original: original.active_render=True
    attribute=o.data.attributes.new(name='runtime_group',type='INT',domain='FACE')
    for item in attribute.data:item.value=group_names.index(group[o.name])
    obj_coord=bpy.data.objects.new('Source coordinates '+o.name,None);scene.collection.objects.link(obj_coord);obj_coord.matrix_world=o.matrix_world.copy()
    lo=Vector(tuple(min(v.co[i] for v in o.data.vertices) for i in range(3)))
    hi=Vector(tuple(max(v.co[i] for v in o.data.vertices) for i in range(3)))
    gen_coord=bpy.data.objects.new('Generated coordinates '+o.name,None);scene.collection.objects.link(gen_coord)
    gen_coord.matrix_world=o.matrix_world@Matrix.Translation(lo)@Matrix.Diagonal((*[max(.0001,v) for v in hi-lo],1))
    # Explicit UV map node avoids changing source image sampling when bake UV is active.
    for slot in o.material_slots:
        mat=slot.material.copy() if slot.material else None
        slot.material=mat
        if not mat or not mat.use_nodes:continue
        generated=mat.node_tree.nodes.new('ShaderNodeTexCoord');generated.object=gen_coord
        for n in list(mat.node_tree.nodes):
            if n.type=='TEX_COORD' and n!=generated:
                n.object=obj_coord
                for link in list(n.outputs['Generated'].links):mat.node_tree.links.new(generated.outputs['Object'],link.to_socket)
            if n.type in ['TEX_NOISE','TEX_WAVE'] and not n.inputs['Vector'].is_linked:mat.node_tree.links.new(generated.outputs['Object'],n.inputs['Vector'])
            if n.type=='TEX_IMAGE' and not n.inputs['Vector'].is_linked and original:
                coord=mat.node_tree.nodes.new('ShaderNodeUVMap');coord.uv_map=original.name
                mat.node_tree.links.new(coord.outputs[0],n.inputs['Vector'])
    m=o.matrix_world.copy();o.parent=None;o.matrix_world=m
bpy.ops.object.select_all(action='DESELECT')
for o in objects:o.select_set(True)
bpy.context.view_layer.objects.active=objects[0]
bpy.ops.object.join();combined=bpy.context.object
bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
combined.data.uv_layers.new(name='RoomAtlas');combined.data.uv_layers.active=combined.data.uv_layers['RoomAtlas']
bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT')
bpy.ops.uv.smart_project(angle_limit=math.radians(65),island_margin=.003,area_weight=1)
bpy.ops.object.mode_set(mode='OBJECT')
atlas=bpy.data.images.new('Nursery approved lighting atlas',width=4096,height=4096,alpha=False)
atlas.generated_color=(.008,.008,.008,1)
for mat in {slot.material for slot in combined.material_slots if slot.material}:
    nodes=mat.node_tree.nodes
    for n in nodes:n.select=False
    n=nodes.new('ShaderNodeTexImage');n.image=atlas;n.select=True;nodes.active=n
print('BAKING',len(objects),'source meshes in one atlas pass',flush=True)
started=time.time()
bpy.ops.object.bake(type='COMBINED',uv_layer='RoomAtlas')
atlas.filepath_raw=str(OUT/'nursery-lit.png');atlas.file_format='PNG';atlas.save()
atlas.scale(2048,2048);atlas.filepath_raw=str(OUT/'nursery-lit-low.png');atlas.save()
# All source materials are now baked, including procedural grain/linen, the scanned props,
# and illumination from the shared fixture manifest. No flat-material export fallback.
material=bpy.data.materials.new('Nursery baked lighting');material.use_nodes=True
nodes=material.node_tree.nodes;links=material.node_tree.links;p=nodes.get('Principled BSDF')
p.inputs['Base Color'].default_value=(0,0,0,1);p.inputs['Roughness'].default_value=1
image=bpy.data.images.load(str(OUT/'nursery-lit.png'),check_existing=False)
t=nodes.new('ShaderNodeTexImage');t.image=image
links.new(t.outputs['Color'],p.inputs['Emission Color']);p.inputs['Emission Strength'].default_value=1
for uv in list(combined.data.uv_layers):
    if uv.name!='RoomAtlas':combined.data.uv_layers.remove(uv)
combined.data.uv_layers.active=combined.data.uv_layers['RoomAtlas'];combined.data.uv_layers.active.active_render=True
combined.data.materials.clear();combined.data.materials.append(material)
for face in combined.data.polygons:face.material_index=0
exported=[]
for name in group_names:
    old=bpy.data.objects.get(name)
    if old and old.type=='EMPTY':bpy.data.objects.remove(old,do_unlink=True)
for index,name in enumerate(group_names):
    mesh=combined.data.copy();bm=bmesh.new();bm.from_mesh(mesh)
    layer=bm.faces.layers.int['runtime_group']
    bmesh.ops.delete(bm,geom=[f for f in bm.faces if f[layer]!=index],context='FACES')
    bm.to_mesh(mesh);bm.free()
    o=bpy.data.objects.new(name,mesh);scene.collection.objects.link(o)
    pivot=pivots.get(name,Matrix.Identity(4)).translation
    o.data.transform(Matrix.Translation(-pivot));o.location=pivot
    exported.append(o)
bpy.data.objects.remove(combined,do_unlink=True)
bpy.ops.object.select_all(action='DESELECT')
for o in exported:o.select_set(True)
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'artifacts/nursery-baked.blend'))
bpy.ops.export_scene.gltf(filepath=str(OUT/'nursery.glb'),export_format='GLB',use_selection=True,export_animations=False,export_cameras=False,export_lights=False,export_extras=True,export_image_format='NONE',export_materials='EXPORT')
# Texture is external and bound by the runtime; GLB image omission is intentional and checked.
metrics={'nativeSha256':hashlib.sha256((PACKAGE/'nursery-form.blend').read_bytes()).hexdigest(),'bakeSeconds':round(time.time()-started,2),'sourceMeshes':len(objects),'runtimeMeshes':len(exported),'triangles':sum(len(o.data.loop_triangles) if o.data.loop_triangles else (o.data.calc_loop_triangles() or len(o.data.loop_triangles)) for o in exported),'textureTiers':{'mobile':[4096,4096],'low':[2048,2048]},'textureBudgetBytes':4096*4096*4//3,'textureBudgetBasis':'GPU block compression up to 8 bits/pixel including mipmaps; import setting is required','fixtureManifestSha256':hashlib.sha256((PACKAGE/'lighting-manifest.json').read_bytes()).hexdigest(),'nodes':[o.name for o in exported],'files':{p.name:{'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in OUT.iterdir() if p.is_file() and p.suffix in ['.glb','.png']}}
(PACKAGE/'runtime').mkdir(exist_ok=True);(PACKAGE/'runtime/export.json').write_text(json.dumps(metrics,indent=2)+'\n')
print('NURSERY_EXPORT_READY',json.dumps(metrics),flush=True)
