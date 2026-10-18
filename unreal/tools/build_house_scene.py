"""Executed by build_map.py after verified imports. All geometry becomes real Unreal assets."""
from house_layout import layout as house_layout, verify as verify_house
import math,random
random.seed(91)
house=house_layout();print('HOUSE_GRAPH',verify_house())
if not LEVELS.new_level(MAP):raise RuntimeError('Cannot create house map')
cube=load('/Engine/BasicShapes/Cube.Cube');sphere=load('/Engine/BasicShapes/Sphere.Sphere');cylinder=load('/Engine/BasicShapes/Cylinder.Cylinder')
interactive=u.load_class(None,'/Script/WaitingForDawn.WDInteractable');ghost_class=u.load_class(None,'/Script/WaitingForDawn.WDGhost')
def spawn(cls,label,p,yaw=0):
    a=ACTORS.spawn_actor_from_class(cls,u.Vector(*p),u.Rotator(yaw=yaw));a.set_actor_label(label);a.set_editor_property('tags',[u.Name(label)]);return a
def flat_material(name,color,metal=0,rough=.85,emissive=False):
    path='/Game/Imported/'+name
    if u.EditorAssetLibrary.does_asset_exist(path):return load(path)
    m=ASSET_TOOLS.create_asset(name,'/Game/Imported',u.Material,u.MaterialFactoryNew())
    v=u.MaterialEditingLibrary.create_material_expression(m,u.MaterialExpressionConstant3Vector);v.set_editor_property('constant',u.LinearColor(*color))
    u.MaterialEditingLibrary.connect_material_property(v,'',u.MaterialProperty.MP_EMISSIVE_COLOR if emissive else u.MaterialProperty.MP_BASE_COLOR)
    for prop,value in [(u.MaterialProperty.MP_ROUGHNESS,rough),(u.MaterialProperty.MP_METALLIC,metal)]:
        c=u.MaterialEditingLibrary.create_material_expression(m,u.MaterialExpressionConstant);c.set_editor_property('r',value);u.MaterialEditingLibrary.connect_material_property(c,'',prop)
    u.MaterialEditingLibrary.recompile_material(m);u.EditorAssetLibrary.save_loaded_asset(m);return m
materials['stone']=flat_material('M_basement',(.065,.071,.065));materials['brass']=flat_material('M_tarnished',(.22,.14,.045),.7,.45)
materials['dark']=flat_material('M_black',(.013,.016,.019));materials['paper']=flat_material('M_paper',(.48,.39,.23))
materials['lamp']=flat_material('M_lamp_glow',(2,1.1,.45),emissive=True)
def character_material(name,path,tint,two_sided=False):
    asset='/Game/Imported/'+name
    if u.EditorAssetLibrary.does_asset_exist(asset):return load(asset)
    m=ASSET_TOOLS.create_asset(name,'/Game/Imported',u.Material,u.MaterialFactoryNew());m.set_editor_property('two_sided',two_sided)
    tex=u.MaterialEditingLibrary.create_material_expression(m,u.MaterialExpressionTextureSample);tex.set_editor_property('texture',import_texture(path,name+'_texture'))
    color=u.MaterialEditingLibrary.create_material_expression(m,u.MaterialExpressionConstant3Vector);color.set_editor_property('constant',u.LinearColor(*tint))
    mul=u.MaterialEditingLibrary.create_material_expression(m,u.MaterialExpressionMultiply);u.MaterialEditingLibrary.connect_material_expressions(tex,'RGB',mul,'A');u.MaterialEditingLibrary.connect_material_expressions(color,'',mul,'B');u.MaterialEditingLibrary.connect_material_property(mul,'',u.MaterialProperty.MP_BASE_COLOR)
    rough=u.MaterialEditingLibrary.create_material_expression(m,u.MaterialExpressionConstant);rough.set_editor_property('r',.92);u.MaterialEditingLibrary.connect_material_property(rough,'',u.MaterialProperty.MP_ROUGHNESS)
    u.MaterialEditingLibrary.recompile_material(m);u.EditorAssetLibrary.save_loaded_asset(m);return m
