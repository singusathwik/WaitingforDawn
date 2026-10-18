"""Create the proposed room contract. Human approvals deliberately remain empty."""
from pathlib import Path
import json
import shutil
import subprocess
import sys
from PIL import Image, ImageDraw, ImageFont

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'design/rooms/eleanors-nursery'
SKILL=Path.home()/'.codex/plugins/cache/openai-curated-remote/build-3d-game-rooms/0.3.3/skills/build-3d-game-rooms'
if (OUT/'function-approval.json').exists():
    raise SystemExit('This proposal has human approval. Preserve its record; make a versioned revision instead of resetting it.')

def read(name):return json.loads((OUT/name).read_text(encoding='utf-8'))
def write(name,obj):(OUT/name).write_text(json.dumps(obj,indent=2)+'\n',encoding='utf-8',newline='\n')

sources={'cradle':'exec-04878970-145e-479d-bc23-1cdfafa5f9c4.png','wardrobe':'exec-7402a1f5-a3dd-4dc4-9d7b-2b3dd0bee222.png','dresser':'exec-f6ce16de-0b82-483e-b201-9bcf2da6aba0.png'}
for name,file in sources.items():
    source=Path.home()/'.codex/generated_images/01a14a7e-d9fd-7bc2-a5e0-d98758f71661'/file
    shutil.copyfile(source,OUT/'images'/f'{name}.png')

surfaces=[]
def surface(id,location,dimensions,wall=False,ceiling=False):surfaces.append(dict(id=id,location=location,dimensions=dimensions,wall=wall,ceiling=ceiling))
surface('floor',[0,0,-.18],[21.4,21.4,.36])
surface('ceiling',[0,0,3.75],[21.4,21.4,.3],ceiling=True)
for id,x,y,dx,dy in [('west',-10.5,0,.3,21.3),('east',10.5,0,.3,21.3),('north',0,10.5,21.3,.3),('south',0,-10.5,21.3,.3),('north-divider',0,1.8,21,.18),('south-divider',0,-1.8,21,.18),('north-midwall',0,6.15,.18,8.7),('south-midwall',0,-6.15,.18,8.7)]:surface(id,[x,y,1.8],[dx,dy,3.6],wall=True)
openings=[]
def opening(id,wall,loc,width,height,kind,destination,axis='y',sill=0):
    size=[width,.9,height] if axis=='y' else [.9,width,height]
    op=dict(id=id,wallId=wall,location=loc,cutterDimensions=size,kind=kind,widthMeters=width,heightMeters=height,depthMeters=.3,thresholdMeters=0,sillMeters=sill,destination=destination,mask=f'masks/{id}.png',cutter=f'masks/{id}.json',approved=False)
    openings.append(op)
opening('west-arrival','west',[-10.5,0,1.7],3,3.4,'door','Existing stair to the ground floor','x')
opening('east-exit','east',[10.5,0,1.7],3,3.4,'door','Existing east wing and service stair','x')
for wall,y in [('north-divider',1.8),('south-divider',-1.8)]:
    for side,x in [('west',-5),('east',5.5)]: opening(wall+'-'+side,wall,[x,y,1.4],2.4,2.8,'door','Open internal passage; no extra lock or door leaf')
opening('north-loop','north-midwall',[0,6,1.4],2.4,2.8,'door','Dressing room to nursery loop','x')
opening('south-loop','south-midwall',[0,-6,1.4],2.4,2.8,'door','Reading room to attendant room loop','x')
for side,y in [('north',10.5),('south',-10.5)]:
    for index,x in enumerate([-5,5]):opening(side+'-window-'+str(index+1),side,[x,y,2.05],2.8,1.5,'window','Exterior backing; barred and non-traversable',sill=1.3)
