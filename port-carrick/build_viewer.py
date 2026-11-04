import json,sys
t=open('viewer_template.html').read()
d=open(sys.argv[1] if len(sys.argv)>1 else 'city.json').read()
assert '</script' not in d
open('port-carrick-map.html','w').write(t.replace('/*DATA*/',d))
print(len(t)+len(d)); 
