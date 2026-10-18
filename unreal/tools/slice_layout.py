"""Authoring source shared by the Unreal map builder and independent geometry checks.
All positions and dimensions are Unreal centimetres: X forward, Y right, Z up.
"""
from math import sqrt

def layout():
    boxes = []
    def box(name, centre, size, material="plaster", role="structure", visible=True):
        boxes.append(dict(name=name, centre=centre, size=size, material=material, role=role, visible=visible))
    box("Ground_support", [0,0,-15], [1240,940,30], "floor", "floor")
    box("Upper_east_support", [390,0,305], [460,900,30], "floor", "floor")
    box("Upper_nursery_support", [-220,-175,305], [760,550,30], "floor", "floor")
    # Stair treads are SOLID closed boxes, overlapping 1 cm at the risers.
    for i in range(20):
        height = (i+1)*16
        box(f"Stair_{i:02}", [-386+i*28,250,height/2], [29,150,height], "wood", "stair")
        for side in (-1,1):
            box(f"Stair_guard_{i:02}_{side}", [-386+i*28,250+side*79,height+60], [29,8,120], "wood", "guard", False)
            box(f"Stair_newel_{i:02}_{side}", [-386+i*28,250+side*79,height+50], [5,5,100], "wood", "rail")
            box(f"Stair_rail_{i:02}_{side}", [-386+i*28,250+side*79,height+100], [32,7,7], "wood", "rail")
    for z in (0,320):
        for y in (-460,460): box(f"Outer_Y_{y}_{z}",[0,y,z+160],[1240,20,320])
        for x in (-610,610): box(f"Outer_X_{x}_{z}",[x,0,z+160],[20,900,320])
    box("Roof",[0,0,655],[1240,940,30],"plaster")
    # Ground-floor room: wall segments leave a real 110 x 240 cm opening.
    box("Door_wall_south",[-200,-325,160],[20,250,320])
    box("Door_wall_north",[-200,5,160],[20,190,320])
    box("Door_header",[-200,-145,280],[20,110,80])
    for y in (-205,-85): box(f"Door_frame_{y}",[-200,y,120],[24,10,240],"wood")
    box("Door_frame_top",[-200,-145,242],[24,130,8],"wood")
    box("Landing_guard_north",[-220,104,380],[760,8,120],"wood","guard",False)
    for x in range(-590,161,30): box(f"Landing_baluster_{x}",[x,104,370],[5,5,100],"wood","rail")
    box("Landing_handrail",[-220,104,420],[760,8,8],"wood","rail")
    for y,length in [(137,66),(397,106)]:
        box(f"Landing_end_guard_{y}",[156,y,380],[8,length,120],"wood","guard",False)
        box(f"Landing_end_rail_{y}",[156,y,420],[8,length,8],"wood","rail")
    # Small pieces are visual only; invisible coarse cubes must not trap the player.
    props = [
        dict(asset="sofa",location=[-460,-290,0],yaw=90,scale=1),
        dict(asset="dining",location=[180,-220,0],yaw=12,scale=1),
        dict(asset="fallen_chair",location=[300,-40,0],yaw=35,scale=1),
        dict(asset="litter",location=[-320,20,0],yaw=60,scale=1),
        dict(asset="litter",location=[360,70,0],yaw=170,scale=1),
        dict(asset="bed",location=[-410,-280,320],yaw=0,scale=.7),
        dict(asset="nursery_litter",location=[-150,-180,320],yaw=0,scale=.75),
        dict(asset="shelf",location=[480,-390,320],yaw=0,scale=.7),
        dict(asset="radiator",location=[-570,0,320],yaw=90,scale=.7),
    ]
    route = [[-450,250,0]] + [[-386+i*28,250,(i+1)*16] for i in range(20)]
    route += [[200,250,320],[310,250,320],[310,40,320],[-320,40,320]]
    return dict(units="centimetres", boxes=boxes, props=props, stair_route=route,
                starts=[[-430,-50,96],[-380,-50,96],[-430,30,96],[-380,30,96]],
                ghost=[430,-320,90], patrol=[[430,-320,90],[420,250,90],[-450,250,90]],
                door=[-200,-200,0], cupboard=[-520,30,0],
                lights=[[-350,-80,270],[250,-180,270],[300,250,590],[-250,-150,590]])

def support_height(boxes, x, y, ceiling):
    hits = []
    for b in boxes:
        if b["role"] not in ("floor","stair"): continue
        c,s=b["centre"],b["size"]
        top=c[2]+s[2]/2
        if abs(x-c[0])<=s[0]/2 and abs(y-c[1])<=s[1]/2 and top<=ceiling:
            hits.append(top)
    return max(hits) if hits else None

def verify_layout(data):
    failures=[]; probes=0
    route=data["stair_route"]
    for a,b in zip(route,route[1:]):
        n=max(1,int(sqrt(sum((v-u)**2 for u,v in zip(a,b)))/2))
        for i in range(n+1):
            t=i/n; p=[u+(v-u)*t for u,v in zip(a,b)]
            for offset in (-38,0,38):
                # Side samples apply along the actual stair run, not across the landing railing.
                y=p[1]+offset if p[1]==250 else p[1]
                top=support_height(data["boxes"],p[0],y,p[2]+35)
                probes+=1
                if top is None or abs(top-p[2])>35: failures.append((p,offset,top))
    assert not failures, f"Stair support gaps: {failures[:6]}"
    assert all(b["size"][2]>0 for b in data["boxes"])
    assert len({b['name'] for b in data['boxes']})==len(data['boxes'])
    return dict(support_probes=probes,boxes=len(data['boxes']),props=len(data['props']))

if __name__ == '__main__':
    import json
    print(json.dumps(verify_layout(layout()),indent=2))
