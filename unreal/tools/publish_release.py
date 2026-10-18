"""Publish a reviewed APK using Git's existing credential helper; never print secrets."""
from pathlib import Path
import argparse, hashlib, http.client, json, subprocess, urllib.parse, urllib.request, urllib.error

p=argparse.ArgumentParser()
p.add_argument('--apk',type=Path,required=True)
p.add_argument('--body',type=Path,required=True)
p.add_argument('--tag',default='unreal-v0.9.1')
p.add_argument('--commit',required=True)
args=p.parse_args()
version=args.tag.removeprefix('unreal-v')
repo='singusathwik/WaitingforDawn'
credential=subprocess.run(['git','credential','fill'],input='protocol=https\nhost=github.com\n\n',text=True,capture_output=True,check=True)
fields=dict(line.split('=',1) for line in credential.stdout.splitlines() if '=' in line)
token=fields.get('password')
if not token:raise RuntimeError('GitHub credential unavailable')
headers={'Authorization':'Bearer '+token,'Accept':'application/vnd.github+json','X-GitHub-Api-Version':'2022-11-28','User-Agent':'WaitingForDawn-release'}
def api(path,data=None):
    request=urllib.request.Request('https://api.github.com'+path,headers=headers,data=json.dumps(data).encode() if data is not None else None)
    if data is not None:request.add_header('Content-Type','application/json')
    with urllib.request.urlopen(request,timeout=60) as r:return json.load(r)
identity=api('/user')['login']
if identity.lower()!='singusathwik':raise RuntimeError('Unexpected authenticated GitHub account')
try:release=api('/repos/'+repo+'/releases/tags/'+urllib.parse.quote(args.tag))
except urllib.error.HTTPError as e:
    if e.code!=404:raise
    release=api('/repos/'+repo+'/releases',{'tag_name':args.tag,'target_commitish':args.commit,'name':'Waiting for Dawn — Unreal '+version,'body':args.body.read_text(encoding='utf-8'),'draft':False,'prerelease':True})
digest=hashlib.file_digest(args.apk.open('rb'),'sha256').hexdigest()
name='WaitingForDawn-Unreal-'+version+'-arm64.apk'
existing=next((a for a in release['assets'] if a['name']==name),None)
if existing:
    if existing.get('digest')!='sha256:'+digest:raise RuntimeError('An asset with different content already exists; refusing silent replacement')
    asset=existing
else:
    url=urllib.parse.urlsplit(release['upload_url'].split('{')[0]+'?name='+urllib.parse.quote(name))
    conn=http.client.HTTPSConnection(url.hostname,timeout=180)
    conn.putrequest('POST',url.path+'?'+url.query)
    for k,v in headers.items():conn.putheader(k,v)
    conn.putheader('Content-Type','application/vnd.android.package-archive')
    conn.putheader('Content-Length',str(args.apk.stat().st_size));conn.endheaders()
    with args.apk.open('rb') as f:
        while chunk:=f.read(1024*1024):conn.send(chunk)
    response=conn.getresponse();body=response.read()
    if response.status not in (200,201):raise RuntimeError('Upload failed HTTP '+str(response.status))
    asset=json.loads(body)
if asset.get('digest')!='sha256:'+digest:raise RuntimeError('Published asset digest does not match local APK')
print(json.dumps({'release':release['html_url'],'download':asset['browser_download_url'],'bytes':asset['size'],'sha256':digest,'commit':args.commit},indent=2))
