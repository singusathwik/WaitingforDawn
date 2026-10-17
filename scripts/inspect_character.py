import bpy,json
from pathlib import Path
bpy.ops.wm.open_mainfile(filepath=str(Path(__file__).resolve().parents[1]/'source_art/rosswet/new_thin_zombie.blend'))
print('OBJECTS',[(o.name,o.type,tuple(o.dimensions)) for o in bpy.data.objects])
print('ACTIONS',[(a.name,a.frame_range[:]) for a in bpy.data.actions])
print('IMAGES',[(i.name,i.filepath) for i in bpy.data.images])
for o in bpy.data.objects:
 if o.type=='ARMATURE':print('BONES',[b.name for b in o.data.bones])