schedule=read('openings.json');schedule.update(primaryArrival={'openingId':'west-arrival','exception':''},openings=openings);write('openings.json',schedule)
for op in openings:
    im=Image.new('L',(256,256),0);draw=ImageDraw.Draw(im)
    draw.rectangle((32,24,223,255 if op['kind']=='door' else 231),fill=255)
    im.save(OUT/op['mask'])
    cmd=[sys.executable,str(SKILL/'scripts/trace_opening_mask.py'),str(OUT/op['mask']),'--id',op['id'],'--kind',op['kind'],'--width-m',str(op['widthMeters']),'--height-m',str(op['heightMeters']),'--out',str(OUT/op['cutter']),'--preview',str((OUT/op['cutter']).with_suffix('.preview.png'))]
    if op['kind']=='window':cmd+=['--sill-m',str(op['sillMeters'])]
    subprocess.run(cmd,check=True,capture_output=True,text=True)
subprocess.run([sys.executable,str(SKILL/'scripts/compose_opening_contact_sheet.py'),str(OUT/'openings.json'),'--package',str(OUT),'--out',str(OUT/'plans/openings.png')],check=True)

prompts=read('images/prompts.json')['prompts']
assets=[]
for id,role,dims,count,poly,kind in [('cradle','Story focal object; separated rocking runners and slats',[1.6,.85,1.16],1,12000,'hero'),('wardrobe','Single-player hiding with real 50 mm eye slit and two pivoted leaves',[2,1.68,2.42],1,8000,'reusable'),('dresser','Six individually searchable drawers with independent animation pivots',[3.58,.88,1.7],2,9000,'reusable')]:
    assets.append(dict(id=id,function=role,description='Aged walnut, restrained Victorian joinery and tarnished hardware; see isolated proposal',**{'class':kind},dimensionsMeters=dims,attachmentFace='floor',semanticFront='negative-y',intendedInstances=count,targetPolycount=poly,rejectionCriteria=['Floating support or fused moving parts','Missing interior or rear surface','Dimensions obstruct existing interaction approach','Wardrobe eye slit or bed visibility is obstructed','Mobile geometry exceeds assigned budget'],productionMethod='Local editable Blender mesh; no Meshy request authorized',image=dict(source=f'images/{id}.png',prompt=prompts[id],generator='Built-in image_gen; model identifier not supplied',approved=False,approvedBy=''),attempts=[]))
