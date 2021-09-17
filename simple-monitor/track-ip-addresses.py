import os
import sys
import json
import requests

from ipaddress import ip_address

from read_zone_file import get_zone_records

print('\n'.join(sys.path))

import dns.resolver as dns_resolver

DOMAIN = 'web-service.org'

CWD = os.path.dirname(os.path.realpath(__file__))

FNAME = 'database.json'

FPATH = os.path.join(CWD, FNAME)

if (not os.path.exists(FPATH)):
    data = {'ip_addresses': {}}
else:
    with open(FPATH, 'r') as f:
        j = f.read()
    data = json.loads(j)

ip_addresses = data['ip_addresses']

assert len(sys.argv) >= 3, '({} --> {}) Usage: track-ip-addresses.py <ip-address> <count>'.format(len(sys.argv), sys.argv[1:])

if (sys.argv[1] == '--ips'):
    url = sys.argv[-1]
    assert len(url) > 0, 'Usage: track-ip-addresses.py <ip-address> <count> <url>'
    ips = [ip for ip in sys.argv[2].split(',') if (len(ip) > 0)]
    keys = list(ip_addresses.keys())
    missing = list(set(keys) - set(ips))

    if (len(missing) > 0):
        for ip in missing:
            requests.post(url, data={'text': '{} is offline or down'.format(ip)}, headers = {"Content-type": "application/json"})

    zone_recs = get_zone_records("./{}.txt".format(DOMAIN), domain=DOMAIN, interested_in=['A'], invert=True)
    for ip,domain in zone_recs.items():
        if (ip_address(ip).is_private):
            response = os.system("ping -w 30 -c 1 {}".format(ip))
            if (response != 0):
                requests.post(url, data={'text': '{} is offline or down'.format(ip)}, headers = {"Content-type": "application/json"})
              
    sys.exit(0)
else:
    ip = sys.argv[1]
    cnt = int(sys.argv[2])
    ip_addresses[ip] = cnt

with open(FPATH, 'w') as f:
    print(json.dumps(data), file=f)