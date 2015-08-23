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

    tagTiles = tagMap.getElementsByTagName('tileset')[0]
    tileW = float(tagTiles.getAttribute('tilewidth'))
    tileH = float(tagTiles.getAttribute('tileheight'))

    tagLayerMap = tagMap.getElementsByTagName('layer')[0]
    tagData = tagLayerMap.getElementsByTagName('data')[0]

    encoded = tagData.firstChild.nodeValue
    raw = zlib.decompress(base64.b64decode(encoded))

    objects = []
    for group in tagMap.getElementsByTagName('objectgroup'):
        for object in group.getElementsByTagName('object'):
            type = object.getAttribute('type')

            ow, oh = 0.0, 0.0
            if object.hasAttribute('width'):
                ow = float(object.getAttribute('width'))
            if object.hasAttribute('height'):
                oh = float(object.getAttribute('height'))

            cx = (float(object.getAttribute('x')) + 0.5*ow) /tileW
            cy = (float(object.getAttribute('y')) + 0.5*oh) /tileH

            dict = {
                'type': type,
                'cx': cx,
                'cy': cy,
                'w': ow*0.5 / tileW,
                'h': oh*0.5 / tileH
            }

            tagProperties = object.getElementsByTagName('properties')
            if len(tagProperties) > 0:
                for prop in tagProperties[0].getElementsByTagName('property'):
                    dict[prop.getAttribute('name')] = prop.getAttribute('value')

            path = None
            tagPolyLine = object.getElementsByTagName('polyline')
            if len(tagPolyLine) > 0:
                pointStr = tagPolyLine[0].getAttribute('points')
                path = []
                for tupStr in pointStr.split(' '):
                    x, y = [float(coord) for coord in tupStr.split(',')]
                    path.append([x, y])
            if path: dict['path'] = path

            objects.append(dict)
            #print(type, cx, cy)

    ids = [raw[i*4] - 1 for i in range(w*h)]
    out[name] = { 'grid': ids, 'w': w, 'h': h, 'objects': objects }

fd = open(OUT, 'w')
fd.write("LEVELS = %s\n" % str(out))
fd.close()

