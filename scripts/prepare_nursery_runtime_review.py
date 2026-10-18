"""Collect local runtime evidence for a human review. Never grants approval."""
from pathlib import Path
import hashlib,json,shutil

ROOT=Path(__file__).resolve().parents[1]
PACKAGE=ROOT/'design/rooms/eleanors-nursery'
DELIVERY=ROOT/'docs/validation-0.8.1'
DELIVERY.mkdir(exist_ok=True)
read=lambda p:json.loads(p.read_text())
def write(p,value):p.write_text(json.dumps(value,indent=2)+'\n',encoding='utf-8')
for name in ['tests-081-final.log','traversal-081.log','benchmark-081.log','signature-081.txt','manifest-081.txt','form-preflight-final.log']:
    shutil.copy2(ROOT/'artifacts'/name,DELIVERY/name)
for p in (ROOT/'artifacts/android-081').glob('*.log'):
    (DELIVERY/('android-'+p.name)).write_text('\n'.join(line.rstrip() for line in p.read_text().splitlines()).rstrip()+'\n',newline='\n')
for p in (ROOT/'artifacts/android-081').glob('*.png'):shutil.copy2(p,PACKAGE/'runtime'/p.name)
files={}
for ext in ['apk','exe']:
    p=ROOT/'artifacts'/('WaitingForDawn-0.8.1.'+ext)
    files[p.name]={'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
write(DELIVERY/'build.json',{'version':'0.8.1','androidVersionCode':9,'files':files})
(ROOT/'artifacts/SHA256SUMS-0.8.1.txt').write_text(''.join(v['sha256']+'  '+k+'\n' for k,v in files.items()))
report=read(PACKAGE/'final-report.json')
report['runtimeChecks']={'vlow':True,'textureTiers':True,'lightmap':True,'lightingManifest':True,'performance':True,
    'browserCapture':'runtime-review-browser.png','errors':[],
    'evidence':'runtime/integrity.json; docs/validation-0.8.1; runtime/*.png',
    'performanceScope':'Geometry and texture budgets pass. Short desktop and host-GPU emulator benchmarks only; physical phones remain unqualified.',
    'lightingScope':'Combined baked color/light atlas for static surfaces; five manifest-driven practicals with nearest-three active budget for actors. Static surfaces do not receive dynamic shadows.',
    'knownEmulatorIssue':'SwiftShader produced blank frames and shader link errors. Final checks used host GPU; rejected logs remain under ignored artifacts/android-swiftshader-failure. https://github.com/godotengine/godot/issues/109550'}
report['runtimeNativeSha256']=read(PACKAGE/'runtime/export.json')['nativeSha256']
report['formCheckEvidence']['shellManifoldBooleans']='form-preflight.json: evaluated shell, 108 shell rays and 96 low trim/aperture rays'
report['postmortem']={
    'observations':['A successful PNG request can still contain a blank 3D frame.','The original 3 m navigation grid missed the approved offset doorways.','Boolean-cut trim concealed a low collision bar.'],
    'corrections':['Rebuilt trim as explicit segments around doors and added 96 low-height aperture rays.','Added a 1.5 m navigation grid and capsule pruning for flat room links; preserved stair connectors.','Trimmed floor to 21 m so its edge meets the existing stair landing.','Fixed early-input access to the bag and the desktop F-key call.','Reject shader errors and low-variance blank captures; use emulator hardware graphics.'],
    'remainingRisks':['Human Runtime approval pending.','Physical-phone performance, thermal, audio listening and phone-to-phone Wi-Fi remain unqualified.','The bespoke mother character, whole-house art pass and rendered-film intro are not included in this room upgrade.','No signed or tested iOS binary.']}
report['proposedLessons']=[{'id':'aperture-trim-capsule','status':'pending','lesson':'Validate decorated openings near floor height and walk the complete progression route before release.'},{'id':'render-not-transport','status':'pending','lesson':'Reject runtime shader errors and blank frame content even when screenshot transport succeeds.'}]
write(PACKAGE/'final-report.json',report)
review=read(PACKAGE/'milestone-reviews.json')
review['runtime'].update(evidence=['runtime-review.html','runtime/integrity.json','runtime/export.json','runtime/nursery-view.png','runtime/nursery-hide.png','runtime/nursery-bed.png','runtime/nursery-drawers.png','runtime/nursery-view-low.png','../../../docs/validation-0.8.1'],
    strangestElement='The keeper still uses the existing credited creature asset; a bespoke corpse and mother character are outside this room upgrade.',
    notes='Integrated and tested local 0.8.1 candidate. Form-approved layout preserved; runtime clearance fixes documented in final-report.json. Human Runtime approval remains separate from the executed technical checks.')
write(PACKAGE/'milestone-reviews.json',review)
apk=files['WaitingForDawn-0.8.1.apk']
gallery=''.join('<figure><a href="runtime/'+name+'.png"><img src="runtime/'+name+'.png" alt="'+label+'"></a><figcaption>'+label+'</figcaption></figure>' for name,label in [
    ('nursery-drawers','Two dressers with 12 independently searchable drawers'),
    ('nursery-hide','Inside the wardrobe — actual mesh viewing slit'),
    ('nursery-bed','Under the bed — low camera and room visibility'),
    ('nursery-view-low','Lower texture detail — same geometry, smaller atlas')])
html='''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Waiting for Dawn · runtime review</title>
<style>*{box-sizing:border-box}body{margin:0;background:#101313;color:#ddd6c7;font:16px/1.6 system-ui,sans-serif}main{max-width:1180px;margin:auto;padding:36px 28px 70px}h1{font:52px/1.05 Georgia,serif;margin:10px 0 22px}h2{font:30px Georgia,serif;margin-top:40px}.eyebrow{color:#b9a778;letter-spacing:.14em;font-size:12px;text-transform:uppercase}.lede{max-width:760px;color:#bfbfb4}img{width:100%;display:block;border:1px solid #383c38}figure{margin:0 0 28px}figcaption{font-size:14px;color:#aead9e;padding:10px 0}.grid{display:grid;grid-template-columns:1fr 1fr;gap:24px}.status{padding:12px 18px;border-left:3px solid #9baf81;background:#1b211b;margin:24px 0}a{color:#c9d5b3}table{border-collapse:collapse;width:100%}td,th{text-align:left;padding:12px;border-bottom:1px solid #333}code{overflow-wrap:anywhere;font-size:12px}.limit{color:#bdb5a6}@media(max-width:700px){h1{font-size:38px}.grid{grid-template-columns:1fr}main{padding:24px 16px}}</style>
<main><div class="eyebrow">Waiting for Dawn · version 0.8.1 · 18 October 2026</div><h1>The nursery, inside the game.</h1>
<p class="lede">Your approved room is now playable: four connected spaces, a modeled cradle, hollow wardrobe, dressers, shelves and aged surfaces. These are captures from the signed Android APK running in the emulator.</p>
<div class="status">Layout approved · textured art approved · runtime review ready</div>
<figure><a href="runtime/nursery-view.png"><img src="runtime/nursery-view.png" alt="Android gameplay in Eleanor’s nursery"></a><figcaption>Actual Android gameplay. Baked room lighting, working HUD, shared bag and dawn clock.</figcaption></figure>
<h2>Search, hide and find your way out</h2><div class="grid">'''+gallery+'''</div>
<h2>What was checked</h2><table><tr><th>Check</th><th>Result and scope</th></tr>
<tr><td>Progression</td><td>CharacterBody walked all 12 keys, opened the garage and boarded. Ghost disabled in that route fixture; separate tests cover capture and endings.</td></tr>
<tr><td>Multiplayer</td><td>Two/four-process regression passed. Final APK joined Windows, searched a native drawer, synchronized the key and open state, rejected duplication, restarted and handled departure.</td></tr>
<tr><td>Visuals</td><td>Both texture tiers, wardrobe slit, under-bed camera and drawer views inspected. 83,876 room triangles, 16 runtime meshes.</td></tr>
<tr><td>Performance</td><td>15-second desktop and hardware-GPU emulator samples: p50/p95 frame time 16.67 ms at 60 FPS. This does not predict physical-phone performance.</td></tr>
<tr><td>Fixes</td><td>Door trim collisions, stair threshold snag, room navigation gaps, input before bag initialization and desktop flashlight key.</td></tr></table>
<h2>Build ready for review</h2><p>Signed Android APK: <strong>WaitingForDawn-0.8.1.apk</strong> · '''+f'{apk["bytes"]/1_000_000:.1f} MB'+''' · version code 9. Same package and signing certificate as 0.8.0. All multiplayer peers must update together.</p><p><code>SHA-256 '''+apk['sha256']+'''</code></p>
<p class="limit">This upgrade covers the nursery wing. Other rooms, the adapted ghost and narrated in-engine opening retain their existing art. Static room lighting is baked. Real-phone graphics, thermal behavior, headphone balance, phone-to-phone Wi-Fi and iOS remain unqualified. SwiftShader emulator rendering failed; the hardware-GPU captures shown here passed.</p>
<p><a href="runtime/integrity.json">Asset checks</a> · <a href="final-report.json">Runtime report</a> · <a href="nursery-form.blend">Editable Blender room</a></p>
<div class="status">The APK is available locally. GitHub publication waits for your runtime review approval.</div></main></html>'''
(PACKAGE/'runtime-review.html').write_text(html,encoding='utf-8')
print('RUNTIME_REVIEW_READY',apk['sha256'])