skin=character_material('M_EleanorSkin','assets/models/mourning_ghost_new_thin_zombie.png',(.65,.72,.79))
cloth=character_material('M_MourningFabric','assets/textures/quatrefoil_jacquard_fabric/diff.jpg',(.08,.09,.11),True)
from mourning_material import apply as apply_mourning_material
apply_mourning_material()
for material in (skin,cloth):
    material.set_editor_property('used_with_skeletal_mesh',True);u.MaterialEditingLibrary.recompile_material(material);u.EditorAssetLibrary.save_loaded_asset(material)
ghost_materials=list(ghost_mesh.get_editor_property('materials'))
for slot,material in enumerate(ghost_materials):
    slot_name=str(material.get_editor_property('imported_material_slot_name')).lower()
    material.set_editor_property('material_interface',cloth if 'cloth' in slot_name else skin)
ghost_mesh.set_editor_property('materials',ghost_materials)
# World-space tiling prevents 30-metre floors from stretching a single texture across the house.
def world_material(name,folder):
    path='/Game/Imported/'+name
    if u.EditorAssetLibrary.does_asset_exist(path):return load(path)
    m=ASSET_TOOLS.create_asset(name,'/Game/Imported',u.Material,u.MaterialFactoryNew())
    pos=u.MaterialEditingLibrary.create_material_expression(m,u.MaterialExpressionWorldPosition)
    mask=u.MaterialEditingLibrary.create_material_expression(m,u.MaterialExpressionComponentMask);mask.set_editor_property('r',True);mask.set_editor_property('g',True)
    assert u.MaterialEditingLibrary.connect_material_expressions(pos,'',mask,'')
    div=u.MaterialEditingLibrary.create_material_expression(m,u.MaterialExpressionDivide);div.set_editor_property('const_b',180.0);u.MaterialEditingLibrary.connect_material_expressions(mask,'',div,'A')
    for suffix,prop in [('diff',u.MaterialProperty.MP_BASE_COLOR),('rough',u.MaterialProperty.MP_ROUGHNESS)]:
        t=import_texture(f'assets/textures/{folder}/{suffix}.jpg',name+'_'+suffix)
        tex=u.MaterialEditingLibrary.create_material_expression(m,u.MaterialExpressionTextureSample);tex.set_editor_property('texture',t)
        u.MaterialEditingLibrary.connect_material_expressions(div,'',tex,'Coordinates');u.MaterialEditingLibrary.connect_material_property(tex,'RGB' if suffix=='diff' else 'R',prop)
    u.MaterialEditingLibrary.recompile_material(m);u.EditorAssetLibrary.save_loaded_asset(m);return m
