"""Exercise the signed APK on the named emulator through in-game test fixtures.

Captures come from Godot's viewport API and a loopback HTTP collector, not desktop UI input.
"""
from pathlib import Path
import subprocess,time,threading,argparse,json
from PIL import Image,ImageStat
from http.server import HTTPServer,BaseHTTPRequestHandler
ROOT=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser();parser.add_argument('--network',action='store_true');parser.add_argument('--wide',action='store_true');parser.add_argument('--skip-install',action='store_true');parser.add_argument('--mode',choices=['nursery-view','nursery-hide','nursery-bed','nursery-drawers','nursery-benchmark','repair-home','repair-parlour','repair-door','repair-kitchen','repair-garage','repair-drawer','repair-stairs','repair-exterior']);args=parser.parse_args()
adb=Path.home()/'.cache/wired-android/sdk/platform-tools/adb.exe'
godot=Path.home()/'.cache/hollow-house/engine/Godot_v4.5.2-stable_win64.exe'
out=ROOT/'artifacts/android-083';out.mkdir(exist_ok=True)
def call(*argv,timeout=90,check=True):
    return subprocess.run([str(adb),'-s','emulator-5554',*argv],capture_output=True,timeout=timeout,check=check)
call('start-server');call('reconnect','offline',check=False)
call('wait-for-device')
for i in range(45):
    if call('shell','getprop','sys.boot_completed').stdout.strip()==b'1':break
    time.sleep(1)
else:raise RuntimeError('Emulator did not boot')
print('ANDROID READY',call('shell','getprop','ro.build.version.release').stdout.decode().strip(),flush=True)
if not args.skip_install:
    print(call('install','-r',str(ROOT/'artifacts/WaitingForDawn-0.8.3.apk'),timeout=180).stdout.decode().strip(),flush=True)
call('reverse','tcp:8871','tcp:8871')
package='org.hollowhouse.lastride';prefix=''
class Collector(BaseHTTPRequestHandler):
    def do_POST(self):
        size=int(self.headers.get('Content-Length','0'))
        if not 0<size<10_000_000:self.send_error(413);return
        data=self.rfile.read(size)
        if not data.startswith(b'\x89PNG'):self.send_error(415);return
        (out/(prefix+'.png')).write_bytes(data)
        self.send_response(200);self.end_headers();self.wfile.write(b'OK')
    def log_message(self,*args):pass
server=HTTPServer(('127.0.0.1',8871),Collector)
threading.Thread(target=server.serve_forever,daemon=True).start()
try:
    if args.wide: call('shell','wm','size','1080x2400')
    if not args.network:
        for mode,extra in [('nursery-view',[]),('nursery-hide',[]),('nursery-bed',[]),('nursery-drawers',[]),('nursery-view',['--nursery-low']),('nursery-benchmark',[]),('repair-home',[]),('repair-parlour',[]),('repair-door',[]),('repair-kitchen',[]),('repair-garage',[]),('repair-drawer',[]),('repair-stairs',[]),('repair-exterior',[])]:
            if args.mode and (mode!=args.mode or extra):continue
            prefix=mode+('-low' if extra else '')
            (out/(prefix+'.png')).unlink(missing_ok=True)
            call('shell','am','force-stop',package);call('logcat','-c')
            parameters=','.join(['--','--test='+mode,'--report-render']+extra)
            call('shell','am','start','-n',package+'/com.godot.game.GodotApp','--esa','command_line_params',parameters)
            completed=False
            for step in range(70):
                time.sleep(1)
                log=call('logcat','-d','-s','godot:V','AndroidRuntime:E').stdout.decode(errors='replace')
                if 'ERROR:' in log or 'FATAL EXCEPTION' in log:
                    (out/(prefix+'.log')).write_text(log,encoding='utf-8')
                    raise RuntimeError(log[-4000:])
                if 'NURSERY RENDER '+mode in log or 'REPAIR RENDER '+mode in log:
                    (out/(prefix+'.log')).write_text(log,encoding='utf-8');completed=True;break
            assert completed and (out/(prefix+'.png')).is_file(), 'Missing Android render: '+prefix
            with Image.open(out/(prefix+'.png')) as capture:
                # Exclude HUD borders: an error can leave only the 2D HUD visible.
                w,h=capture.size
                if args.wide: assert abs(w/h-2400/1080)<.015, f'Letterboxed viewport: {w}x{h}'
                scene=capture.convert('RGB').crop((w//4,h//4,3*w//4,3*h//4))
                assert max(ImageStat.Stat(scene).stddev)>4, 'Blank Android 3D viewport: '+prefix
            print('ANDROID PASS',prefix,flush=True)
    else:
        call('shell','am','force-stop',package);call('logcat','-c')
        with (out/'host.log').open('wb') as stream:
            host=subprocess.Popen([str(godot),'--headless','--path',str(ROOT),'--','--test=room-host'],stdout=stream,stderr=subprocess.STDOUT,creationflags=subprocess.CREATE_NO_WINDOW)
            try:
                time.sleep(2)
                call('shell','am','start','-n',package+'/com.godot.game.GodotApp','--esa','command_line_params','--,--test=room-client,--server=10.0.2.2')
                assert host.wait(timeout=80)==0,'Desktop host failed'
                time.sleep(3)
                log=call('logcat','-d','-s','godot:V','AndroidRuntime:E').stdout.decode(errors='replace');(out/'client.log').write_text(log,encoding='utf-8')
                assert 'SEARCH CLIENT PASS' in log and 'ERROR:' not in log and 'FATAL EXCEPTION' not in log,log[-4000:]
                print('ANDROID-WINDOWS PASS native drawer key, shared state, duplicate use, restart and disconnect',flush=True)
            finally:
                if host.poll() is None:host.terminate()
finally:
    call('shell','am','force-stop',package,check=False)
    call('reverse','--remove','tcp:8871',check=False)
    if args.wide: call('shell','wm','size','reset',check=False)
    server.shutdown()
