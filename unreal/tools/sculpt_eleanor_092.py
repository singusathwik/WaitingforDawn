"""Original mourning apparition geometry over the credited animated Rosswet armature.
Run with Blender 4.3.2. Does not edit the legacy source or gameplay collision.
"""
import bpy, bmesh, math, random, json, hashlib
from pathlib import Path
from mathutils import Vector
R=random.Random(2192)
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'design/eleanor-092'; OUT.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(ROOT/'assets/models/wraith.glb'))
rig=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE')
rig.data.pose_position='REST'
for o in list(bpy.context.scene.objects):
    if o.type=='MESH' and o.name.startswith('Icosphere'):bpy.data.objects.remove(o,do_unlink=True)
body=next(o for o in bpy.context.scene.objects if o.type=='MESH')

def material(name,color,rough=.8):
    m=bpy.data.materials.new(name);m.use_nodes=True
    p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1);p.inputs['Roughness'].default_value=rough
    return m
skin=material('M_DreadFace',(.40,.42,.37),.88)
cloth=material('M_DreadCloth',(.15,.14,.12),.97)
hair=material('M_DreadHair',(.008,.010,.012),.57)
hair.node_tree.nodes['Principled BSDF'].inputs['Specular IOR Level'].default_value=.22
socket=material('M_DreadCavity',(.002,.0015,.0025),.92)
ivory=material('M_DreadIvory',(.36,.32,.22),.65)
eye=material('M_DreadEye',(.22,.24,.20),.31)
rust=material('M_DreadRust',(.11,.043,.018),.76)

def procedural(m,colors,scale):
    n=m.node_tree.nodes;l=m.node_tree.links;p=n.get('Principled BSDF')
    tex=n.new('ShaderNodeTexNoise');tex.inputs['Scale'].default_value=scale;tex.inputs['Detail'].default_value=5;tex.inputs['Roughness'].default_value=.78
    ramp=n.new('ShaderNodeValToRGB')
    ramp.color_ramp.elements[0].position=.27;ramp.color_ramp.elements[0].color=(*colors[0],1)
    ramp.color_ramp.elements[1].position=.74;ramp.color_ramp.elements[1].color=(*colors[1],1)
    mid=ramp.color_ramp.elements.new(.48);mid.color=(*colors[2],1)
    l.new(tex.outputs['Fac'],ramp.inputs[0]);l.new(ramp.outputs['Color'],p.inputs['Base Color'])
    fine=n.new('ShaderNodeTexNoise');fine.inputs['Scale'].default_value=145;fine.inputs['Detail'].default_value=3
    bump=n.new('ShaderNodeBump');bump.inputs['Strength'].default_value=.22;bump.inputs['Distance'].default_value=.035
    l.new(fine.outputs['Fac'],bump.inputs['Height']);l.new(bump.outputs['Normal'],p.inputs['Normal'])
procedural(skin,[(.095,.075,.080),(.61,.62,.52),(.29,.32,.29)],7)
procedural(cloth,[(.022,.018,.014),(.27,.25,.20),(.10,.095,.08)],11)

def bind(o,bone='head',weights=None):
    if weights is None:
        g=o.vertex_groups.new(name=bone);g.add(list(range(len(o.data.vertices))),1,'REPLACE')
    else:
        for i,p in enumerate(o.data.vertices):
            for name,w in weights(p.co).items():
                if w<=0:continue
                g=o.vertex_groups.get(name) or o.vertex_groups.new(name=name);g.add([i],w,'REPLACE')
    mod=o.modifiers.new('Preserved character rig','ARMATURE');mod.object=rig
    o.parent=rig;o.matrix_parent_inverse=rig.matrix_world.inverted()
    return o

def mesh(name,verts,faces,mat,bone='head',weights=None,uvs=None):
    d=bpy.data.meshes.new(name);d.from_pydata(verts,[],faces);d.update()
    o=bpy.data.objects.new(name,d);bpy.context.collection.objects.link(o);d.materials.append(mat)
    for f in d.polygons:f.use_smooth=True
    if uvs:
        uv=d.uv_layers.new()
        for p in d.polygons:
            for li in p.loop_indices:uv.data[li].uv=uvs[d.loops[li].vertex_index]
    return bind(o,bone,weights)

def ellipsoid(name,center,scale,mat,bone='head',segments=24,rings=16):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments,ring_count=rings,location=center)
    o=bpy.context.object;o.name=name;o.scale=scale
    bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    o.data.materials.append(mat)
    for f in o.data.polygons:f.use_smooth=True
    return bind(o,bone)

