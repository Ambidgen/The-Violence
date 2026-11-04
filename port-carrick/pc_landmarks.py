"""pc_landmarks.py - declarative landmark specs. Positions are *anchors*: the placer snaps each
building to the nearest valid frontage inside the stated ward (optionally on a named street)."""

# kind -> (colour class used by the viewer)
# cls: 'bldg' (has tiers) or 'open' (plaza/park/yard: no height)
L = []


# default year built, by kind (explicit yr= overrides; the generator never lets a building predate its street)
YR_DEFAULT = {"civic": 1890, "plaza": 1890, "police": 1925, "media": 1902, "commerce": 1910, "health": 1912, "political": 1948,
              "harbour": 1860, "faith": 1885, "fire": 1915, "housing": 1925, "utility": 1930, "school": 1925, "industry": 1895,
              "rail": 1893, "cemetery": 1845, "park": 1935, "academy": 1989, "bridge": 1958}


def lm(id, name, kind, ward, ax, ay, w, d, lv, tiers=None, street=None, cls="bldg", status="occupied",
       units=None, note="", yr=None, sub=None, h=None):
    L.append(dict(id=id, name=name, kind=kind, ward=ward, anchor=(ax, ay), w=w, d=d, lv=lv, tiers=tiers,
                  street=street, cls=cls, status=status, units=units, note=note, yr=yr or YR_DEFAULT.get(kind, 1910),
                  sub=sub, h=h))