materials['floor']=world_material('M_house_floor','old_wooden_floor_01')
materials['carpet']=world_material('M_house_carpet','quatrefoil_jacquard_fabric')
# Vertical world-space projection selects XZ or YZ from the surface normal.
# This keeps wallpaper at a physical scale on long walls instead of stretching cube UVs.
wall_path='/Game/Imported/M_house_wall'
if not u.EditorAssetLibrary.does_asset_exist(wall_path):
    m=ASSET_TOOLS.create_asset('M_house_wall','/Game/Imported',u.Material,u.MaterialFactoryNew())
    pos=u.MaterialEditingLibrary.create_material_expression(m,u.MaterialExpressionWorldPosition)
    norm=u.MaterialEditingLibrary.create_material_expression(m,u.MaterialExpressionVertexNormalWS)
    alpha=u.MaterialEditingLibrary.create_material_expression(m,u.MaterialExpressionComponentMask);alpha.set_editor_property('r',True);assert u.MaterialEditingLibrary.connect_material_expressions(norm,'',alpha,'')
    absolute=u.MaterialEditingLibrary.create_material_expression(m,u.MaterialExpressionAbs);u.MaterialEditingLibrary.connect_material_expressions(alpha,'',absolute,'Input')
    lerp=u.MaterialEditingLibrary.create_material_expression(m,u.MaterialExpressionLinearInterpolate);u.MaterialEditingLibrary.connect_material_expressions(absolute,'',lerp,'Alpha')
    for first,slot in [('r','A'),('g','B')]:
        mask=u.MaterialEditingLibrary.create_material_expression(m,u.MaterialExpressionComponentMask);mask.set_editor_property(first,True);mask.set_editor_property('b',True);assert u.MaterialEditingLibrary.connect_material_expressions(pos,'',mask,'');u.MaterialEditingLibrary.connect_material_expressions(mask,'',lerp,slot)
    div=u.MaterialEditingLibrary.create_material_expression(m,u.MaterialExpressionDivide);div.set_editor_property('const_b',180.0);u.MaterialEditingLibrary.connect_material_expressions(lerp,'',div,'A')
    for suffix,propname in [('diff',u.MaterialProperty.MP_BASE_COLOR),('rough',u.MaterialProperty.MP_ROUGHNESS)]:
        tex=u.MaterialEditingLibrary.create_material_expression(m,u.MaterialExpressionTextureSample);tex.set_editor_property('texture',import_texture('assets/textures/decrepit_wallpaper/'+suffix+'.jpg','Wall_'+suffix));u.MaterialEditingLibrary.connect_material_expressions(div,'',tex,'Coordinates');u.MaterialEditingLibrary.connect_material_property(tex,'RGB' if suffix=='diff' else 'R',propname)
    u.MaterialEditingLibrary.recompile_material(m);u.EditorAssetLibrary.save_loaded_asset(m)
materials['plaster']=load(wall_path)
def box(name,p,size,mat='wood',collision=True,mesh=None,yaw=0,pitch=0):
    a=spawn(u.StaticMeshActor,name,p,yaw);c=a.static_mesh_component;c.set_static_mesh(mesh or cube)
    a.set_actor_scale3d(u.Vector(*(s/100 for s in size)));c.set_material(0,materials[mat]);c.set_collision_profile_name('BlockAll' if collision else 'NoCollision')
    if pitch:a.set_actor_rotation(u.Rotator(yaw=yaw,pitch=pitch),False)
    return a
def prop(asset,p,yaw=0,scale=1,collision=True,label=None):
    a=spawn(u.StaticMeshActor,label or asset,p,yaw);a.static_mesh_component.set_static_mesh(meshes[asset]);a.set_actor_scale3d(u.Vector(scale,scale,scale))
    a.static_mesh_component.set_collision_profile_name('BlockAll' if collision else 'NoCollision');return a
# FBX's basic material translation loses some glTF texture nodes. Restore the
# verified oak map on wood slots rather than accepting untextured white furniture.
for mesh in meshes.values():
    for slot in range(mesh.get_num_sections(0)):
        material=mesh.get_material(slot)
        if material and any(n in material.get_name().lower() for n in ('worn_oak','aged_walnut')):mesh.set_material(slot,materials['wood'])
for b in house['boxes']:
    a=box(b['name'],b['centre'],b['size'],b['material'],True,pitch=b.get('pitch',0))
    if not b['visible']:a.static_mesh_component.set_visibility(False)
    a.set_editor_property('tags',[u.Name(b['role'])])
# Skirting and picture rails give the large rooms a readable human scale.
for r in house['rooms']:
    for height in (12,232):
        box('RoomMoulding',[r['x'],-265 if r['row']==0 else 495,r['z']+height],[1370,7,12],'wood',False)
        box('OuterMoulding',[r['side']*1590,r['y'],r['z']+height],[7,860 if r['row']==0 else 735,12],'wood',False)
# An authored exterior surrounds the playable rooms; nothing opens into a void.
for sx in (-1,1):box('SlateRoof',[sx*800,0,1330],[1800,2580,38],'dark',False,pitch=sx*25)
for level in (0,1,2):
    for x in (-1250,-650,650,1250):
        if level==0 and x>0:continue
        z=level*320+170
        box('ShutteredWindow',[x,-1223,z],[120,8,160],'dark',False)
        for dx in (-64,64):box('WindowFrame',[x+dx,-1230,z],[10,16,180],'wood',False)
        for dz in (-85,85):box('WindowSill',[x,-1230,z+dz],[145,22,10],'wood',False)
        box('WindowCross',[x,-1232,z],[6,12,165],'wood',False)
        box('WindowCross',[x,-1232,z],[130,12,6],'wood',False)
        for dz in (-45,32):box('BoardedWindow',[x,-1244,z+dz],[160,8,16],'wood',False,pitch=7)
