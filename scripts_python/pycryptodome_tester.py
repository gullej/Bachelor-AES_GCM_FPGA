import json
from base64 import b64encode
from Crypto.Cipher import AES
from Crypto.Random import get_random_bytes

header = b"header"            # to be authenticated
data   = b"plain"             # to be encrypted
key    = get_random_bytes(16) # cipher key
nonce  = get_random_bytes(12) # to become iv

cipher = AES.new(key, AES.MODE_GCM, nonce=nonce)
cipher.update(header)
ciphertext, tag = cipher.encrypt_and_digest(data)

json_k = [ 'nonce', 'header', 'ciphertext', 'tag']
json_v = [ b64encode(x).decode('utf-8') for x in (cipher.nonce, header, ciphertext, tag)]
result = json.dumps(dict(zip(json_k, json_v)))

print(result)