# ---- Old Town (civic core, north bank, west/east of the viaduct)
lm("city-hall", "City Hall and Council Chambers", "civic", "oldtown", 120, 850, 62, 44, 7, tiers=[[0, 5], [10, 7]], yr=1881)
lm("courthouse", "County Courthouse and DA's Office", "civic", "oldtown", 270, 850, 54, 40, 5)
lm("civic-plaza", "Civic Plaza", "plaza", "oldtown", 190, 720, 56, 40, 0, cls="open")
lm("police-hq", "Carrick Street Station (Police HQ)", "police", "oldtown", -110, 760, 50, 34, 4, yr=1924)
lm("ledger", "The Carrick Ledger", "media", "oldtown", -340, 800, 42, 30, 5)
lm("market-hall", "Old Market Hall", "commerce", "oldtown", -260, 620, 56, 36, 3)
lm("mercy-general", "Mercy General Hospital", "health", "oldtown", -500, 1000, 72, 52, 9, tiers=[[0, 5], [7, 9]])
lm("pell-office", "Pell for Mayor office", "political", "oldtown", 420, 700, 8, 16, 3)
lm("carrick-hotel", "The Carrick Hotel", "commerce", "oldtown", 330, 620, 40, 24, 8, tiers=[[0, 4], [3, 8]])
lm("savings-trust", "Carrick Savings & Trust", "commerce", "oldtown", 20, 960, 30, 24, 6)
lm("free-library", "Carrick Free Library", "civic", "oldtown", 520, 560, 40, 28, 3)
lm("harbour-master", "Harbour Master's Office", "harbour", "eastport", 2300, 757, 26, 14, 3, street="Packet Basin Road", yr=1842)
lm("customs-house", "Customs House", "harbour", "eastport", 2560, 757, 26, 14, 3, street="Packet Basin Road", yr=1851)
lm("fish-market", "Fish Market", "harbour", "riverside", -2350, 560, 24, 10, 2, street="Fish Pier 2", yr=1873)
lm("packet-terminal", "Packet Terminal", "harbour", "eastport", 2425, 640, 24, 10, 3, street="Packet Pier 2", yr=1841)
lm("tollhouse", "Carrick Bridge Authority Tollhouse", "harbour", "northgate", 70, 1370, 24, 16, 2, street="Bridge Street", yr=1958)
# ---- Riverside (north-west lowland, workers' wards on the western swell)
lm("ebenezer", "Ebenezer Community Church", "faith", "riverside", -1500, 640, 28, 16, 3, tiers=[[0, 3], [5, 6]])
lm("engine-2", "Engine Company 2", "fire", "riverside", -1050, 560, 18, 24, 2)
lm("riverside-homes", "Riverside Homes", "housing", "riverside", -1300, 760, 46, 16, 4, units=36)
lm("floodwall-shed", "Floodwall tool shed", "utility", "riverside", -1800, 270, 4, 5, 1, street="North Quay")
lm("carrick-high", "Carrick High School", "school", "riverside", -1400, 1000, 70, 40, 3)
lm("st-casimir", "St. Casimir's Church", "faith", "riverside", -2000, 700, 24, 40, 3, tiers=[[0, 3], [4, 7]])
# ---- Ironworks (south-west: mills, rail yards, the Slag)
lm("bridge-st-apts", "Bridge Street Apartments", "housing", "ironworks", -30, -1650, 40, 22, 5, street="Bridge Street")
lm("okonjo-hq", "Carrick Together storefront", "political", "ironworks", -640, -430, 9, 15, 2)
lm("power-station", "Carrick Power Station", "utility", "ironworks", -1150, -330, 64, 40, 6, tiers=[[0, 6], [14, 18]], yr=1924)
lm("mill-3", "Carrick Steel, Mill No. 3", "industry", "ironworks", -1900, -800, 70, 40, 3, status="derelict", yr=1889)
lm("brass-rail", "Brass Rail Tavern", "commerce", "ironworks", -500, -600, 9, 16, 2)
lm("yard-office", "Carrick Yard Office", "rail", "ironworks", -900, -1380, 14, 10, 1, yr=1893)
lm("union-hall", "Steelworkers Local 14 Hall", "political", "ironworks", -300, -560, 24, 18, 2)
lm("coal-wharf", "Carrick Coal Co. dock", "harbour", "ironworks", -2550, -480, 26, 10, 2, street="Coal Pier 2", yr=1891)
lm("rail-station", "Carrick Union Station", "rail", "ironworks", -120, -1340, 40, 20, 3, yr=1893)
# ---- Kilbride (south-east: police families, bluff)
lm("fop-lodge", "FOP Lodge 14", "political", "kilbride", 500, -700, 30, 22, 2)
lm("st-brendan", "St. Brendan's Church", "faith", "kilbride", 900, -900, 26, 44, 3, tiers=[[0, 3], [5, 9]])
lm("kilbride-elementary", "Kilbride Elementary", "school", "kilbride", 1200, -1000, 60, 34, 3)
lm("engine-5", "Engine Company 5", "fire", "kilbride", 700, -1200, 18, 24, 2)
lm("grain-elevator", "Carrick Grain Elevator", "industry", "eastport", 2570, -400, 24, 11, 22, tiers=[[0, 5], [1.5, 22]], street="Grain Pier 2", yr=1914)
lm("holy-cross", "Holy Cross Cemetery", "cemetery", "kilbride", 1700, -1500, 70, 80, 0, cls="open")
lm("kilbride-corner-store", "Kilbride Avenue corner store", "commerce", "kilbride", 1000, -600, 9, 14, 2, street="Kilbride Avenue")
lm("bluff-rd-bungalow", "Bluff Road bungalow", "housing", "kilbride", 1300, -1700, 12, 12, 1, street="Bluff Road")
# ---- Eastport (north-east + south-east: harbour trades, Hale Armour)
lm("hale-armour", "Hale Armour & Fleet", "industry", "eastport", 2400, 980, 120, 70, 4)
lm("hale-records", "Hale Fleet Sales & Workshop", "commerce", "eastport", 2150, 960, 40, 26, 2)
lm("container-stack", "Eastport container yard", "industry", "eastport", 3000, 800, 90, 70, 0, cls="open")
lm("warehouse-row-7", "Warehouse Row Unit 7", "industry", "eastport", 1500, 420, 30, 24, 2, street="Warehouse Row")
lm("wharf-st-flat", "Wharf Street flat", "housing", "eastport", 1100, 1180, 8, 16, 3, street="Wharf Street")
lm("training-center", "Public Safety Training Center", "academy", "eastport", 2800, -900, 80, 50, 3, yr=1989)
# ---- Northgate (the heights)
lm("kettering-hq", "Safe Streets headquarters", "political", "northgate", 900, 1600, 36, 24, 4)
lm("ch6", "Channel 6 studio and tower", "media", "northgate", 1500, 1800, 40, 30, 3, tiers=[[0, 3], [12, 28]], yr=1961)
lm("harlan-park", "Harlan Park", "park", "northgate", -1000, 1750, 100, 110, 0, cls="open", street="Harlan Avenue")
lm("harlan-ave-bungalow", "Harlan Avenue bungalow", "housing", "northgate", -700, 1700, 12, 12, 1, street="Harlan Avenue")
lm("heights-villa", "Heights Boulevard villa", "housing", "northgate", -300, 1900, 24, 16, 3, street="Heights Boulevard")
lm("grace-methodist", "Grace Methodist Church", "faith", "northgate", 300, 1750, 24, 34, 3, tiers=[[0, 3], [5, 8]])


# ---- v4 additions: the original landing, dual-bank emergency services, flood defence and water/sewer works
lm("landing-tavern", "The Landing Tavern", "commerce", "oldtown", -560, 300, 9, 14, 2, yr=1796,
   note="oldest surviving building; the ferry landing's inn")
