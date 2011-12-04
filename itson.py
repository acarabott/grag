import urllib
import random
import os

from pyechonest import config
from pyechonest import sandbox

import echonest.audio as audio

config.ECHO_NEST_API_KEY = "YLTCU72SODVIC00NB"
config.ECHO_NEST_CONSUMER_KEY = 'd0fe2f9558fb209037fc49a4227ac81d'
config.ECHO_NEST_SHARED_SECRET = '9QNMqlVDQWWgMjxJVoej0Q'

sandbox_name = 'emi_professor_green'

print 'getting list of assets'

more_assets = True
asslists = []
images = []
videos = []

start = 0
while more_assets:
    new_asslist = sandbox.list(sandbox_name, 100, start)
    start += 100
    if len(new_asslist) == 0:
        more_assets = False
    else:
        asslists.append(new_asslist)

for i in range(len(asslists)):
    if i == 0:
        combo = asslists[i]
    else:
        combo = combo + asslists[i]    

for asset in combo:
    if 'title' in asset:
         if asset['title'].find('Music Video') > -1 and asset['filename'].find('mp4') > -1:
             if asset['filename'].find('high') > -1:                
                 videos.append(asset)
     
    if asset['type'] == 'release_image':
        filename = str(asset['filename']).partition('/')[2];
        image_asset = sandbox.access(sandbox_name, asset['id'])
        urllib.urlretrieve(image_asset[0]['url'], sandbox_name + '_' + filename)
            
print 'selecting video'

video = random.choice(videos)
filename = str(video['filename']).partition('/')[2];

print filename
video_asset = sandbox.access(sandbox_name, video['id'])
# video_asset = sandbox.access(sandbox_name, '4a0be7c9d98e734d643adb6b9d31b0e4')

urllib.urlretrieve(video_asset[0]['url'], sandbox_name + '_' + filename)

print 'encoding audio'

os.system('ffmpeg -i ' + sandbox_name + '_' + filename + ' -vn -acodec libmp3lame -ab 192000 ' + sandbox_name + '_' + filename + '.mp3')

print 'acquiring analysis'

song_analysis   = audio.LocalAudioFile(sandbox_name + '_' + filename + '.mp3')
sections        = song_analysis.analysis.sections
bars            = song_analysis.analysis.bars
beats           = song_analysis.analysis.beats
tempo           = song_analysis.analysis.tempo
# tatums          = song_analysis.analysis.tatums

print 'writing analysis data'

f = open(sandbox_name + '_' + filename + '.ena', 'w')

f.write(str(tempo['value']) + '\n')

for section in sections:
    f.write(str(section.start) + ':' + str(section.duration) + ', ')

f.write('\n')

for bar in bars:
    f.write(str(bar.start) + ':' + str(bar.duration) + ', ')

f.write('\n')

for beat in beats:
    f.write(str(beat.start) + ':' + str(beat.duration) + ', ')

f.write('\n')

f.write(filename)

print 'done'
f.close()

