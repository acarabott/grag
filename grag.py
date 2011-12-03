import oauth2 as oauth
import time

url = "http://developer.echonest.com/api/v4/sandbox/access"

params = {
    'api_key': 'YLTCU72SODVIC00NB',
    'oauth_version': "1.0",
    'sandbox':'emi_tinie_tempah',
    'id': '0e804b6859738850673ae0fa18a20145',
    "oauth_nonce": oauth.generate_nonce(),
    'oauth_timestamp': int(time.time()),
    'oauth_signature_method': 'HMAC-SHA1'
}

# token = oauth.Token(key="d0fe2f9558fb209037fc49a4227ac81d", secret="9QNMqlVDQWWgMjxJVoej0Q")
consumer = oauth.Consumer(key="d0fe2f9558fb209037fc49a4227ac81d", secret="9QNMqlVDQWWgMjxJVoej0Q")

# params['oauth_token'] = token.key
params['oauth_consumer_key'] = consumer.key

req = oauth.Request(method="GET", url="http://developer.echonest.com/api/v4/sandbox/access", parameters=params)

signature_method = oauth.SignatureMethod_HMAC_SHA1()

req.sign_request(signature_method, consumer)
