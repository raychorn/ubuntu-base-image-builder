import os
import sys
import json
import requests

import dotenv

from ipaddress import ip_address

from read_zone_file import get_zone_records

#print('\n'.join(sys.path))

import dns.resolver as dns_resolver

fp_env = dotenv.find_dotenv()
print('env: {}'.format(fp_env))
dotenv.load_dotenv(fp_env)

DOMAIN = os.environ.get('THE_DOMAIN')
assert isinstance(DOMAIN, str) and (len(DOMAIN) > 0), 'DOMAIN is not set in {}'.format(fp_env)

DOMAIN = '.'.join(DOMAIN.split('.')[-2:])

print('DEBUG: DOMAIN: {}'.format(DOMAIN))

ALERT_THRESHOLD = int(os.environ.get('ALERT_THRESHOLD', '15'))
assert isinstance(ALERT_THRESHOLD, int) and (ALERT_THRESHOLD >= 1) and (ALERT_THRESHOLD <= 99), 'ALERT_THRESHOLD is not set in {}'.format(fp_env)

print('DEBUG: ALERT_THRESHOLD: {}'.format(ALERT_THRESHOLD))

CWD = os.path.dirname(os.path.realpath(__file__))

FNAME = 'database.json'

FPATH = os.path.join(CWD, FNAME)


def initialize_data():
    return {'ip_addresses': {}}


if (not os.path.exists(FPATH)):
    data = initialize_data()
else:
    try:
        with open(FPATH, 'r') as f:
            j = f.read()
        data = json.loads(j)
        if (len(data) == 0):
            data = initialize_data()
    except Exception as e:
        data = initialize_data()

ip_addresses = data.get('ip_addresses', {})

assert len(sys.argv) >= 3, '({} --> {}) Usage: track-ip-addresses.py <ip-address> <count> <delta>'.format(len(sys.argv), sys.argv[1:])

alerts_event = 'alerts'

def tally_event_for(ip, event, data={}): # data is ip_addresses (dict)
    bucket = data.get(ip, {})
    if (not isinstance(bucket, dict)):
        cnt = bucket
        bucket = {}
        bucket['cnt'] = cnt
    bucket[event] = bucket.get(event, 0) + 1
    print('DEBUG: bucket: {}'.format(bucket))
    data[ip] = bucket
    return bucket.get(event, 0)


def zone_sub_domains():
    zone_recs = get_zone_records("./{}.txt".format(DOMAIN), domain=DOMAIN, interested_in=['A'], invert=True)
    for ip,_domain in zone_recs.items():
        if (ip_address(ip).is_private) and (ip.find(default) > -1):
            yield ip,_domain


if (sys.argv[1] == '--ips'):
    url = sys.argv[-2]
    assert len(url) > 0, 'Usage: track-ip-addresses.py <ip-address> <count> <url> <default-network>'
    print('DEBUG: url: {}'.format(url))

    default = sys.argv[-1]
    assert len(default) > 0, 'Usage: track-ip-addresses.py <ip-address> <count> <url> <default-network>'
    print('DEBUG: default: {}'.format(default))
    default = '.'.join(default.split('.')[0:-1])

    ips = [ip for ip in sys.argv[2].split(',') if (len(ip) > 0)]
    keys = list(ip_addresses.keys())
    missing = list(set(keys) - set(ips))

    ip_domains = dict([tuple([ip,_domain]) for ip,_domain in zone_sub_domains()])
    if (len(missing) > 0):
        for _ip in missing:
            if (not _ip in list(ip_domains.keys())):
                continue
            print('ALERT.1: {} is down or missing.'.format(_ip))
            num = tally_event_for(_ip, alerts_event, data=ip_addresses)
            if (num > ALERT_THRESHOLD):
                continue
            r = requests.post(url, json={'text': 'ALERT.1: {} is offline or down'.format(_ip)}, headers = {"Content-type": "application/json"})
            print('STATUS: {}'.format(r.status_code))

    for ip,_domain in ip_domains.items():
        if (ip_address(ip).is_private) and (ip.find(default) > -1):
            print('Pinging: {} --> {}'.format(ip, _domain))
            cmd = "{}/pinger.sh {}".format(os.path.dirname(__file__), ip)
            response = os.system(cmd)
            print('{} --> {} ({})'.format(cmd, response, type(response)))
            if (response != 0):
                print('ALERT.2: {} ({}) is down or missing.'.format(ip, _domain))
                num = tally_event_for(ip, alerts_event, data=ip_addresses)
                if (num > ALERT_THRESHOLD):
                    continue
                r = requests.post(url, json={'text': 'ALERT.2: {} ({}) is offline or down'.format(ip, domain)}, headers = {"Content-type": "application/json"})
                print('STATUS: {}'.format(r.status_code))
              
    #sys.exit(0)
else:
    ip = sys.argv[1]
    cnt = int(sys.argv[2])
    delta = sys.argv[3]
    #print('ip: {}, delta: {}, data={}'.format(ip, delta, ip_addresses))
    tally_event_for(ip, delta, data=ip_addresses)

with open(FPATH, 'w') as f:
    print(json.dumps(data, indent=3), file=f)