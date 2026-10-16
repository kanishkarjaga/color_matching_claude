import '../core/color_math.dart';

class Thread {
  final int? id; final String code, name, hex, sampleHex, type;
  final double costPer1000; final bool inStock; final double stockQty, lowStockAt;
  Thread({this.id, required this.code, required this.name, required this.hex, required this.sampleHex,
    this.type = 'normal', this.costPer1000 = 0, this.inStock = true, this.stockQty = 0, this.lowStockAt = 0});
  Map<String, Object?> toMap() { final l = hexToLab(sampleHex); return {
    'id': id, 'code': code, 'name': name, 'hex': hex, 'sample_hex': sampleHex, 'type': type,
    'cost_per_1000_stitches': costPer1000, 'in_stock': inStock ? 1 : 0, 'stock_qty': stockQty,
    'low_stock_at': lowStockAt, 'lab_l': l.l, 'lab_a': l.a, 'lab_b': l.b}; }
  factory Thread.fromMap(Map<String, Object?> m) => Thread(
    id: m['id'] as int?, code: m['code'] as String, name: m['name'] as String, hex: m['hex'] as String,
    sampleHex: m['sample_hex'] as String, type: m['type'] as String,
    costPer1000: (m['cost_per_1000_stitches'] as num).toDouble(), inStock: m['in_stock'] == 1,
    stockQty: (m['stock_qty'] as num).toDouble(), lowStockAt: (m['low_stock_at'] as num).toDouble());
}

({Thread thread, double deltaE}) snapToThread(String targetHex, List<Thread> all, {String? type, Set<int> exclude = const {}}) {
  final t = hexToLab(targetHex); Thread? best; var bd = double.infinity;
  for (final th in all) {
    if (!th.inStock || exclude.contains(th.id) || (type != null && th.type != type)) continue;
    final d = ciede2000(t, hexToLab(th.sampleHex));
    if (d < bd) { bd = d; best = th; }
  }
  if (best == null) throw StateError('No in-stock thread available');
  return (thread: best, deltaE: bd);
}
