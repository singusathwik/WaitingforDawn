"""Deterministic original synthesis; no downloaded samples. Requires numpy."""
from pathlib import Path
import wave
import numpy as np

ROOT = Path(__file__).resolve().parents[1] / 'assets' / 'audio'
ROOT.mkdir(parents=True, exist_ok=True)
SR = 22050
rng = np.random.default_rng(8713)

def write(name, seconds, fn, loop=False):
    t = np.arange(int(seconds * SR)) / SR
    noise = rng.uniform(-1, 1, len(t))
    x = fn(t, noise)
    if not loop:
        x *= np.minimum(t * 150, 1) * np.minimum((seconds-t)*30, 1)
    x = np.clip(x, -.95, .95)
    with wave.open(str(ROOT / (name + '.wav')), 'wb') as f:
        f.setparams((1, 2, SR, len(x), 'NONE', 'not compressed'))
        f.writeframes((x * 32767).astype('<i2').tobytes())

write('foot_wood', .32, lambda t,n: (np.sin(2*np.pi*(92*t-50*t*t))*.5+n*.22)*np.exp(-t*23))
write('foot_stone', .27, lambda t,n: (np.sin(2*np.pi*170*t)*.28+n*.36)*np.exp(-t*30))
write('glass', 1.1, lambda t,n: (n*.35 + sum(np.sin(2*np.pi*f*t)*.07 for f in [1703,2371,3197,4201]))*np.exp(-t*7))
write('door', 1.5, lambda t,n: np.sin(2*np.pi*(120*t+45*t*t))*.13*np.exp(-t*2)+ (n*.45+np.sin(2*np.pi*48*t)*.4)*np.exp(-t*12))
write('chair', .9, lambda t,n: (np.sin(2*np.pi*(310*t+35*np.sin(t*12)))*.2+n*.16)*np.exp(-t*5))
write('key', 1.2, lambda t,n: sum(np.sin(2*np.pi*f*t)*a*np.exp(-t*d) for f,a,d in [(880,.25,4),(1320,.16,6),(2112,.1,8)]))
write('stinger', 2.5, lambda t,n: (sum(np.sin(2*np.pi*f*t)*.10 for f in [43,61,113,119,241])+n*.12)*np.exp(-t*1.8))
write('breath', 2.0, lambda t,n: np.convolve(n,np.ones(30)/30,'same')*np.sin(np.pi*t/2)**2*.9)
write('creak', 3.0, lambda t,n: (np.sin(2*np.pi*(180*t+6*np.sin(t*4)))*.22+n*.05)*np.sin(np.pi*t/3)**2)
write('engine', 4.0, lambda t,n: (np.sin(2*np.pi*(28*t+8*t*t))*.3+np.sin(2*np.pi*94*t)*.1+n*.13)*np.minimum(t,1))
# Loop harmonics are exact multiples of 1/12 Hz; no seam discontinuity.
write('ambient', 12, lambda t,n: (np.sin(2*np.pi*36*t)*.12+np.sin(2*np.pi*(36+1/12)*t)*.09+np.sin(2*np.pi*61*t)*.035)*(0.7+0.3*np.cos(2*np.pi*t/12)), True)
write('pursuit', 8, lambda t,n: (np.sin(2*np.pi*47*t)*.24+np.sin(2*np.pi*71*t)*.1)*(np.exp(-((t%0.8)/.09))+.55*np.exp(-(((t+.16)%0.8)/.06))), True)
print('Generated', len(list(ROOT.glob('*.wav'))), 'original sound assets')

# Original rising spectral warning, band-limited harmonics with a breathy envelope.
write("wail", 2.8, lambda t,n: (sum(np.sin(2*np.pi*k*(170*t+48*t*t+2*np.sin(t*9)))*(.18/k) for k in range(1,7))+np.convolve(n,np.ones(16)/16,"same")*.2)*np.sin(np.pi*t/2.8)**2)