box('FrontDoor',[0,-1225,120],[145,16,240],'wood',False)
for sx in (-1,1):box('PorchPost',[sx*160,-1510,140],[22,22,280],'wood',False)
box('PorchRoof',[0,-1380,290],[380,400,35],'dark',False)
box('PorchPath',[0,-1610,2],[400,800,6],'stone',False)
def action(name,p,kind,mesh=None,yaw=0,scale=1,required='',needs=()):
    a=spawn(interactive,name,p,yaw);a.set_editor_property('display_name',u.Text(name.replace('_',' ')));a.set_editor_property('kind',kind)
    if mesh:a.mesh.set_static_mesh(mesh)
    a.mesh.set_relative_scale3d(u.Vector(scale,scale,scale))
    a.set_editor_property('required_key',u.Name(required));a.set_editor_property('required_keys',[u.Name(n) for n in needs]);a.set_editor_property('interaction_sound',audio['door'])
    return a
doors={};drawers={};hides=[];key_metadata=[]
for r in house['rooms']:
    i,x,y,z=r['id'],r['x'],r['y'],r['z'];side=r['side']
    # Wide manor doorways retain enough clearance after navmesh voxel erosion.
    door_y=-760 if r['row']==0 else 140
    door=action('Door_'+r['name'],[side*200,door_y-75,z],u.WDInteraction.DOOR,meshes['room_door'],required=r['lock'])
    door.mesh.set_relative_scale3d(u.Vector(150/110,1,1))
    door.mesh.set_relative_rotation(u.Rotator(yaw=90),False,False);door.handle.set_relative_location(u.Vector(98,12,105),False,False);doors[i]=door
    # A human-scale hollow six-drawer dresser with six independent trays.
    cx=x-(350 if r['name']=='Garage' else 0);cy=y-(300 if r['row']==0 else 160)
    prop('dresser',[cx,cy,z],180,.65)
    trays=[]
    for row in range(2):
        for col in range(3):
            dx=cx+(col-1)*72;dz=z+30+row*45
            d=action(f'{r["name"]}_drawer_{row*3+col+1}',[dx,cy+2,dz],u.WDInteraction.DRAWER,meshes['drawer'],180,.65)
            d.handle.set_relative_location(u.Vector(0,49,0),False,False)
            d.set_editor_property('open_offset',u.Vector(0,48,0));d.set_editor_property('blocks_passage',False);trays.append(d)
    drawers[i]=trays
    # Wardrobe: physical hollow shell; hiding viewpoint is inside, facing its slotted front.
    wx=x+side*420;wy=y+220
    prop('wardrobe_case',[wx,wy,z],180,.7)
    h=action('Hide_'+r['name'],[wx,wy,z],u.WDInteraction.WARDROBE)
    h.handle.set_relative_location(u.Vector(0,-64,110),False,False)
    h.set_editor_property('hide_offset',u.Vector(0,0,90));h.set_editor_property('exit_offset',u.Vector(0,-180,92));hides.append(h)
    # Thin front boards leave a physical viewing slit. Separate sides are clearly visible.
    box('WardrobeLower',[wx,wy-56,z+55],[115,5,110]);box('WardrobeUpper',[wx,wy-56,z+156],[115,5,36])
    for sx in (-58,58):box('WardrobeStile',[wx+sx,wy-60,z+90],[5,8,180])
    box('WardrobeLatch',[wx+46,wy-65,z+103],[4,7,13],'brass',False)
    # Composition: furniture clustered near walls, readable circulation and scattered clutter.
    if r['floor']==2:
        bx=x-side*270;by=y+80;prop('bed',[bx,by,z],90,.8)
        bed=action('Under_bed_'+r['name'],[bx,by,z],u.WDInteraction.BED)
        bed.handle.set_relative_location(u.Vector(0,-115,35),False,False);bed.set_editor_property('hide_offset',u.Vector(0,0,90));bed.set_editor_property('exit_offset',u.Vector(0,-180,92));hides.append(bed)
    elif r['floor']==1:
        prop('cradle',[x-side*260,y+80,z],15,.95);prop('armchair',[x+100,y+100,z],-20,1)
        prop('nursery_litter',[x-100,y-40,z],30,1,False)
    elif r['name']=='Kitchen':
        for j in range(4):prop('kitchen',[x-350+j*180,y+280,z],180,1)
        prop('dining',[x,y+30,z],0,1)
    elif r['name']=='Parlour':
        prop('sofa',[x-230,y+60,z],90,1);prop('armchair',[x+230,y+120,z],-45,1);prop('dining',[x,y+50,z],0,.7)
    elif r['name']=='Study':
        prop('shelf',[x+340,y+300,z],180,1);prop('dining',[x-160,y+80,z],15,.8);prop('armchair',[x-280,y+80,z],70,1)
    elif r['floor']==-1:
        for j in range(3):box('OldCrate',[x-250+j*180,y+100,z+40],[100,85,80],'wood')
        for j in range(4):box('BoilerPipe',[x+side*600,y,z+50+j*55],[15,650,15],'stone')
    prop('radiator',[side*1540,y+100,z],side*90,.9)
    for j in range(4):
        prop('litter' if j%2 else 'debris',[x+random.uniform(-440,440),y+random.uniform(-180,220),z+2],random.randrange(360),random.uniform(.65,1.1),False)
    prop('fallen_chair',[x+320,y-60,z],33,.8,False)
    # Little disturbances occupy the route but never trap the collision capsule.
    n=action('Loose_crockery_'+r['name'],[x+200,y-40,z+20],u.WDInteraction.NOISE,cube,scale=.28);n.mesh.set_material(0,materials['paper'])
    # Skirting, cornices and vertical wall panelling give the architecture depth.
    for wall_y in (y-440 if r['row']==0 else -230,y+340):
        if r['name']=='Garage' and wall_y==y-440:
            box('GarageSkirtingLeft',[447.5,wall_y,z+12],[445,8,24]);box('GarageSkirtingRight',[1422.5,wall_y,z+12],[305,8,24])
        else:box('Skirting',[x,wall_y,z+12],[1350,8,24])
        box('Cornice',[x,wall_y,z+305],[1350,12,15])
    for j in range(6):box('Wallpanel',[side*1587,y-300+j*110,z+70],[8,90,120])
    # Original framed silhouettes, no extracted third-party artwork.
    for j in range(2):
        px=x-280+j*540;py=-265 if r['row']==0 else 495
        box('PortraitBacking',[px,py,z+175],[95,5,120],'dark',False)
        for dx in (-50,50):box('PortraitFrame',[px+dx,py-4,z+175],[7,8,132],'brass',False)
        for dz in (-64,64):box('PortraitFrame',[px,py-4,z+175+dz],[106,8,7],'brass',False)
        box('PortraitHead',[px,py-7,z+195],[32,2,40],'paper',False,mesh=sphere)
        box('PortraitShoulders',[px,py-7,z+154],[58,2,40],'stone',False,mesh=sphere)

