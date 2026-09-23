from pathlib import Path
import urllib.request,re
for id,name in [(320659,'great'),(320660,'excellent'),(320661,'awesome')]:
    html=urllib.request.urlopen(f'https://freesound.org/people/rhodesmas/sounds/{id}/').read().decode()
    urls=re.findall(r'https://[^\s"<>]+(?:mp3|ogg)',html)
    print(name, sorted(set(urls)))
    Path(f'output/voice-{name}.html').write_text(html,encoding='utf-8')
