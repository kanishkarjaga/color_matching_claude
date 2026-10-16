import 'dart:math';

typedef Lab = ({double l, double a, double b});

Lab hexToLab(String hex) {
  final h = hex.replaceAll('#', '');
  double lin(int c) { final v = c / 255; return v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4).toDouble(); }
  final r = lin(int.parse(h.substring(0, 2), radix: 16)), g = lin(int.parse(h.substring(2, 4), radix: 16)), b = lin(int.parse(h.substring(4, 6), radix: 16));
  final x = (0.4124564 * r + 0.3575761 * g + 0.1804375 * b) / 0.95047;
  final y = 0.2126729 * r + 0.7151522 * g + 0.0721750 * b;
  final z = (0.0193339 * r + 0.1191920 * g + 0.9503041 * b) / 1.08883;
  double f(double t) => t > 216 / 24389 ? pow(t, 1 / 3).toDouble() : (24389 / 27 * t + 16) / 116;
  return (l: 116 * f(y) - 16, a: 500 * (f(x) - f(y)), b: 200 * (f(y) - f(z)));
}

double _rad(double d) => d * pi / 180, _deg(double r) => r * 180 / pi;

double ciede2000(Lab p, Lab q) {
  final c1 = sqrt(p.a * p.a + p.b * p.b), c2 = sqrt(q.a * q.a + q.b * q.b);
  final cm7 = pow((c1 + c2) / 2, 7).toDouble();
  final g = 0.5 * (1 - sqrt(cm7 / (cm7 + pow(25, 7))));
  final a1 = (1 + g) * p.a, a2 = (1 + g) * q.a;
  final c1p = sqrt(a1 * a1 + p.b * p.b), c2p = sqrt(a2 * a2 + q.b * q.b);
  double hue(double b, double a, double c) => c == 0 ? 0 : (_deg(atan2(b, a)) + 360) % 360;
  final h1 = hue(p.b, a1, c1p), h2 = hue(q.b, a2, c2p);
  final dL = q.l - p.l, dC = c2p - c1p;
  double dh = 0;
  if (c1p * c2p != 0) { dh = h2 - h1; if (dh > 180) { dh -= 360; } else if (dh < -180) { dh += 360; } }
  final dH = 2 * sqrt(c1p * c2p) * sin(_rad(dh / 2));
  final lpm = (p.l + q.l) / 2, cpm = (c1p + c2p) / 2;
  double hpm;
  if (c1p * c2p == 0) { hpm = h1 + h2; }
  else if ((h1 - h2).abs() <= 180) { hpm = (h1 + h2) / 2; }
  else { hpm = (h1 + h2 < 360) ? (h1 + h2 + 360) / 2 : (h1 + h2 - 360) / 2; }
  final t = 1 - 0.17 * cos(_rad(hpm - 30)) + 0.24 * cos(_rad(2 * hpm)) + 0.32 * cos(_rad(3 * hpm + 6)) - 0.20 * cos(_rad(4 * hpm - 63));
  final dTheta = 30 * exp(-pow((hpm - 275) / 25, 2));
  final cpm7 = pow(cpm, 7).toDouble();
  final rc = 2 * sqrt(cpm7 / (cpm7 + pow(25, 7)));
  final sl = 1 + 0.015 * pow(lpm - 50, 2) / sqrt(20 + pow(lpm - 50, 2));
  final sc = 1 + 0.045 * cpm, sh = 1 + 0.015 * cpm * t;
  final rt = -sin(_rad(2 * dTheta)) * rc;
  return sqrt(pow(dL / sl, 2) + pow(dC / sc, 2) + pow(dH / sh, 2) + rt * (dC / sc) * (dH / sh));
}
