from pathlib import Path
import requests,json,hashlib
from concurrent.futures import ThreadPoolExecutor
ROOT=Path(__file__).resolve().parents[1]
headers={'User-Agent':'HollowHouseAssetBuild/0.4'}
manifest=[]
def get(url):
 r=requests.get(url,headers=headers,timeout=90);r.raise_for_status();return r

def save(info,path):
 path.parent.mkdir(parents=True,exist_ok=True)
 if not path.exists():path.write_bytes(get(info['url']).content)
 data=path.read_bytes()
 assert hashlib.md5(data).hexdigest()==info['md5'],path
 manifest.append({'path':path.relative_to(ROOT).as_posix(),'url':info['url'],'sha256':hashlib.sha256(data).hexdigest()})

def model(name):
 meta=get('https://api.polyhaven.com/files/'+name).json()
 info=meta['gltf']['1k']['gltf'];base=ROOT/'assets/models'/name
 save(info,base/(name+'.gltf'))
 for relative,f in info['include'].items():save(f,base/relative)
 print('MODEL',name,flush=True)

def texture(name):
 meta=get('https://api.polyhaven.com/files/'+name).json()
 for key in ['diff','nor_gl','rough']:
  info=meta[{'diff':'Diffuse','rough':'Rough'}.get(key,key)]['1k']['jpg'];save(info,ROOT/'assets/textures'/name/(key+'.jpg'))
 print('TEXTURE',name,flush=True)
if __name__=='__main__':
 jobs=[(model,n) for n in ['ClassicConsole_01','GothicCabinet_01','ArmChair_01','Lantern_01']]+[(texture,n) for n in ['decrepit_wallpaper','old_wooden_floor_01','rough_plaster_broken','quatrefoil_jacquard_fabric']]
 with ThreadPoolExecutor(max_workers=3) as pool:
  list(pool.map(lambda job:job[0](job[1]),jobs))
 (ROOT/'assets/asset-manifest.json').write_text(json.dumps(manifest,indent=2))
