#!/usr/bin/python3

import zlib, base64
from xml.dom.minidom import parse

MAPS = [ 'l0' ]
OUT = 'src/gen_maps.coffe'

out = {}

for name in MAPS:
    fileName = 'media/%s.tmx' % name
    tagMap = parse(fileName).getElementsByTagName('map')[0]

    w = int(tagMap.getAttribute('width'))
    h = int(tagMap.getAttribute('height'))

    tagLayerMap = tagMap.getElementsByTagName('layer')[0]
    tagData = tagLayerMap.getElementsByTagName('data')[0]

    encoded = tagData.firstChild.nodeValue
    raw = zlib.decompress(base64.b64decode(encoded))

    ids = [raw[i*4] for i in range(w*h)]
    out[name] = { 'grid': ids, 'w': w, 'h': h }

fd = open(OUT, 'w')
fd.write("LEVELS = %s\n" % str(out))
fd.close()

