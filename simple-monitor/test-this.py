import os
import dotenv

fp_env = dotenv.find_dotenv()
print('env: {}'.format(fp_env))
dotenv.load_dotenv(fp_env)

SLACK = os.environ.get('SLACK')

SLICK = os.environ.get('SLICK')

import zlib
from base64 import urlsafe_b64encode as b64e, urlsafe_b64decode as b64d

def obscure(data: bytes) -> bytes:
    return b64e(zlib.compress(data, 9))

def unobscure(obscured: bytes) -> bytes:
    return zlib.decompress(b64d(obscured))

s1 = unobscure(SLICK.encode())
assert s1 == SLACK.encode(), '{} != {}'.format(s1, SLACK.encode())
print(s1.decode())