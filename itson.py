import urllib
import random
import os

from pyechonest import config
from pyechonest import sandbox

import echonest.audio as audio

config.ECHO_NEST_API_KEY = "YLTCU72SODVIC00NB"
config.ECHO_NEST_CONSUMER_KEY = 'd0fe2f9558fb209037fc49a4227ac81d'
config.ECHO_NEST_SHARED_SECRET = '9QNMqlVDQWWgMjxJVoej0Q'

sandbox_name = 'emi_tinie_tempah'

# listing = sandbox.list(sandbox_name)
# asset = sandbox.access(sandbox_name, "0e804b6859738850673ae0fa18a20145")

# url = asset[0]['url']

# f = urllib.urlopen(asset[0]['url'])
# split = str(url.partition('?')[0])

# urllib.urlretrieve(asset[0]['url'], 'test.mov')

print 'getting list of assets'

asslist = sandbox.list(sandbox_name, 100)

needVideo = True

videos = []

for item in asslist:
    if 'title' in item:
        if item['title'].find('Music Video') > -1 and item['title'].find('Clip') == -1:
            videos.append(item)
        # print item['id']

print 'selecting video'
video = random.choice(videos)
video_asset = sandbox.access(sandbox_name, video['id'])
urllib.urlretrieve(video_asset[0]['url'], 'song.mov')

print 'encoding audio'

os.system('ffmpeg -i song.mov -vn -acodec libmp3lame -ab 192000 song.mp3')

print 'acquiring analysis'

song_analysis   = audio.LocalAudioFile('song.mp3')
sections        = song_analysis.analysis.sections
bars            = song_analysis.analysis.bars
beats           = song_analysis.analysis.beats
tempo           = song_analysis.analysis.tempo
# tatums          = song_analysis.analysis.tatums

print 'writing analysis data'

f = open('analysis.ena', 'w')

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


print 'done'
f.close()

