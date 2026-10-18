"""Complete manor authoring data, centimetres; progression checked independently of Unreal."""
from math import sqrt,atan2,degrees

KEYS=['Nursery','Pantry','Study','Cellar','Boiler','Bedroom','Attic','Safe','Archive','Workshop','Garage','Ignition']
ROOMS=[
 (-1,-1,0,'Coal cellar','Cellar'),(-1,-1,1,'Boiler room','Boiler'),(-1,1,0,'Workshop','Workshop'),(-1,1,1,'Wine store',''),
 (0,-1,0,'Parlour',''),(0,-1,1,'Kitchen',''),(0,1,0,'Garage',''),(0,1,1,'Study',''),
 (1,-1,0,'Nursery','Nursery'),(1,-1,1,'Playroom',''),(1,1,0,'Schoolroom',''),(1,1,1,'Music room',''),
 (2,-1,0,'Eleanor bedroom','Bedroom'),(2,-1,1,'Attic bedroom','Attic'),(2,1,0,'Guest bedroom','Safe'),(2,1,1,'Archive','Archive')]
# key, room index, prerequisite keys for the container (room lock is separate)
STASHES=[('Nursery',4,[]),('Pantry',5,[]),('Study',7,[]),('Cellar',8,[]),
 ('Boiler',0,['Nursery','Pantry','Study']),('Bedroom',1,[]),('Attic',12,[]),
 ('Safe',13,[]),('Archive',13,['Safe']),('Workshop',14,[]),('Garage',15,['Safe']),('Ignition',2,[])]
def layout():
    boxes=[]; stairs=[]; rooms=[]
    def box(name,p,s,mat='plaster',role='structure',visible=True,pitch=0):
        boxes.append(dict(name=name,centre=p,size=s,material=mat,role=role,visible=visible,pitch=pitch))
    for floor in range(-1,3):
        z=floor*320
        # Cut only the incoming flight. Four rectangular pieces preserve the rest of the floor.
        incoming={0:1050,1:700,2:1050}.get(floor)
        if incoming is None:box('floor_basement',[0,0,z-15],[3200,2400,30],'floor','floor')
        else:
            x0,x1=-1240,-600; y0,y1=incoming-100,incoming+100
            for j,(xa,xb,ya,yb) in enumerate([(-1600,x0,-1200,1200),(x1,1600,-1200,1200),(x0,x1,-1200,y0),(x0,x1,y1,1200)]):
                box(f'floor_{floor}_{j}',[(xa+xb)/2,(ya+yb)/2,z-15],[xb-xa,yb-ya,30],'floor','floor')
        for x in (-1610,1610):box(f'outer_x_{floor}_{x}',[x,0,z+160],[20,2440,320])
        box(f'outer_north_{floor}',[0,1210,z+160],[3240,20,320])
        # Garage facade has an actual 380 cm opening, ground level only.
        if floor==0:
            box('front_left',[-475,-1210,160],[2290,20,320]);box('front_right',[1445,-1210,160],[350,20,320]);box('garage_lintel',[1070,-1210,300],[400,20,40])
        else:box(f'outer_south_{floor}',[0,-1210,z+160],[3240,20,320])
        # Each side has two rooms, both reached from the central hall.
        for side in (-1,1):
            x=side*200
            for n,(a,b) in enumerate([(-1200,-835),(-685,65),(215,500)]):box(f'hallwall_{floor}_{side}_{n}',[x,(a+b)/2,z+160],[20,b-a,320])
            for y in (-760,140):
                box(f'header_{floor}_{side}_{y}',[x,y,z+280],[20,150,80])
                for end in (-80,80):box(f'jamb_{floor}_{side}_{y}_{end}',[x,y+end,z+120],[26,10,240],'wood')
                box(f'architrave_{floor}_{side}_{y}',[x,y,z+243],[26,170,9],'wood')
            box(f'roompartition_{floor}_{side}',[side*905,-250,z+160],[1390,20,320])
            box(f'roomrear_{floor}_{side}',[side*905,510,z+160],[1390,20,320])
        # Continuous hall runner; worn spots are tagged separately for rare creaks.
        box(f'runner_{floor}',[0,-300,z+1],[260,1700,2],'carpet','dressing')
        box(f'loose_{floor}',[0,670,z+1],[320,130,2],'floor','LooseBoard')
    box('roof',[0,0,975],[3240,2440,30])
    for floor,y in [(-1,1050),(0,700),(1,1050)]:
        z=floor*320
        route=[[-1340,y,z]]
        for i in range(20):
            x=-1226+i*30;h=(i+1)*16
            box(f'step_{floor}_{i}',[x,y,z+h/2],[31,180,h],'wood','stair')
            for side in (-1,1):
                box(f'guard_{floor}_{i}_{side}',[x,y+side*96,z+h+55],[31,8,110],'wood','guard',False)
                if i%3==0:box(f'newel_{floor}_{i}_{side}',[x,y+side*96,z+h+48],[5,5,96],'wood','rail')
            if i%4==0:route.append([x,y,z+h])
        route += [[-550,y,z+320],[-400,y,z+320]];stairs.append(route)
        box(f'top_landing_bridge_{floor}',[-620,y,z+305],[60,180,30],'floor','floor')
        for side in (-1,1):
            box(f'handrail_{floor}_{side}',[-941,y+side*96,z+260],[sqrt(600**2+320**2),8,8],'wood','rail',True,degrees(atan2(320,600)))
            box(f'landingguard_{floor}_{side}',[-920,y+side*107,z+375],[640,8,110],'wood','guard',False)
            box(f'landingrail_{floor}_{side}',[-920,y+side*107,z+420],[640,8,8],'wood','rail')
        box(f'endguard_{floor}',[-1244,y,z+375],[8,210,110],'wood','guard',False)
        box(f'endrail_{floor}',[-1244,y,z+420],[8,210,8],'wood','rail')
    # Exterior ground and boundary; the player cannot walk into empty space.
    for j,(xa,xb,ya,yb) in enumerate([(-3000,-1620,-3000,3000),(1620,3000,-3000,3000),(-1620,1620,-3000,-1220),(-1620,1620,1220,3000)]):
        box(f'courtyard_{j}',[(xa+xb)/2,(ya+yb)/2,-10],[xb-xa,yb-ya,20],'stone','floor')
    for side in (-1,1):
        box(f'estate_x{side}',[side*2800,0,150],[35,5600,350],'stone')
        box(f'estate_y{side}',[0,side*2800,150],[5600,35,350],'stone')
    for i,(floor,side,row,name,lock) in enumerate(ROOMS):
        rooms.append(dict(id=i,floor=floor,side=side,row=row,name=name,lock=lock,z=floor*320,x=side*900,y=-730 if row==0 else 130))
    return dict(boxes=boxes,stairs=stairs,rooms=rooms,keys=KEYS,stashes=STASHES)

def verify():
    owned=set();order=[]
    while len(owned)<len(KEYS):
        before=len(owned)
        for key,room,needs in STASHES:
            lock=ROOMS[room][4]
            if key not in owned and (not lock or lock in owned) and all(n in owned for n in needs):owned.add(key);order.append(key)
        assert len(owned)>before,'Circular key dependency or unreachable key'
    d=layout();assert len({b['name'] for b in d['boxes']})==len(d['boxes'])
    return dict(rooms=len(ROOMS),keys=len(KEYS),progression_order=order,stair_flights=3,boxes=len(d['boxes']))
if __name__=='__main__':
    import json;print(json.dumps(verify(),indent=2))