props=read('props.json');props['assets']=assets
props['generation'].update(hardCreditCeiling=0,creditsPerTexturedTask=15,pricingVerifiedAt='',disabled=True,reason='No paid Meshy work requested. Local Blender authoring selected. Bundled validator requires Meshy even for local-only concepts; report this without fabricating pricing or approval.')
write('props.json',props)
layout=read('room-layout.json');layout.update(surfaces=surfaces,instances=[dict(id='cradle-1',assetId='cradle',location=[6,6,0],rotationDegrees=[0,0,0]),dict(id='wardrobe-1',assetId='wardrobe',location=[-6,3,0],rotationDegrees=[0,0,90]),dict(id='dresser-1',assetId='dresser',location=[-3,6,0],rotationDegrees=[0,0,0]),dict(id='toy-drawers',assetId='dresser',location=[6,-6,0],rotationDegrees=[0,0,0])],coordinateMapping='Godot = (75 + X, 5 + Z, 9 - Y)',existingGameplayFixtures=[dict(id='bed-hide',location=[3,-6,0],entry=[1,-6,0]),dict(id='under-bed-box',location=[-3,-6,.65]),dict(id='keeper-body',location=[6,3,.3]),dict(id='diary',location=[-6,-3,.82])],builtInFeatures=['Wall skirting and picture rails','Four toy/book shelf bays','Four sealed exterior windows with reveals and sills','Five ceiling-mounted light fixtures','Timber ceiling beams'],circulation=[dict(id='main',points=[[-12,0,0],[12,0,0]],width=3.42),dict(id='north-loop',points=[[-5,0,0],[-5,6,0],[5.5,6,0],[5.5,0,0]],minimumOpeningWidth=2.4),dict(id='south-loop',points=[[-5,0,0],[-5,-6,0],[5.5,-6,0],[5.5,0,0]],minimumOpeningWidth=2.4)])
camera=dict(viewport=[1280,720],location=[2.1,3.1,1.65],target=[6,6,.8],verticalFovDegrees=70)
layout['existingGameplayFixtures'][0].update(proposedDimensionsMeters=[2.2,1.9,1.75],change='Shorten frame from 2.9 m to 2.2 m; keep hiding anchor and entry')
layout['productionCamera']=camera;write('room-layout.json',layout)
brief=read('room-brief.json');brief.update(purpose='Eleanor nursery wing: find the dead keeper, infer the family tragedy, search two sets of six drawers and evade the mother through connected rooms.',runtimeSurface='Existing Godot 4.5.2 Android first-person cooperative game; no engine migration',boundsMeters=[21,21,3.6],hero=dict(id='cradle',role='Empty cradle establishes the mother and lost-child theme without a key-location label',reservedBoundsMeters=[3,2.5,2.1]),symmetry=dict(mode='bilateral',order=2,appliesTo=['architecture','barriers','circulation','repeatedProps'],exceptions=['Existing interaction anchors stay fixed; furniture is intentionally asymmetric','West internal opening at X=-5 and east at X=5.5 preserve access to the keeper','One cradle in the northeast room establishes the hero hierarchy']),circulation=dict(description='3.42 m clear central corridor, 2.4 m internal openings, two cross-room loops; player radius .32 m and ghost radius .4 m must be verified in runtime. Door sweeps and hiding entry reserves stay clear.',minimumClearanceMeters=1.2),productionCamera=camera,performanceBudget=dict(maxSceneTriangles=250000,maxVLowBytes=8000000,maxHighTextureBytes=24000000),creditBudget=dict(maximumCredits=0,approvalRequired=True),artifacts=dict(floorPlan='plans/lower-room.png',reflectedCeilingPlan='plans/reflected-ceiling.png',planMetadata='plan-metadata.json',wallElevations=['plans/elevation-north.png','plans/elevation-south.png'],visualTarget='images/prop-contact-sheet.png',openingContactSheet='plans/openings.png'))
write('room-brief.json',brief)
plan=read('plan-metadata.json');plan['coverage']=['room-outline','cutouts','openings','exterior-apron','main-sign','ingress-props','floor-markers','barriers','columns','circulation','placed-features'];plan['coverageNotes']={'main-sign':'None proposed; no floating in-world labels','floor-markers':'Review-only corridor dashes, excluded from gameplay','columns':'None; load-bearing walls and ceiling beams','projectionSourceDetail':'Orthographic Blender Cycles render of the actual concept meshes; ceiling collection rendered separately'};write('plan-metadata.json',plan)
review=read('milestone-reviews.json');review['function'].update(evidence=['review.html','plans/lower-room.png','images/prop-contact-sheet.png','plans/openings.png','nursery-concept.blend'],strangestElement='A 21 m nursery is implausibly large as one room; four connected domestic spaces address that scale. The oversized original 3 m double doors remain to preserve gameplay.',notes='Layout and prop references proposed, not approved. No paid generation, final composition, export, or deployment.');write('milestone-reviews.json',review)
report=read('final-report.json');report['postmortem']['remainingRisks']=['Function approval pending','Final materials and production topology not yet authored','Ghost navigation and hiding visibility require a real Godot integration test','The stock validator assumes paid Meshy assets and is not compatible with a zero-spend local authoring path'];write('final-report.json',report)
sheet=Image.new('RGB',(1800,730),'#eeeae3');draw=ImageDraw.Draw(sheet)
font=ImageFont.truetype('C:/Windows/Fonts/georgia.ttf',25)
small=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',20)
for i,(id,label,desc) in enumerate([('cradle','01 / Eleanor\u2019s cradle','Story focal point'),('wardrobe','02 / Slotted wardrobe','Hide and watch the doorway'),('dresser','03 / Six-drawer dresser','Six independent searches')]):
    im=Image.open(OUT/'images'/f'{id}.png');im.thumbnail((580,570))
    sheet.paste(im,(i*600+(600-im.width)//2,20+(570-im.height)//2))
    draw.text((i*600+24,610),label,font=font,fill='#222222');draw.text((i*600+24,652),desc,font=small,fill='#555555')
sheet.save(OUT/'images/prop-contact-sheet.png')
print('NURSERY_REVIEW_CONTRACT_PREPARED; approvals remain pending')
