"""Core color matching: sRGB -> CIELAB (D65) and CIEDE2000 (Sharma 2005)."""
import math

def hex_to_rgb(h: str):
    h = h.lstrip('#'); return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))

def rgb_to_lab(rgb):
    def lin(c):
        c /= 255.0
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
    r, g, b = (lin(c) for c in rgb)
    x = (0.4124564*r + 0.3575761*g + 0.1804375*b) / 0.95047
    y = (0.2126729*r + 0.7151522*g + 0.0721750*b)
    z = (0.0193339*r + 0.1191920*g + 0.9503041*b) / 1.08883
    f = lambda t: t ** (1/3) if t > 216/24389 else (24389/27*t + 16) / 116
    fx, fy, fz = f(x), f(y), f(z)
    return (116*fy - 16, 500*(fx - fy), 200*(fy - fz))

def hex_to_lab(h): return rgb_to_lab(hex_to_rgb(h))

def ciede2000(l1, l2, kL=1, kC=1, kH=1):
    L1, a1, b1 = l1; L2, a2, b2 = l2
    C1, C2 = math.hypot(a1, b1), math.hypot(a2, b2)
    Cm = (C1 + C2) / 2
    G = 0.5 * (1 - math.sqrt(Cm**7 / (Cm**7 + 25**7)))
    a1p, a2p = (1+G)*a1, (1+G)*a2
    C1p, C2p = math.hypot(a1p, b1), math.hypot(a2p, b2)
    h1p = math.degrees(math.atan2(b1, a1p)) % 360 if C1p else 0
    h2p = math.degrees(math.atan2(b2, a2p)) % 360 if C2p else 0
    dLp, dCp = L2 - L1, C2p - C1p
    if C1p * C2p == 0: dhp = 0
    else:
        dhp = h2p - h1p
        if dhp > 180: dhp -= 360
        elif dhp < -180: dhp += 360
    dHp = 2 * math.sqrt(C1p*C2p) * math.sin(math.radians(dhp/2))
    Lpm, Cpm = (L1+L2)/2, (C1p+C2p)/2
    if C1p * C2p == 0: hpm = h1p + h2p
    elif abs(h1p-h2p) <= 180: hpm = (h1p+h2p)/2
    elif h1p + h2p < 360: hpm = (h1p+h2p+360)/2
    else: hpm = (h1p+h2p-360)/2
    T = (1 - 0.17*math.cos(math.radians(hpm-30)) + 0.24*math.cos(math.radians(2*hpm))
         + 0.32*math.cos(math.radians(3*hpm+6)) - 0.20*math.cos(math.radians(4*hpm-63)))
    dTheta = 30 * math.exp(-(((hpm-275)/25)**2))
    Rc = 2 * math.sqrt(Cpm**7 / (Cpm**7 + 25**7))
    Sl = 1 + 0.015*(Lpm-50)**2 / math.sqrt(20 + (Lpm-50)**2)
    Sc, Sh = 1 + 0.045*Cpm, 1 + 0.015*Cpm*T
    Rt = -math.sin(math.radians(2*dTheta)) * Rc
    return math.sqrt((dLp/(kL*Sl))**2 + (dCp/(kC*Sc))**2 + (dHp/(kH*Sh))**2
                     + Rt*(dCp/(kC*Sc))*(dHp/(kH*Sh)))

def snap(target_hex, threads, only_type=None, exclude_ids=()):
    """Nearest in-stock thread by CIEDE2000 on stitched-sample color."""
    t = hex_to_lab(target_hex); best = None
    for th in threads:
        if not th.get('in_stock', 1) or th['id'] in exclude_ids: continue
        if only_type and th['type'] != only_type: continue
        d = ciede2000(t, hex_to_lab(th['sample_hex']))
        if best is None or d < best[1]: best = (th, d)
    if best is None: raise LookupError('no in-stock thread available')
    return {'thread': best[0], 'delta_e': round(best[1], 2)}

def contrast_warning(thread_hex, fabric_hex, min_de=20.0, min_dl=15.0):
    """Warn if tones too close even when hue differs (lightness gap covers low light / color-blind viewing)."""
    a, b = hex_to_lab(thread_hex), hex_to_lab(fabric_hex)
    de, dl = ciede2000(a, b), abs(a[0]-b[0])
    return {'delta_e': round(de, 1), 'delta_L': round(dl, 1), 'too_close': de < min_de or dl < min_dl}
