import os
import ujson

def get_zone_records(zonefile, domain="web-service.org", interested_in=['A'], invert=False):
    import dns.zone
    from dns.exception import DNSException

    if (not os.path.exists(zonefile)):
        zonefile = os.path.join(os.path.dirname(os.path.abspath(__file__)), "%s.txt" % domain)
    assert os.path.exists(zonefile), "Zone file not found: %s" % zonefile
    
    assert isinstance(interested_in, list), "interested_in must be a list of record types."

    records = {}
    
    try:
        zone = dns.zone.from_file(zonefile, domain)
        _zone_origin = '.'.join(str(zone.origin).split('.')[0:-1])
        if (not invert):
            records[_zone_origin] ={}
        for name, node in zone.nodes.items():
            rdatasets = node.rdatasets
            _name = str(name)
            node = {}
            for rdataset in rdatasets:
                for rdata in rdataset:
                    _rdtype = str(rdataset.rdtype).split('.')[-1]
                    if (_rdtype not in interested_in):
                        continue
                    if (_rdtype == 'SOA'):
                        node[_name] = str(rdata)
                    if (_rdtype == 'MX'):
                        node[_name] = {'exchange': rdata.exchange, 'preference': rdata.preference}
                    if (_rdtype == 'NS'):
                        node[_name] = '.'.join(rdata.target.to_text().split('.')[0:-1])
                    if (_rdtype == 'CNAME'):
                        node[_name] = str(rdata.target)
                    if (_rdtype == 'A'):
                        node[_name] = rdata.address
            if (len(node) > 0):
                for k,v in node.items():
                    if (invert):
                        records[v] = '{}.{}'.format(k, _zone_origin)
                    else:
                        records[_zone_origin][k] = v
    except DNSException as e:
        print(e.__class__, e)
        
    return records

if (__name__ == '__main__'):
    data = get_zone_records("./web-service.org.txt", domain="web-service.org", interested_in=['A'], invert=True)
    print(ujson.dumps(data, indent=4))
    print('-'*30)

    if (0):
        print(ujson.dumps(get_zone_records("./web-service.org.txt", domain="web-service.org", interested_in=['MX']), indent=4))
        print('-'*30)

        print(ujson.dumps(get_zone_records("./web-service.org.txt", domain="web-service.org", interested_in=['CNAME']), indent=4))
        print('-'*30)

        print(ujson.dumps(get_zone_records("./web-service.org.txt", domain="web-service.org", interested_in=['NS']), indent=4))
        print('-'*30)

        print(ujson.dumps(get_zone_records("./web-service.org.txt", domain="web-service.org", interested_in=['SOA']), indent=4))
        print('-'*30)
