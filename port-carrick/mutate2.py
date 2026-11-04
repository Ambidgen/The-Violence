"""mutation tests for the v4 rules: each injected contradiction must be caught"""
import json, copy, os, sys, tempfile, validate_city as V
D=json.load(open('city.json'))
def run(name, fn, want):
    d=copy.deepcopy(D); fn(d)
    with tempfile.TemporaryDirectory(prefix="port-carrick-mutation-") as tmp:
        path=os.path.join(tmp, "city.json")
        with open(path, "w") as f: json.dump(d, f)
        rep=V.validate(path)
    fails=[c['id'] for c in rep['checks'] if not c['ok']]
    ok=any(w in fails for w in want)
    print(f"{'CAUGHT' if ok else 'MISSED'} {name:62s} -> {fails}")
    return ok
B=lambda d:d['buildings']
def cross(d,i): return next(c for c in d['crossings'] if c['id']==i)
def ms():
    r=[]
    r.append(run('viaduct dated before the rail bridge',lambda d:cross(d,'carrick-bridge').update(year=1880),['HS1']))
    r.append(run('a second major crossing',lambda d:cross(d,'rail-lift').update(major=True),['HS1','GE4']))
    r.append(run('house older than its street',lambda d:B(d)['yr'].__setitem__(100,1790),['HS2']))
    r.append(run('dwelling built after the peak year',lambda d:B(d)['yr'].__setitem__(next(i for i,u in enumerate(B(d)['units']) if u>0),1990),['HS2','HS5']))
    r.append(run('Fish Basin fill dated before the basin',lambda d:d['water']['fill'].update(year=1850),['HS4']))
    r.append(run('two basins dug the same year',lambda d:d['water']['basins']['Fish Basin'].update(year=1838),['HS4']))
    r.append(run('population curve peak edited',lambda d:d['history']['pop'].__setitem__(next(i for i,p in enumerate(d['history']['pop']) if p[0]==1962),[1962,149000]),['HS5']))
    r.append(run('abandonment dated before the peak',lambda d:B(d)['abn'].__setitem__(next(i for i,a in enumerate(B(d)['abn']) if a!=9999),1930),['HS6']))
    def gap(d):
        s=next(s for s in d['wall']['segments'] if s['bank']=='N' and s['pts'][0][0]==-3000.0); s['pts']=s['pts'][4:]
    r.append(run('hole punched in the floodwall',gap,['FL1']))
    r.append(run('wall crest below the flood line',lambda d:d['wall'].update(crest=221.0),['FL1']))
    r.append(run('Ferry Street gate removed',lambda d:d['wall'].update(gates=[g for g in d['wall']['gates'] if g['id']!='gate-ferry-N']),['FL1','FL2']))
    def mv(d):
        for s in d['wall']['segments']:
            if s['bank']=='S': s['pts']=[[p[0],p[1]+30] for p in s['pts']]
    r.append(run('south wall slid 30 m inland',mv,['FL3']))
    r.append(run('a pump station removed from each bank',lambda d:d['utilities'].update(pumps=[p for p in d['utilities']['pumps'] if p not in('pump-n2','pump-n3','pump-s2','pump-s3')]),['FL4']))
    r.append(run('flood class corrupted',lambda d:B(d)['fl'].__setitem__(10,2 if B(d)['fl'][10]!=2 else 0),['FL5']))
    def vac(d):
        b=B(d)
        for i in range(b['n']):
            if b['fl'][i]==1 and b['units'][i]>0 and b['peak'][i]>0: b['status'][i]=0; b['now'][i]=b['peak'][i]
    r.append(run('families move back into the flooded lowland',vac,['FL6','PD1']))
    r.append(run('reservoir raised so head exceeds 100 m',lambda d:d['utilities']['facilities'][1].update(twl=500.0),['UT1','UT2']))
    r.append(run('standpipe moved to the wrong bank',lambda d:d['utilities']['facilities'][0].update(y=-1800.0),['UT2']))
    def sew(d):
        l=next(l for l in d['utilities']['laterals'] if l['fall']>0.03); l['up'],l['down']=l['down'],l['up']
    r.append(run('a sewer lateral laid uphill',sew,['UT3']))
    r.append(run('water intake moved downstream of the outfalls',lambda d:next(l for l in d['landmarks'] if l['id']=='waterworks').update(x=3000.0),['UT4']))
    r.append(run('one harbour CSO removed',lambda d:d['utilities'].update(outfalls=[o for o in d['utilities']['outfalls'] if not o['id'].startswith('cso-NE')]),['UT5','UT4']))
    def fire(d):
        for l in d['landmarks']:
            if l['kind']=='fire' and l['bank']=='S': l['bank']='N'
    r.append(run('every south-bank fire station reassigned north',fire,['SV1']))
    r.append(run('response time table zeroed on one bank',lambda d:[B(d)['tf'].__setitem__(i,5) for i in range(0,B(d)['n'],5)],['SV3']))
    r.append(run('closing both bridges strands a building',lambda d:B(d)['tc'].__setitem__(7,99999),['SV2']))
    r.append(run('Packet Basin re-dug at the narrows',lambda d:d['water']['basins']['Packet Basin'].update(rect=[150.0,150.0,700.0,500.0]),['GE3c']))
    r.append(run('Coal Spur deleted',lambda d:d.update(rail=[x for x in d['rail'] if x['name']!='Coal Spur']),['RD12']))
    def pier(d):
        b=d['water']['basins']['Grain Basin']; p=b['piers'][0]; p[3]=-150.0
    r.append(run('a Grain Basin pier pushed into the river',pier,['GE3','GE3c']))
    print(sum(r),'of',len(r),'caught')
    return all(r)

if __name__ == '__main__':
    sys.exit(0 if ms() else 1)
