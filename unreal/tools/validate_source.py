"""Portable authoring validation. Does NOT compile Unreal or test its physics/networking."""
from pathlib import Path
import ast, json, hashlib, sys
from slice_layout import layout, verify_layout
ROOT=Path(__file__).resolve().parents[2]
PROJECT=ROOT/'unreal/WaitingForDawn'
project=json.loads((PROJECT/'WaitingForDawn.uproject').read_text())
assert project['EngineAssociation']=='5.7'
assert project['Modules'][0]['Name']=='WaitingForDawn'
for script in (ROOT/'unreal/tools').glob('*.py'):
    ast.parse(script.read_text(encoding='utf-8'),filename=str(script))
report={'scope':'Source and export checks only; not an Unreal runtime test','layout':verify_layout(layout())}
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
print(json.dumps(report,indent=2))
