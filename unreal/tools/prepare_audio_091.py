"""Local neural narration and CC0 human vocal sound design; no credentials required.
Dependencies live outside the project. Originals and receipts retain provenance.
"""
from pathlib import Path
import sys, urllib.request, hashlib, json
sys.path.insert(0,'E:/WaitingForDawnTools/Audio/python')
import numpy as np
import soundfile as sf
from kokoro_onnx import Kokoro
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'unreal/Audio'; OUT.mkdir(exist_ok=True)
RAW=OUT/'sources'; RAW.mkdir(exist_ok=True)
sources=[('breath','https://cdn.freesound.org/previews/151/151206_140737-hq.mp3','https://freesound.org/people/OwlStorm/sounds/151206/','OwlStorm'),('scream','https://cdn.freesound.org/previews/169/169811_1122547-hq.mp3','https://freesound.org/people/missozzy/sounds/169811/','missozzy')]
SR=24000
def mono(path,rate=1.):
    a,s=sf.read(path);a=a.mean(axis=1) if a.ndim>1 else a
    return np.interp(np.arange(int(len(a)*SR/s/rate))*s*rate/SR,np.arange(len(a)),a)
def norm(a,peak=.65):return a*peak/max(np.max(np.abs(a)),.001)
def fade(a,seconds=.025):
    a=a.copy();n=min(int(SR*seconds),len(a)//2);a[:n]*=np.linspace(0,1,n);a[-n:]*=np.linspace(1,0,n);return a
def write(name,a):sf.write(OUT/(name+'.wav'),fade(a),SR,subtype='PCM_16')
for name,url,page,author in sources:
    p=RAW/(name+'.mp3')
    if not p.exists():urllib.request.urlretrieve(url,p)
breath=mono(RAW/'breath.mp3')
print('SOURCE_LENGTHS',len(breath)/SR,len(mono(RAW/'scream.mp3'))/SR,flush=True)
# Preserve human articulation; restrained pitch shift, layered room echoes only.
scream=mono(RAW/'scream.mp3',.82)
def room(a):
    out=np.pad(a,(0,int(SR*.8)))
    for delay,gain in [(0.079,.16),(.137,.12),(.231,.08),(.409,.04)]:
        n=int(delay*SR);out[n:n+len(a)]+=a*gain
    return out
write('stinger',norm(room(scream),.72))
warning=np.zeros(SR*5)
b=norm(breath[:SR*4],.25);warning[:len(b)]+=b
tail=norm(scream[int(.65*SR):],.13);start=int(1.4*SR);warning[start:start+min(len(tail),len(warning)-start)]+=tail[:len(warning)-start]
write('wail',norm(room(warning),.5))
# A breathing cycle with a quiet crossfade instead of the old filtered white-noise loop.
loop=breath[:min(len(breath),SR*6)];loop=norm(loop,.4);n=SR//4
loop[:n]=loop[:n]*np.linspace(0,1,n)+loop[-n:]*np.linspace(1,0,n);loop=loop[:-n]
write('breath',loop)
lines=[
 'We were students on a midnight trip. That house should have been empty. Then the front door slammed shut.',
 'Upstairs, we found the keeper. Dead for days. We tried to leave, but not a single door would open.',
 'Eleanor lived here with her children. After the fire, she locked every room, still waiting for them to return.',
 'There was a letter in his hand. Find the keys. Reach the garage. Start the car... before dawn.'
]
k=Kokoro('E:/WaitingForDawnTools/Audio/models/kokoro-v1.0.onnx','E:/WaitingForDawnTools/Audio/models/voices-v1.0.bin')
# The 0.4.7 wrapper supplies int32 speed for this float-input ONNX export.
# Coerce against the model contract without changing installed package files.
class TypedSession:
    def __init__(self,session):self.session=session
    def __getattr__(self,name):return getattr(self.session,name)
    def run(self,outputs,inputs):
        inputs=dict(inputs);inputs['speed']=inputs['speed'].astype(np.float32)
        return self.session.run(outputs,inputs)
k.sess=TypedSession(k.sess)
assert 'bm_george' in k.get_voices()
parts=[]
for i,line in enumerate(lines):
    speed=1.0
    for attempt in range(3):
        a,s=k.create(line,voice='bm_george',speed=speed,lang='en-gb')
        if len(a)/s<=8.6:break
        speed*=len(a)/s/8.5
    assert len(a)/s<=8.8,(i,len(a)/s)
    print('NARRATION',i,len(a)/s,speed,flush=True)
    a=fade(norm(a,.64));parts.append(np.pad(a,(int(.12*s),9*s-len(a)-int(.12*s))))
write('introduction',np.concatenate(parts))
receipt={'narrator':{'engine':'Kokoro v1.0 / kokoro-onnx 0.4.7','voice':'bm_george','license':'Apache-2.0 model','source':'https://huggingface.co/hexgrad/Kokoro-82M','script':lines,'synthetic':True},'recordings':[{'author':author,'source':page,'download':url,'license':'CC0-1.0','sha256':hashlib.sha256((RAW/(name+'.mp3')).read_bytes()).hexdigest()}for name,url,page,author in sources],'outputs':{p.name:{'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'seconds':sf.info(p).duration,'peak':float(np.max(np.abs(sf.read(p)[0])))}for p in OUT.glob('*.wav')}}
(OUT/'provenance.json').write_text(json.dumps(receipt,indent=2)+'\n')
print('AUDIO_READY',flush=True)