for index,(key,room,needs) in enumerate(house['stashes']):
    tray=drawers[room][(index*5+2)%6];tray.set_editor_property('required_keys',[u.Name(n) for n in needs])
    p=tray.get_actor_location()
    k=action('Key_'+key,[p.x,p.y,p.z],u.WDInteraction.KEY,meshes['key'],scale=.48)
    k.set_editor_property('container',tray);k.set_editor_property('grants_key',u.Name(key));k.set_editor_property('open_offset',u.Vector(0,0,-16));k.set_editor_property('interaction_sound',audio['key'])
    key_metadata.append(dict(key=key,room=room,container=tray.get_actor_label(),approach=[p.x,p.y-150,p.z//320*320+92]))

# Two keys are hidden behind hinged frames instead of a second arbitrary drawer.
for name in ('Study','Archive'):
    k=next(a for a in ACTORS.get_all_level_actors() if a.get_actor_label()=='Key_'+name)
    r=house['rooms'][next(s[1] for s in house['stashes'] if s[0]==name)]
    p=[r['x'],-275 if r['row']==0 else 485,r['z']+145]
    frame=action('Hinged_portrait_'+name,p,u.WDInteraction.DOOR,cube,scale=1)
    frame.mesh.set_relative_scale3d(u.Vector(.9,.05,1.0));frame.mesh.set_material(0,materials['wood']);frame.set_editor_property('blocks_passage',False)
    frame.set_editor_property('open_yaw',-100.0);frame.handle.set_relative_location(u.Vector(40,-8,0),False,False)
    if name=='Archive':frame.set_editor_property('required_keys',[u.Name('Safe')])
    k.set_actor_location(u.Vector(p[0],p[1]+8,p[2]),False,False);k.set_editor_property('container',frame)
    for entry in key_metadata:
        if entry['key']==name:entry.update(container='Hinged_portrait_'+name,approach=[p[0],p[1]-120,r['z']+92])

car=action('EscapeCar',[1070,-760,0],u.WDInteraction.CAR,meshes['car'],yaw=-90)
car.mesh.set_relative_rotation(u.Rotator(yaw=-90),False,False)
car.handle.set_relative_location(u.Vector(-125,-20,105),False,False)
car.set_editor_property('interaction_sound',audio['engine'])
garage=action('GarageLock',[1070,-1207,140],u.WDInteraction.GARAGE,cube,required='Garage')
garage.mesh.set_relative_scale3d(u.Vector(3.8,.1,2.8));garage.mesh.set_material(0,materials['wood']);garage.handle.set_relative_location(u.Vector(-220/3.8,210,-40/2.8),False,False)
garage.set_editor_property('open_offset',u.Vector(0,0,285))
box('GarageKeyPlate',[850,-1186,100],[14,4,25],'brass',False)
box('GarageKeyHole',[850,-1182,102],[3,2,8],'dark',False)
# Reuse the approved Blender room's posed keeper, with its original texture.
keeper=prop('keeper',[-1100,160,370],20,1,False,'TheKeeper');keeper.set_actor_rotation(u.Rotator(pitch=90,yaw=20),False)
center,extent=keeper.get_actor_bounds(False)
keeper.set_actor_location(keeper.get_actor_location()+u.Vector(-1100-center.x,160-center.y,323+extent.z-center.z),False,False)
for slot in range(meshes['keeper'].get_num_sections(0)):keeper.static_mesh_component.set_material(slot,skin)
letter=action('KeeperLetter',[-1040,175,350],u.WDInteraction.LETTER,cube);letter.mesh.set_relative_scale3d(u.Vector(.22,.3,.012));letter.mesh.set_material(0,materials['paper'])
for i,p in enumerate([[0,-1050,96],[-65,-1020,96],[65,-1020,96],[0,-920,96]]):spawn(u.PlayerStart,'Survivor_'+str(i),p,90)
ghost=spawn(ghost_class,'Eleanor',[0,350,-230],90);ghost.mesh.set_skeletal_mesh_asset(ghost_mesh)
ghost_scale=235/(ghost_record['source_height_m']*100);ghost.mesh.set_relative_scale3d(u.Vector(ghost_scale,ghost_scale,ghost_scale));ghost.mesh.set_relative_rotation(u.Rotator(yaw=-90),False,False)
ghost.mesh.set_relative_location(u.Vector(0,0,-88-ghost_record['source_min_z_m']*100*ghost_scale),False,False)
ghost.set_editor_property('warning_sound',audio['wail']);ghost.set_editor_property('patrol_points',[u.Vector(*p) for p in [[0,-800,-230],[0,350,-230],[0,-850,90],[0,400,90],[-1350,700,90],[-400,700,410],[0,-900,410],[0,400,410]]])
for clip,animation in ghost_animations.items():ghost.set_editor_property(clip+'_animation',animation)
for name in ('manor','parchment'):import_texture('assets/ui/'+name+'.png','UI_'+name)

# Warm practical lights above ground; basement receives no ceiling illumination.
for r in house['rooms']:
    if r['floor']<0:continue
    x,y,z=r['x'],r['y'],r['z']
    light=spawn(u.PointLight,'RoomLight_'+r['name'],[x,y,z+260]);c=light.point_light_component
    c.set_mobility(u.ComponentMobility.MOVABLE);c.set_editor_property('intensity_units',u.LightUnits.LUMENS);c.set_intensity(80);c.set_attenuation_radius(400);c.set_light_color(u.LinearColor(1,.82,.65));c.set_cast_shadows(True)
    box('LightStem',[x,y,z+290],[5,5,55],'dark',False,mesh=cylinder)
    box('PendantShade',[x,y,z+265],[45,45,20],'brass',False,mesh=cylinder)
    box('Bulb',[x,y,z+252],[12,12,18],'lamp',False,mesh=sphere)
for floor in (0,1,2):
    for y in (-850,-100,650):
        p=spawn(u.PointLight,'FlickerHall',[0,y,floor*320+260]);c=p.point_light_component;c.set_mobility(u.ComponentMobility.MOVABLE);c.set_editor_property('intensity_units',u.LightUnits.LUMENS);c.set_intensity(60);c.set_attenuation_radius(360);c.set_light_color(u.LinearColor(.65,.73,1));p.set_editor_property('tags',[u.Name('Flicker')])
        box('HallFixture',[0,y,floor*320+290],[40,40,12],'dark',False);box('HallBulb',[0,y,floor*320+278],[18,18,12],'lamp',False,mesh=sphere)
sky=spawn(u.SkyLight,'NightFill',[0,0,1500]);sky.light_component.set_intensity(.015)
sun=spawn(u.DirectionalLight,'DawnMoon',[0,0,1800]);sun.set_actor_rotation(u.Rotator(pitch=-25,yaw=30),False);sun.light_component.set_intensity(.08);sun.light_component.set_light_color(u.LinearColor(.4,.55,.8));sun.light_component.set_mobility(u.ComponentMobility.MOVABLE)
sun.light_component.set_cast_shadows(False)
for x in (-900,900):
    fill=spawn(u.PointLight,'CourtyardBlueFill_'+str(x),[x,-1900,480]);c=fill.point_light_component;c.set_mobility(u.ComponentMobility.MOVABLE);c.set_editor_property('intensity_units',u.LightUnits.LUMENS);c.set_intensity(500);c.set_attenuation_radius(1400);c.set_light_color(u.LinearColor(.25,.35,.6));c.set_cast_shadows(False)
fog=spawn(u.ExponentialHeightFog,'CourtyardMist',[0,0,-20]);fog.component.set_editor_property('fog_density',.008);fog.component.set_editor_property('fog_height_falloff',.7)
ambient=spawn(u.AmbientSound,'HouseAmbience',[0,0,0]);audio['ambient'].set_editor_property('looping',True);ambient.audio_component.set_sound(audio['ambient']);ambient.audio_component.set_volume_multiplier(.18);ambient.audio_component.set_editor_property('auto_activate',True)
nav=spawn(u.NavMeshBoundsVolume,'HouseNavigation',[0,0,400]);nav.set_actor_scale3d(u.Vector(22,18,10))
world=u.get_editor_subsystem(u.UnrealEditorSubsystem).get_editor_world();u.SystemLibrary.execute_console_command(world,'RebuildNavigation')
u.EditorAssetLibrary.save_directory('/Game/Imported',only_if_is_dirty=False,recursive=True)
if not LEVELS.save_current_level():raise RuntimeError('House save failed')
(ROOT/'unreal/docs/evidence/house-layout.json').write_text(json.dumps(dict(**verify_house(),key_locations=key_metadata,actors=len(ACTORS.get_all_level_actors())),indent=2))
print('WD_FULL_HOUSE_CREATED',MAP,'Actors',len(ACTORS.get_all_level_actors()))