def tube(name,points,radii,mat,bone='head',sides=8,weights=None):
    vv=[];ff=[];uv=[]
    for i,p in enumerate(points):
        p=Vector(p);t=(Vector(points[min(i+1,len(points)-1)])-Vector(points[max(0,i-1)])).normalized()
        ref=Vector((0,1,0)) if abs(t.y)<.9 else Vector((1,0,0))
        a=t.cross(ref).normalized();b=t.cross(a).normalized()
        rx,ry=radii[i] if isinstance(radii[i],tuple) else (radii[i],radii[i])
        for j in range(sides+1):
            ang=j/sides*math.tau;vv.append(p+a*math.cos(ang)*rx+b*math.sin(ang)*ry);uv.append((j/sides,i/(len(points)-1)))
    for i in range(len(points)-1):
        for j in range(sides):
            k=i*(sides+1)+j;ff.append((k,k+1,k+sides+2,k+sides+1))
    return mesh(name,vv,ff,mat,bone,weights,uv)

# Retain only the original arms/hands; the original skull, torso and legs are replaced.
bm=bmesh.new();bm.from_mesh(body.data);bm.verts.ensure_lookup_table();deform=bm.verts.layers.deform.active
arm_groups={g.index:g.name for g in body.vertex_groups if any(s in g.name for s in ('upper_arm','forearm','hand','finger','palm','thumb'))}
remove=[v for v in bm.verts if sum(w for i,w in v[deform].items() if i in arm_groups)<.55]
bmesh.ops.delete(bm,geom=remove,context='VERTS');bm.to_mesh(body.data);bm.free();body.name='Eleanor_gaunt_arms'
# Narrow the old muscular arms without moving any joints or changing bind transforms.
inv=body.matrix_world.inverted()
for v in body.data.vertices:
    p=body.matrix_world@v.co
    candidates=[(g.weight,body.vertex_groups[g.group].name) for g in v.groups if body.vertex_groups[g.group].name.startswith(('upper_arm','forearm'))]
    if not candidates:continue
    weight,bone=max(candidates);b=rig.data.bones[bone];start=rig.matrix_world@b.head_local
    end=rig.matrix_world@(rig.data.bones['forearm'+bone[-2:]].head_local if bone.startswith('upper_arm') else rig.data.bones['hand'+bone[-2:]].head_local)
    axis=end-start;t=max(0,min(1,(p-start).dot(axis)/axis.length_squared));q=start+t*axis
    v.co=inv@(q+(p-q)*(1-.30*weight))

# A continuous facial shell with actual openings, sculpted cheeks, nose and asymmetric jaw.
vv=[];ff=[];uv=[];cols=96;rows=64
for i in range(rows+1):
    phi=math.pi*i/rows
    for j in range(cols+1):
        theta=math.tau*j/cols;x=.54*math.sin(phi)*math.cos(theta);z=7.65+.91*math.cos(phi)
        x*=1-.24*max(0,(7.5-z)/.75)
        y=-.04+.49*math.sin(phi)*math.sin(theta);front=max(0,-math.sin(theta))**6
        gauss=lambda cx,cz,sx,sz:math.exp(-((x-cx)/sx)**2-((z-cz)/sz)**2)
        y+=front*(.17*(gauss(-.235,7.84,.145,.14)+gauss(.235,7.81,.145,.14))+.09*gauss(0,7.28,.26,.18)-.23*gauss(0,7.61,.085,.22)-.09*gauss(0,7.51,.12,.075)-.065*(gauss(-.36,7.49,.17,.14)+gauss(.36,7.49,.17,.14))-.045*(gauss(-.21,8.00,.19,.055)+gauss(.21,7.97,.19,.055)))
        x+=front*.035*max(0,(7.35-z)/.6)
        vv.append((x,y,z));uv.append((j/cols,1-i/rows))
for i in range(rows):
    for j in range(cols):
        k=i*(cols+1)+j;ids=(k,k+1,k+cols+2,k+cols+1);c=sum((Vector(vv[a])for a in ids),Vector())/4
        mouth=((c.x-.015)/.17)**2+((c.z-7.28-.12*c.x)/.055)**2<1
        eyes=any(((c.x-s*.235)/.125)**2+((c.z-(7.84 if s<0 else 7.81))/.06)**2<1 for s in(-1,1))
        if c.y<-.14 and (mouth or eyes):continue
        ff.append(ids[::-1])  # outward-facing surface; Unreal culls inward faces