lm("lift-tender", "Ferry Street lift-bridge tender's house", "harbour", "oldtown", -630, 250, 10, 8, 2, street="Ferry Street", yr=1927)
lm("engine-1", "Engine Company 1", "fire", "oldtown", 380, 520, 18, 24, 2, yr=1902)
lm("engine-9", "Engine Company 9", "fire", "eastport", 1500, 700, 18, 24, 2, yr=1911)
lm("engine-11", "Engine Company 11", "fire", "northgate", 700, 1950, 18, 24, 2, yr=1952)
lm("engine-7", "Engine Company 7", "fire", "ironworks", -1000, -700, 18, 24, 2, yr=1899)
lm("engine-12", "Engine Company 12", "fire", "eastport", 2500, -1100, 18, 24, 2, yr=1931)
lm("kilbride-precinct", "Kilbride Precinct (south-bank police)", "police", "kilbride", 500, -900, 36, 24, 3, yr=1931,
   note="the south bank's own station: the viaduct can close")
lm("st-lukes", "St. Luke's Hospital", "health", "kilbride", 800, -500, 60, 44, 6, tiers=[[0, 4], [6, 6]], yr=1927)
lm("waterworks", "Carrick Waterworks and River Intake", "utility", "riverside", -3300, 700, 80, 50, 4, sub="waterworks", yr=1869,
   note="intake at the western (upstream) end, above every outfall")
lm("wwtp-north", "East Carrick Wastewater Plant", "utility", "eastport", 3300, 900, 110, 70, 3, sub="wwtp", yr=1927,
   note="north-bank interceptor ends here, downstream")
lm("wwtp-south", "Eastport South Wastewater Plant", "utility", "eastport", 3300, -450, 100, 60, 3, sub="wwtp", yr=1931)
lm("highland-standpipe", "Highland Standpipe", "utility", "northgate", -200, 2050, 14, 14, 15, sub="standpipe", h=45.0, yr=1948,
   note="north-bank high-zone water tower")
lm("carrick-reservoir", "Carrick Reservoir", "utility", "northgate", 900, 1900, 120, 80, 0, cls="open", sub="reservoir", h=10.0, yr=1884,
   note="north-bank low-zone storage")
lm("bluff-standpipe", "Bluff Standpipe", "utility", "kilbride", 300, -2150, 14, 14, 15, sub="standpipe", h=45.0, yr=1938,
   note="south-bank high-zone water tower")
lm("kilbride-reservoir", "Kilbride Reservoir", "utility", "kilbride", 1100, -1850, 120, 80, 0, cls="open", sub="reservoir", h=10.0, yr=1906,
   note="south-bank low-zone storage")
_PUMPS = [("riverside", -2900, "North Quay", 1938), ("riverside", -1500, "North Quay", 1938), ("oldtown", -500, "North Quay", 1938),
          ("eastport", 900, "North Quay", 1938), ("eastport", 1800, "North Quay", 1951), ("eastport", 2900, "North Quay", 1951),
          ("ironworks", -2900, "South Quay", 1938), ("ironworks", -1500, "South Quay", 1938), ("ironworks", -500, "South Quay", 1938),
          ("kilbride", 900, "South Quay", 1938), ("kilbride", 1800, "South Quay", 1951), ("eastport", 2900, "South Quay", 1951)]
for _i, (_wd, _x, _st, _y) in enumerate(_PUMPS):
    _n = _st.startswith("North")
    _k = sum(1 for p in _PUMPS[:_i + 1] if p[2] == _st)
    lm(f"pump-{'n' if _n else 's'}{_k}", f"{'North' if _n else 'South'} Bank Pump Station {_k}", "utility", _wd,
       _x, (250 if _n else -250), 16, 12, 2, street=_st, sub="pump", yr=_y)

# Streets that sites and landmarks refer to by name. (ward, axis, class, pick-rule)
NAMED_STREETS = {
    "Front Street": dict(ward="oldtown", axis="EW", cls="L", rule="nearest_quay"),
    "Foundry Road": dict(ward="ironworks", axis="NS", cls="C", rule="near", pt=(-650.0, -700.0)),
    "Kilbride Avenue": dict(ward="kilbride", axis="NS", cls="C", rule="central"),
    "Bluff Road": dict(ward="kilbride", axis="EW", cls="L", rule="southmost"),
    "Warehouse Row": dict(ward="eastport", axis="EW", cls="L", rule="nearest_quay_n"),
    "Wharf Street": dict(ward="eastport", axis="EW", cls="L", rule="nearest_rail"),
    "Harlan Avenue": dict(ward="northgate", axis="NS", cls="C", rule="central"),
    "Heights Boulevard": dict(ward="northgate", axis="EW", cls="C", rule="central"),
}
