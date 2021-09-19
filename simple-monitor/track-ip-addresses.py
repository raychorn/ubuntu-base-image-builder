import os
import sys
import json
import time
import datetime
import requests

import re

import dotenv

from ipaddress import ip_address

from read_zone_file import get_zone_records

from read_zone_file import unobscure

from wakeonlan import send_magic_packet

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

WAKE_ON_LAN = os.environ.get('WAKE_ON_LAN')
assert isinstance(WAKE_ON_LAN, str) and (len(WAKE_ON_LAN) > 0), 'WAKE_ON_LAN is not set in {}'.format(fp_env)

is_WAKE_ON_LAN_all = WAKE_ON_LAN.lower() == 'all'

SLICK = os.environ.get('SLICK')
assert isinstance(SLICK, str) and (len(SLICK) > 0), 'SLICK is not set in {}'.format(fp_env)

url = unobscure(SLICK.encode()).decode()
print('DEBUG: url: {}'.format(url))

TEST_SLACK_TIME = int(os.environ.get('TEST_SLACK_TIME', '0'))
assert isinstance(TEST_SLACK_TIME, int) and (TEST_SLACK_TIME >= 0) and (TEST_SLACK_TIME <= 59), 'TEST_SLACK_TIME is not set in {}'.format(fp_env)

CWD = os.path.dirname(os.path.realpath(__file__))

FNAME = 'database.json'

CWD = os.environ.get('MONITOR_FPATH', CWD)

if (not os.path.exists(CWD)):
    os.makedirs(CWD)

FPATH = os.path.join(os.environ.get('MONITOR_FPATH', CWD), FNAME)

# get current time in minutes
now = datetime.datetime.now()
current_time = (now.minute * 60) + now.second
current_time_secs = (now.hour * 3600) + (now.minute * 60) + now.second
expected_secs_since_last_checkin = 3600

LAST_SLACK_TIME_CHECKIN = int(os.environ.get('LAST_SLACK_TIME_CHECKIN', str(current_time_secs)))
if (current_time == TEST_SLACK_TIME) or ((current_time_secs - LAST_SLACK_TIME_CHECKIN) >= expected_secs_since_last_checkin):
    if ((current_time_secs - LAST_SLACK_TIME_CHECKIN) >= expected_secs_since_last_checkin):
        r = requests.post(url, json={'text': 'TEST.1: Just saying HI. {}'.format(now)}, headers = {"Content-type": "application/json"})
        print('TEST-STATUS: {}'.format(r.status_code))
        assert r.status_code == 200, 'TEST-STATUS: {}'.format(r.status_code)
        os.environ['LAST_SLACK_TIME_CHECKIN'] = str(current_time_secs)

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


default = sys.argv[-1]
assert len(default) > 0, 'Usage: track-ip-addresses.py <ip-address> <count> <url> <default-network>'
print('DEBUG: default: {}'.format(default))
default = '.'.join(default.split('.')[0:-1])

def zone_sub_domains():
    zone_recs = get_zone_records("./{}.txt".format(DOMAIN), domain=DOMAIN, interested_in=['A'], invert=True)
    for ip,_domain in zone_recs.items():
        if (ip_address(ip).is_private) and (ip.find(default) > -1):
            yield ip,_domain

ip_domains = dict([tuple([ip,_domain]) for ip,_domain in zone_sub_domains()])

if (sys.argv[1] == '--ips'):
    assert len(url) > 0, 'Usage: track-ip-addresses.py <ip-address> <count> <url> <default-network>'
    print('DEBUG: url: {}'.format(url))

    ips = [ip for ip in sys.argv[2].split(',') if (len(ip) > 0)]
    keys = list(ip_addresses.keys())
    missing = list(set(keys) - set(ips))

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
            assert r.status_code == 200, 'TEST-STATUS: {}'.format(r.status_code)

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
                r = requests.post(url, json={'text': 'ALERT.2: {} ({}) is offline or down'.format(ip, _domain)}, headers = {"Content-type": "application/json"})
                print('STATUS: {}'.format(r.status_code))
                assert r.status_code == 200, 'TEST-STATUS: {}'.format(r.status_code)
            time.sleep(5)
              
    #sys.exit(0)
else:
    ip = sys.argv[1]
    cnt = int(sys.argv[2])
    delta = sys.argv[3]
    mac_address = sys.argv[4]
    is_wakeonlan = is_WAKE_ON_LAN_all
    is_mac = re.match(r'^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$', mac_address)
    if (ip in list(ip_domains.keys())):
        is_wakeonlan = (is_mac is not None) and (delta == "+1")
    print('DEBUG: ip: {}, delta: {}, is_wakeonlan={}, is_mac={}'.format(ip, delta, is_wakeonlan, is_mac))
    if (is_wakeonlan):
        send_magic_packet(mac_address)
    tally_event_for(ip, delta, data=ip_addresses)

with open(FPATH, 'w') as f:
    print(json.dumps(data, indent=3), file=f)