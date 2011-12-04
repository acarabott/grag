import urllib
import random
import os

from pyechonest import config
from pyechonest import sandbox

import echonest.audio as audio

config.ECHO_NEST_API_KEY = "YLTCU72SODVIC00NB"
config.ECHO_NEST_CONSUMER_KEY = 'd0fe2f9558fb209037fc49a4227ac81d'
config.ECHO_NEST_SHARED_SECRET = '9QNMqlVDQWWgMjxJVoej0Q'

sandbox_name = 'emi_japanese_popstars'

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
        if item['title'].find('Music Video') > -1 and item['title'].find('Clip') == -1 and item['format'].find('rm') == -1:
            if item['title'].find('streaming') == -1 and item['format'].find('wmv') == -1:
                videos.append(item)

print 'selecting video'
# print videos
video = random.choice(videos)
filename = str(video['filename']).partition('/')[2];

print filename
video_asset = sandbox.access(sandbox_name, video['id'])
# video_asset = sandbox.access(sandbox_name, '4a0be7c9d98e734d643adb6b9d31b0e4')

urllib.urlretrieve(video_asset[0]['url'], sandbox_name + '_' + filename)

print 'encoding audio'

os.system('ffmpeg -i ' + sandbox_name + '_' + filename + ' -vn -acodec libmp3lame -ab 192000 ' + sandbox_name + '_' + filename + '.mp3')

if filename.find('.mov') == -1:
    os.system('ffmpeg -i ' + sandbox_name + '_' + filename + ' -vcodec libxvid -acodec copy ' + sandbox_name + '_' + filename + '.mp4')

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



print 'done'
f.close()

## Convert to wav for sc?gst