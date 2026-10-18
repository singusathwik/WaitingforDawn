"""Validate delivery geometry, baked texture tiers and the shared fixture manifest."""
from pathlib import Path
import hashlib,json,struct
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
PACKAGE=ROOT/'design/rooms/eleanors-nursery'
ASSETS=ROOT/'assets/models/nursery'
export=json.loads((PACKAGE/'runtime/export.json').read_text())
digest=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
assert digest(PACKAGE/'nursery-form.blend')==export['nativeSha256']
for name,expected in export['files'].items():
    assert digest(ASSETS/name)==expected['sha256'],name
assert digest(ASSETS/'lighting-manifest.json')==export['fixtureManifestSha256']
assert digest(PACKAGE/'lighting-manifest.json')==export['fixtureManifestSha256']
data=(ASSETS/'nursery.glb').read_bytes()
magic,version,length=struct.unpack_from('<III',data)
assert magic==0x46546c67 and version==2 and length==len(data)
json_size,kind=struct.unpack_from('<II',data,12)
assert kind==0x4e4f534a
model=json.loads(data[20:20+json_size])
assert len(model['meshes'])==16
assert not model.get('images'), 'Runtime owns the external baked atlas'
triangles=0
for mesh in model['meshes']:
    for primitive in mesh['primitives']:
        assert primitive.get('mode',4)==4
        assert 'TEXCOORD_0' in primitive['attributes']
        triangles+=model['accessors'][primitive['indices']]['count']//3
assert triangles==export['triangles'] and triangles<250000
for name,size in [('nursery-lit.png',4096),('nursery-lit-low.png',2048)]:
    with Image.open(ASSETS/name) as texture: assert texture.size==(size,size)
    settings=(ASSETS/(name+'.import')).read_text()
    assert 'compress/mode=2' in settings and 'mipmaps/generate=true' in settings
assert len(data)<8_000_000 and export['textureBudgetBytes']<24_000_000
result={'status':'PASS','triangles':triangles,'geometryBytes':len(data),
        'geometryTiers':'Shared geometry at both texture tiers',
        'highAtlasGpuBudgetBytes':export['textureBudgetBytes'],
        'fixtureManifestSha256':export['fixtureManifestSha256'],
        'lightmap':'Combined material and lighting atlas; 16 meshes have UV0. Static surfaces are unshaded; runtime practicals illuminate moving actors.',
        'nativeAndExportHashes':'MATCH','textureTiers':'4096 and 2048, VRAM compressed with mipmaps',
        'humanRuntimeApproval':'NOT GRANTED BY THIS CHECK'}
(PACKAGE/'runtime/integrity.json').write_text(json.dumps(result,indent=2)+'\n')
print('NURSERY EXPORT PASS',triangles,'triangles;',len(data),'geometry bytes; source, bake and runtime manifest hashes match')
