import urllib
from pyechonest import config
from pyechonest import sandbox

config.ECHO_NEST_API_KEY = "YLTCU72SODVIC00NB"
config.ECHO_NEST_CONSUMER_KEY = 'd0fe2f9558fb209037fc49a4227ac81d'
config.ECHO_NEST_SHARED_SECRET = '9QNMqlVDQWWgMjxJVoej0Q'

# sandbox_name = 'emi_tinie_tempah'
sandbox_name = "emi_professor_green"

asslist = sandbox.list(sandbox_name, 100)

images = [];

for asset in asslist:
    if asset['type'] == 'release_image' or asset['type'] == 'video_still':
        filename = str(asset['filename']).partition('/')[2];
        image_asset = sandbox.access(sandbox_name, asset['id'])
        urllib.urlretrieve(image_asset[0]['url'], sandbox_name + '_' + filename)