face=mesh('Eleanor_sculpted_face',vv,ff,skin,uvs=uv)
# Round the cut boundaries while retaining UVs, the sculpted surface and head weighting.
bm=bmesh.new();bm.from_mesh(face.data)
edges=[v for v in bm.verts if v.is_boundary]
for repeat in range(8):
    updates={v:sum((e.other_vert(v).co for e in v.link_edges if e.is_boundary),Vector())/sum(e.is_boundary for e in v.link_edges) for v in edges if any(e.is_boundary for e in v.link_edges)}
    for v,p in updates.items():v.co=v.co.lerp(p,.58)
bm.to_mesh(face.data);bm.free()
face.data.update()
front_normals=[p.normal.y for p in face.data.polygons if p.center.y<-.2]
assert front_normals and sum(front_normals)<0, 'Face must point outward for Unreal backface culling'
# Project the original generated facial texture onto the sculpture, then bake it
# into the original spherical UV layout for Unreal. No runtime billboard is used.
projection=face.data.uv_layers.new(name='FaceProjection')
def face_v(z):
    landmarks=[(6.74,.04),(7.28,.26),(7.51,.40),(7.84,.593),(8.56,.97)]
    for (za,va),(zb,vb) in zip(landmarks,landmarks[1:]):
        if z<=zb:return va+(z-za)/(zb-za)*(vb-va)
    return .97
for loop in face.data.loops:
    x,y,z=face.data.vertices[loop.vertex_index].co
    projection.data[loop.index].uv=(.5+x*.69,face_v(z))
face.data.uv_layers.active_index=0;face.data.uv_layers[0].active_render=True
n=skin.node_tree.nodes;l=skin.node_tree.links;p=n.get('Principled BSDF')
projected=n.new('ShaderNodeTexImage');projected.image=bpy.data.images.load(str(OUT/'face_projection.png'));projected.image.pack()
uvmap=n.new('ShaderNodeUVMap');uvmap.uv_map=projection.name;l.new(uvmap.outputs['UV'],projected.inputs['Vector'])
tone=n.new('ShaderNodeHueSaturation');tone.inputs['Saturation'].default_value=.43;tone.inputs['Value'].default_value=.80
l.new(projected.outputs['Color'],tone.inputs['Color']);l.new(tone.outputs['Color'],p.inputs['Base Color'])
neck=tube('High ragged collar',[(0,.09,6.55),(0,.10,6.91),(0,.08,7.15)],[.23,.19,.25],cloth,'neck',20)
for s in(-1,1):
    ellipsoid('Recessed eye socket', (s*.235,.15,7.84 if s<0 else 7.81),(.15,.13,.09),socket)
    ellipsoid('Small pale eye', (s*.235,.003,7.83 if s<0 else 7.80),(.010,.009,.007),eye,segments=12,rings=8)
ellipsoid('Deep mouth cavity',(.015,.16,7.28),(.23,.17,.12),socket)
# A crooked, slightly parted grimace; uneven teeth sit behind the facial shell.
for upper in(True,False):
    for i in range(9):
        if (upper and i==1) or (not upper and i==5):continue
        x=(i-4)*.031;z=(7.315 if upper else 7.245)+.12*x+R.uniform(-.006,.006);length=R.uniform(.018,.035)
        tube('Uneven worn tooth',[(x,-.045,z),(x+R.uniform(-.005,.005),-.05,z+(-length if upper else length))],[.013,.010],ivory,sides=6)

def gown_weights(p):
    z=p.z
    if z>5.7:return {'ribs':1}
    if z>4.7:
        t=z-4.7;return {'ribs':t,'spine':1-t}
    if z>4:
        t=(z-4)/.7;return {'spine':t,'hips':1-t}
    return {'hips':1}

def garment(name,rings,mat,columns=72,open_seam=False):
    vv=[];ff=[];uv=[]
    for i,(z,rx,ry,cy) in enumerate(rings):
        for j in range(columns+1):
            a=math.tau*j/columns;pleat=1+.045*math.cos(j*2.2)+.016*math.sin(j*5.1)
            height=z
            if i==len(rings)-1:height-=.32*(.5+.5*math.sin(j*3.37))+.12*math.cos(j*1.3)
            vv.append((math.cos(a)*rx*pleat,cy+math.sin(a)*ry*pleat,height));uv.append((j/columns,i/(len(rings)-1)))
    for i in range(len(rings)-1):
        for j in range(columns):
            if i>=len(rings)-2 and j%13 in (3,4):continue
            if open_seam and i>4 and abs(j-51)<(i-4)*.6:continue
            k=i*(columns+1)+j;ff.append((k,k+1,k+columns+2,k+columns+1))
    return mesh(name,vv,ff,mat,weights=gown_weights,uvs=uv)
