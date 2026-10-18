"""Assemble the local review page and evidence, without publishing anything."""
from pathlib import Path
import json,hashlib
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'design/rooms/eleanors-nursery'
def read(name):return json.loads((OUT/name).read_text())
def write(name,data):(OUT/name).write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8',newline='\n')

assert read('milestone-reviews.json')['form']['status']!='approved', 'Preserve the approved Form record; create a new runtime review instead'
audit=read('form-preflight.json')
assert audit['technicalPreflight']=='PASS', 'Do not request a Form review with failing geometry checks'
names=['form-nursery','form-dresser','form-wardrobe','form-cradle-detail']+['form-corner-'+str(i) for i in range(1,5)]+['form-ceiling-up','form-ceiling-a','form-ceiling-b']
for name in names:assert (OUT/'renders'/(name+'.png')).is_file(),name
review=read('milestone-reviews.json');review['form'].update(evidence=['form-review.html','nursery-form.blend','form-preflight.json']+['renders/'+n+'.png' for n in names],strangestElement='The former empty 21 m chamber is now four rooms. The native keeper uses the existing zombie asset; a bespoke human corpse and mother character remain separate art work.',notes='Local Blender Form proposal; original human Function approval retained. No final game export, integration or deployment. Corrected support heights, shortened bed, added animation roots, restored source materials, and opened lamp shades.');write('milestone-reviews.json',review)
report=read('final-report.json')
report['gates']['function']=True
report['formChecks']={k:True for k in report['formChecks']}
report['formCheckEvidence']={'floorPlanParity':'plans/form-lower-room.png, plans/form-reflected-ceiling.png; minor support corrections described in form-adjustments.json','primaryArrival':'3 m approved aperture; 9 evaluated wall rays clear','symmetry':'Approved bilateral shell and declared functional prop exceptions retained','shellManifoldBooleans':'form-preflight.json evaluated shell and 108 aperture rays','collisions':'28 independent-prop BVH pair tests, no intersections','support':'Evaluated world-space bottom bounds, within -5 to +5 mm of floor','attachmentOrientation':'Floor-supported furniture; window joinery seated in the scheduled apertures','ceilingAttachmentOrientation':'Five ceiling roses meet the ceiling or beam underside; circular faces parallel to support','seatingOrientation':'Nursery chair faces cradle; reading chair rotated toward diary table','focalDistribution':'One cradle hero; no competing bright prop','heroClearance':'Cradle occupies approved reserve; independent furniture has no intersections','colonnades':'Not applicable; none present','screenClearance':'Production hero frame stays inside 4% viewport margins; corner/close-up visual inspection','scaleCamera':'Metre units; production vertical field of view 70 degrees and 1.65 m eye height','ceilingCoverage':'Center-up and opposed ceiling views','environmentCoverage':'Not applicable; no assigned equirectangular environment','provenance':'Generated walnut prompt plus existing asset licenses, all used textures packed'}
report['reviewRenders']['corners']=['renders/form-corner-'+str(i)+'.png' for i in range(1,5)]
report['reviewRenders']['ceiling']=['renders/form-ceiling-up.png','renders/form-ceiling-a.png','renders/form-ceiling-b.png']
report['formNativeSha256']=hashlib.sha256((OUT/'nursery-form.blend').read_bytes()).hexdigest()
report['postmortem']['remainingRisks']=['Form human approval pending','Texture baking and GLB reimport have not run','Godot lighting, collision, hiding cameras, navigation and mobile performance require runtime tests','Full project monster, story, audio and real-device qualification remain outstanding']
write('final-report.json',report)
write('form-adjustments.json',{'approvedLayoutPreserved':True,'corrections':['Cradle runners and storage box lowered to meet floor','Books seated on shelves','Diary table aligned under diary interaction, paper raised to table top','Bed shortened to remove toy-drawer overlap','Center ceiling rose attached to beam underside','Lamp shades opened so bulbs can illuminate room','Reading chair faces diary table','Native keeper texture restored from local original; unused rig display mesh removed'],'renderOnlyLighting':'Documented indirect-light approximation in lighting-manifest.json; must be baked or matched before runtime approval'})
html=(OUT/'review.html').read_text(encoding='utf-8')
html=html.replace('Nursery design review','Nursery material review').replace('Design proposal · approval pending','Layout approved · art review pending')
html=html.replace('href="validation.txt"','href="form-validation.txt"')
html=html.replace('the under-bed search box','the search box')
html=html.replace('renders/concept-cutaway.png','renders/form-nursery.png')
html=html.replace('Blender concept cutaway showing four connected rooms around the central passage','Textured Blender view of the approved nursery, cradle and keeper')
html=html.replace('Actual Blender concept geometry, shown in neutral clay. This is a layout preview, not the final textured room or a game screenshot.','Actual textured Blender render. Layout approval is recorded. This is the native art review; Android lighting, navigation and performance still need testing.')
html=html.replace('Inspect the proposed room','Inspect the textured room')
html=html.replace('plans/lower-room.png','plans/form-lower-room.png').replace('plans/reflected-ceiling.png','plans/form-reflected-ceiling.png')
html=html.replace('renders/nursery-eye-level.png','renders/form-nursery.png').replace('renders/dresser-eye-level.png','renders/form-dresser.png')
html=html.replace('Blender camera preview','Blender material preview').replace('Player-height clay preview. This checks furniture scale and placement, not final textures or horror lighting.','Player-height textured native render. Baked-light approximation is documented; mobile parity remains untested.')
html=html.replace('Masks have been traced to cutter contours; approval is pending.','The user approved these masks and dimensions at the layout stage.')
html=html.replace('Image-generated design references, not finished 3D assets.','Approved image-generated design references.').replace('The Blender file contains editable construction prototypes of these designs.','The new Blender file contains the textured furniture and separate drawer/wardrobe animation assemblies.')
html=html.replace('Approval state: Function pending · Form not started · Runtime not started','Approval state: Function approved by user · Form awaiting user review · Runtime not started')
html=html.replace('nursery-concept.blend','nursery-form.blend').replace('Download editable Blender concept','Download textured Blender room')
html=html.replace('Editable Blender concept, real apertures, two circulation loops','Textured native room, real apertures, two circulation loops').replace('Approved composition, final surfaces, collision and ghost-route checks','Runtime export, collision and ghost-route checks')
html=html.replace('Three reference designs and modeled construction prototypes','Textured furniture; 12 drawer roots and two wardrobe door pivots').replace('UVs, aged PBR textures, animation pivots, mobile LODs','Delivery UV/bake conversion, mobile LODs and animation integration')
html=html.replace('Fixture locations and story-driven room arrangement','Documented fixture manifest and reviewed native lighting').replace('Runtime lighting, audio balancing and scare timing','Baking/runtime lighting, audio balancing and scare timing')
html=html.replace('No engine migration, external paid asset service, or new production export is performed in this proposal.','No engine migration, external paid asset service, or game export has been performed.')
html=html.replace('Function-stage review package · 18 October 2026','Form-stage review package · 18 October 2026')
gallery='<section class="divider"><div class="eyebrow">Native art inspection</div><h2>Close-ups, corners and ceiling</h2><div class="cards">'
for name in ['form-wardrobe','form-cradle-detail']+['form-corner-'+str(i) for i in range(1,5)]+['form-ceiling-up','form-ceiling-a','form-ceiling-b']:
    gallery+='<a href="renders/'+name+'.png"><img style="width:100%;border-radius:6px" src="renders/'+name+'.png" alt="'+name.replace('-',' ')+'"></a>'
gallery+='</div><p class="note">Four corner views use a deliberately wide 120° field of view for coverage. They are inspection views, not the gameplay camera. All used source textures are packed into the native Blender file. <a href="form-preflight.json">Read measured checks</a>.</p></section>'
html=html.replace('</main>',gallery+'</main>')
(OUT/'form-review.html').write_text(html,encoding='utf-8',newline='\n')
print('LOCAL_FORM_REVIEW_READY',audit['triangles'],'triangles; human Form approval remains pending')
