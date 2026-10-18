"""Restore the unanimated master root's bind transform in every imported clip.
The FBX bind root has scale 395.7522; its baked animation incorrectly replaced it
with unit scale. Preserve all animated child bones, vertex weights and materials.
"""
import unreal as u
import json
from pathlib import Path
mesh=u.load_asset('/Game/Imported/SK_Eleanor')
mod=u.SkeletonModifier();assert mod.set_skeletal_mesh(mesh)
root='dawnroot';ref=mod.get_bone_transform(root,False)
assert ref.scale3d.x>300 and ref.scale3d.x<450
report=[]
for path in u.EditorAssetLibrary.list_assets('/Game/Imported',recursive=False):
    clip=u.load_asset(path)
    if not isinstance(clip,u.AnimSequence) or not clip.get_name().startswith('SK_Eleanor_Anim_'):continue
    model=clip.data_model_interface;controller=clip.controller
    before=u.AnimationLibrary.get_bone_pose_for_time(clip,root,0,False)
    count=model.get_number_of_keys()
    controller.open_bracket('Restore static master root bind transform',False)
    assert controller.set_bone_track_keys(root,[ref.translation]*count,[ref.rotation]*count,[ref.scale3d]*count,False)
    controller.close_bracket(False)
    u.EditorAssetLibrary.save_loaded_asset(clip)
    after=u.AnimationLibrary.get_bone_pose_for_time(clip,root,0,False)
    assert abs(after.scale3d.x-ref.scale3d.x)<.01
    report.append({'animation':clip.get_name(),'keys':count,'before_root_scale':before.scale3d.x,'after_root_scale':after.scale3d.x})
assert len(report)==5
out=Path(__file__).resolve().parents[1]/'docs/evidence/ghost-animation-scale-091.json'
out.write_text(json.dumps(report,indent=2)+'\n')
print('GHOST_ROOT_REPAIRED',len(report))