dress=garment('Layered ragged nightdress',[(6.90,.26,.24,.13),(6.70,.80,.44,.18),(6.45,1.10,.53,.23),(5.80,.92,.48,.12),(5.05,.77,.43,.10),(4.20,.78,.46,.07),(3.6,.89,.55,.07),(2.6,1.02,.64,.07),(1.6,1.13,.70,.07),(.45,1.24,.75,.07)],cloth,open_seam=True)
garment('Torn underskirt',[(3.9,.80,.47,.08),(2.6,.92,.57,.08),(1.3,1.02,.65,.08),(.3,1.08,.69,.08)],cloth,columns=64)
for side in('L','R'):
    a=rig.matrix_world@rig.data.bones['upper_arm.'+side].head_local
    b=rig.matrix_world@rig.data.bones['forearm.'+side].head_local
    ellipsoid('Rounded sleeve shoulder '+side,a,(.31,.29,.24),cloth,'upper_arm.'+side,24,16)
    tube('Ragged sleeve '+side,[a,a.lerp(b,.35),a.lerp(b,.75),a.lerp(b,.90)],[.29,.28,.24,.26],cloth,'upper_arm.'+side,24)
    # Hooked nails are bound to the existing articulated finger bones.
    for base in('finger_index.01.','finger_middle.01.','finger_ring.01.','finger_pinky.01.','thumb.02.'):
        bone=rig.data.bones.get(base+side)
        if not bone:continue
        p=rig.matrix_world@bone.head_local;t=(rig.matrix_world@bone.tail_local-p).normalized()
        tip=p+t*.30
        tube('Tapered black nail '+base+side,[tip,tip+t*.16,tip+t*.30+Vector((0,-.06,0))],[.035,.026,.001],socket,base+side,6)

# Opaque, tapered hair ribbons: wet clumps with small irregular gaps, mobile-safe.
vv=[];ff=[]
for n in range(160):
    theta=R.uniform(0,math.tau)
    # Frame the face, leaving the nose and mouth readable from corridor distance.
    if math.sin(theta)<-.70:theta=R.choice([math.pi*1.22,math.pi*1.78])+R.uniform(-.07,.07)
    length=R.uniform(1.2,2.6);width=R.uniform(.014,.032)
    radial=Vector((math.cos(theta),math.sin(theta),0));across=Vector((-math.sin(theta),math.cos(theta),0));base=len(vv)
    for j in range(14):
        t=max(0,(j-4)/9);phi=.10+min(1,j/4)*1.23
        radius=.61*math.sin(phi)+.10*math.sin(t*math.pi)
        center=radial*radius+Vector((.018*math.sin(t*8+n),-.015,7.65+1.02*math.cos(phi)-length*t))
        w=width*(1-.9*t**2)
        vv.extend([center-across*w,center+radial*.025,center+across*w])
    for j in range(13):
        k=base+j*3;ff.extend([(k,k+3,k+4,k+1),(k+1,k+4,k+5,k+2)])
mesh('Wet layered hair',vv,ff,hair)
# Scalp cap closes gaps above the strands, stopping above the eye sockets.
vv=[];ff=[]
for i in range(19):
    for j in range(65):
        theta=math.tau*j/64;limit=1.08+.12*math.cos(theta)+.06*math.sin(theta*7) if math.sin(theta)<-.5 else 2.05
        phi=(i/18)*limit;ridge=1+.025*math.cos(theta*37+phi*.6)+.012*math.sin(theta*81)
        vv.append((.59*math.sin(phi)*math.cos(theta)*ridge,-.055+.55*math.sin(phi)*math.sin(theta)*ridge,7.65+.99*math.cos(phi)))
for i in range(18):
    for j in range(64):k=i*65+j;ff.append((k,k+1,k+66,k+65))
mesh('Parted hair scalp',vv,ff,hair)
tube('Keepsake cord',[(-.24,-.29,6.62),(-.22,-.43,6.18),(0,-.50,5.96),(.22,-.43,6.18),(.24,-.29,6.62)],[.012]*5,socket,'ribs',6)
ellipsoid('Weathered keepsake', (0,-.52,5.91),(.085,.028,.12),rust,'ribs',16,12)

# Add the same single master root as the shipped mesh; animation data is retained.
bpy.ops.object.select_all(action='DESELECT');rig.select_set(True);bpy.context.view_layer.objects.active=rig
bpy.ops.object.mode_set(mode='EDIT')
roots=[b for b in rig.data.edit_bones if b.parent is None]
master=rig.data.edit_bones.new('DawnRoot');master.head=(0,0,0);master.tail=(0,0,.2)
for b in roots:b.parent=master
bpy.ops.object.mode_set(mode='OBJECT')

