"""Rebuild trim as real separated lengths around the approved apertures."""
from pathlib import Path
import bpy,json
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'design/rooms/eleanors-nursery'
bpy.ops.wm.open_mainfile(filepath=str(OUT/'nursery-form.blend'))
layout=json.loads((OUT/'room-layout.json').read_text());openings=json.loads((OUT/'openings.json').read_text())['openings']
material=bpy.data.materials['Aged walnut / generated albedo'];collection=bpy.data.collections['Joinery']
for wall in layout['surfaces']:
 if not wall.get('wall'):continue
 for obj in [o for o in bpy.data.objects if o.type=='MESH' and o.name.startswith(wall['id']+' trim')]:bpy.data.objects.remove(obj,do_unlink=True)
 axis=0 if wall['dimensions'][0]>wall['dimensions'][1] else 1
 low=wall['location'][axis]-wall['dimensions'][axis]/2;high=wall['location'][axis]+wall['dimensions'][axis]/2
 for z,height in [(.14,.28),(2.55,.05),(3.48,.09)]:
  intervals=[(low,high)]
  for op in openings:
   if op['wallId']!=wall['id'] or op['kind']!='door' or z-height/2>op['heightMeters']:continue
   a=op['location'][axis]-op['widthMeters']/2;b=op['location'][axis]+op['widthMeters']/2
   updated=[]
   for start,end in intervals:
    if b<=start or a>=end:updated.append((start,end));continue
    if a>start:updated.append((start,a))
    if b<end:updated.append((b,end))
   intervals=updated
  for start,end in intervals:
   if end-start<.01:continue
   pos=list(wall['location']);pos[axis]=(start+end)/2;pos[2]=z
   size=list(wall['dimensions']);size[axis]=end-start;size[2]=height
   bpy.ops.mesh.primitive_cube_add(size=1,location=pos);obj=bpy.context.object;obj.name=wall['id']+' trim segment';obj.dimensions=size
   bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
   obj.data.materials.append(material)
   for c in list(obj.users_collection):c.objects.unlink(obj)
   collection.objects.link(obj)
   bevel=obj.modifiers.new('Trim edge','BEVEL');bevel.width=.012;bevel.segments=2
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'nursery-form.blend'))
print('APPROVED_DOORWAY_TRIM_REBUILT_AS_SEPARATE_SEGMENTS')
