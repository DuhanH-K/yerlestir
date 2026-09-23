import math, struct, wave
from pathlib import Path
root=Path('assets/sounds')
def save(name,duration,fn):
    rate=22050
    with wave.open(str(root/name),'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(rate)
        w.writeframes(b''.join(struct.pack('<h',int(max(-1,min(1,fn(i/rate)))*20000)) for i in range(int(rate*duration))))
save('place.wav',.16,lambda t: math.sin(2*math.pi*(600+900*t)*t)*math.exp(-25*t)*.45)
save('clear.wav',.6,lambda t: sum(math.sin(2*math.pi*f*t) for f in [523.25,659.25,783.99])/3*math.sin(math.pi*t/.6)**2*.5)
notes=[261.63,329.63,392,523.25,440,392,329.63,293.66,261.63,349.23,440,523.25,493.88,392,329.63,293.66]
def music(t):
    k=int(t/.75); u=t% .75
    melody=math.sin(2*math.pi*notes[k%len(notes)]*t)*math.sin(math.pi*u/.75)**2*.22
    chord=sum(math.sin(2*math.pi*f*t) for f in [130.813,164.814,195.998])*.022
    return (melody+chord)*min(1,t/.3,(12-t)/.3)
save('music.wav',12,music)

# Pre-rendered staggered bubble pops avoid per-pop player startup latency.
for count in range(8,65):
    step=min(.028,.300/max(1,count-1))
    def pops(t,count=count,step=step):
        value=0.0
        for rank in range(count):
            u=t-(.080+rank*step)
            if 0 <= u < .14:
                frequency=950+rank%5*45
                phase=2*math.pi*frequency*(1-math.exp(-22*u))/22
                value += math.sin(phase)*math.exp(-38*u)*.48
        return value
    save(f'pop_{count}.wav',.6,pops)
