"""Portable authoring validation. Does NOT compile Unreal or test its physics/networking."""
from pathlib import Path
import ast, json, hashlib, sys
from slice_layout import layout, verify_layout
from house_layout import verify as verify_house
ROOT=Path(__file__).resolve().parents[2]
PROJECT=ROOT/'unreal/WaitingForDawn'
project=json.loads((PROJECT/'WaitingForDawn.uproject').read_text())
assert project['EngineAssociation']=='5.7'
assert project['Modules'][0]['Name']=='WaitingForDawn'
for script in (ROOT/'unreal/tools').glob('*.py'):
    ast.parse(script.read_text(encoding='utf-8'),filename=str(script))
report={'scope':'Source and export checks only; not an Unreal runtime test','layout':verify_layout(layout())}
report['house']=verify_house()
manifest=ROOT/'unreal/Staging/assets.json'
if manifest.exists():
    entries=json.loads(manifest.read_text())
    for asset in entries:
        path=manifest.parent/asset['fbx']
        assert path.exists(),path
        assert hashlib.sha256(path.read_bytes()).hexdigest()==asset['sha256'],path
        if 'source_sha256' in asset:
            assert hashlib.sha256((ROOT/asset['source']).read_bytes()).hexdigest()==asset['source_sha256']
    report['verified_fbx_exports']=len(entries)
    report['static_triangles']=sum(e.get('triangles',0) for e in entries)
else: report['verified_fbx_exports']=0
art=ROOT/'design/eleanor-092'
ghost=json.loads((art/'manifest.json').read_text())
assert hashlib.sha256((art/ghost['fbx']).read_bytes()).hexdigest()==ghost['sha256']
assert hashlib.sha256((ROOT/ghost['source']).read_bytes()).hexdigest()==ghost['source_sha256']
assert 0<ghost['triangles']<35000 and ghost['bones']==42 and ghost['root_bones']==['DawnRoot']
for texture in ghost['maps']:
    assert hashlib.sha256((art/texture['file']).read_bytes()).hexdigest()==texture['sha256']
imported=json.loads((art/'unreal-import.json').read_text())
assert imported['fbx_sha256']==ghost['sha256'] and len(imported['slots'])==8
assert imported['face_source_sha256']==hashlib.sha256((art/'face_projection.png').read_bytes()).hexdigest()
for name,digest in imported['generated_asset_hashes'].items():
    assert hashlib.sha256((PROJECT/'Content/Eleanor092'/name).read_bytes()).hexdigest()==digest
for name,digest in imported['protected_asset_hashes'].items():
    assert hashlib.sha256((PROJECT/'Content/Imported'/name).read_bytes()).hexdigest()==digest
report['eleanor_redesign']={'triangles':ghost['triangles'],'bones':ghost['bones'],'material_slots':8,'verified_maps':len(ghost['maps']),'unchanged_animation_and_skeleton_assets':len(imported['protected_asset_hashes'])}
print(json.dumps(report,indent=2))