# Bake the original procedural face and garment color into portable maps.
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=8
scene.render.bake.use_pass_direct=False;scene.render.bake.use_pass_indirect=False;scene.render.bake.use_pass_color=True;scene.render.bake.margin=12
for mat,objects,name in [(skin,[face],'face_albedo'),(cloth,[dress],'cloth_albedo')]:
    image=bpy.data.images.new(name,width=1024,height=1024,alpha=False)
    target=mat.node_tree.nodes.new('ShaderNodeTexImage');target.image=image;mat.node_tree.nodes.active=target
    bpy.ops.object.select_all(action='DESELECT')
    for o in objects:o.select_set(True)
    bpy.context.view_layer.objects.active=objects[0]
    bpy.ops.object.bake(type='DIFFUSE')
    image.filepath_raw=str(OUT/(name+'.png'));image.file_format='PNG';image.save();image.pack()
    mat.node_tree.links.new(target.outputs['Color'],mat.node_tree.nodes['Principled BSDF'].inputs['Base Color'])

for m in (skin,cloth,hair):m.use_backface_culling=False
rig.data.pose_position='POSE';rig.animation_data.action=None
# Export mesh only against the existing compatible Unreal skeleton and repaired clips.
bpy.ops.object.select_all(action='DESELECT')
objects=[o for o in scene.objects if o.type in('MESH','ARMATURE')]
for o in objects:o.select_set(True)
fbx=OUT/'SK_EleanorDread.fbx'
bpy.ops.export_scene.fbx(filepath=str(fbx),use_selection=True,object_types={'MESH','ARMATURE'},apply_unit_scale=True,apply_scale_options='FBX_SCALE_UNITS',axis_forward='-Y',axis_up='Z',bake_anim=False,add_leaf_bones=False,path_mode='COPY',embed_textures=True)
meshes=[o for o in objects if o.type=='MESH'];triangles=0
for o in meshes:o.data.calc_loop_triangles();triangles+=len(o.data.loop_triangles)
assert triangles<35000,triangles
report={'source':'assets/models/wraith.glb','source_sha256':hashlib.sha256((ROOT/'assets/models/wraith.glb').read_bytes()).hexdigest(),'fbx':fbx.name,'sha256':hashlib.sha256(fbx.read_bytes()).hexdigest(),'triangles':triangles,'mesh_objects':len(meshes),'bones':len(rig.data.bones),'root_bones':[b.name for b in rig.data.bones if b.parent is None],'maps':[{'file':n+'.png','sha256':hashlib.sha256((OUT/(n+'.png')).read_bytes()).hexdigest()}for n in('face_albedo','cloth_albedo')],'provenance':'Original face, hair, clothing, nails and keepsake. Credited Rosswet armature, arm geometry and animations retained; CC BY 3.0, see ASSETS.md.'}
(OUT/'manifest.json').write_text(json.dumps(report,indent=2)+'\n')

# A neutral studio inspection render, followed by a face detail. Not runtime proof.
scene.render.engine='CYCLES';scene.cycles.samples=32;scene.render.resolution_x=1100;scene.render.resolution_y=1100;scene.render.resolution_percentage=100
scene.world=bpy.data.worlds.new('Inspection world');scene.world.color=(.035,.035,.035)
def point(obj,target):obj.rotation_euler=(Vector(target)-obj.location).to_track_quat('-Z','Y').to_euler()
for name,loc,power,size,color in [('Cool key',(-5,-7,11),1800,5,(.72,.84,1)),('Warm rim',(5,3,9),2400,4,(1,.66,.35)),('Soft face',(2,-5,6),700,4,(.76,.84,.82))]:
    d=bpy.data.lights.new(name,'AREA');d.energy=power;d.shape='DISK';d.size=size;d.color=color;o=bpy.data.objects.new(name,d);scene.collection.objects.link(o);o.location=loc;point(o,(0,0,5))
camera=bpy.data.cameras.new('Inspection camera');cam=bpy.data.objects.new('Inspection camera',camera);scene.collection.objects.link(cam);scene.camera=cam
cam.location=(10,-22,8);point(cam,(0,0,4.4));camera.type='ORTHO';camera.ortho_scale=10
bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'Eleanor-Mourning-092.blend'))
scene.render.filepath=str(OUT/'blender-full.png');bpy.ops.render.render(write_still=True)
cam.location=(1,-7,8.2);point(cam,(0,-.1,7.65));camera.ortho_scale=2.7
scene.render.filepath=str(OUT/'blender-face.png');bpy.ops.render.render(write_still=True)
print('ELEANOR_092_READY',json.dumps(report))
