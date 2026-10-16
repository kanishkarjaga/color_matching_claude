import 'package:flutter/material.dart';
import '../../data/db.dart';
import '../../data/thread.dart';

Color _c(String h) => Color(int.parse('FF${h.replaceAll('#', '')}', radix: 16));

class ThreadStockPage extends StatefulWidget {
  const ThreadStockPage({super.key});
  @override State<ThreadStockPage> createState() => _S();
}

class _S extends State<ThreadStockPage> {
  List<Thread> items = []; final tester = TextEditingController(text: '#800020'); String result = '';
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async { items = await AppDb.threads(); if (mounted) setState(() {}); }

  void _test() {
    try { final r = snapToThread(tester.text, items);
      result = '${r.thread.name} (${r.thread.code})  ΔE ${r.deltaE.toStringAsFixed(1)}';
    } catch (e) { result = '$e'; }
    setState(() {});
  }

  Future<void> _edit([Thread? t]) async {
    final code = TextEditingController(text: t?.code), name = TextEditingController(text: t?.name),
      hex = TextEditingController(text: t?.hex ?? '#'), sample = TextEditingController(text: t?.sampleHex ?? '#'),
      cost = TextEditingController(text: '${t?.costPer1000 ?? 0}'); var type = t?.type ?? 'normal';
    final ok = await showDialog<bool>(context: context, builder: (_) => StatefulBuilder(builder: (c, set) => AlertDialog(
      title: Text(t == null ? 'Add thread' : 'Edit thread'),
      content: SingleChildScrollView(child: Column(children: [
        TextField(controller: code, decoration: const InputDecoration(labelText: 'Code')),
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
        TextField(controller: hex, decoration: const InputDecoration(labelText: 'Spool HEX')),
        TextField(controller: sample, decoration: const InputDecoration(labelText: 'Stitched-sample HEX')),
        TextField(controller: cost, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cost / 1000 stitches')),
        DropdownButton<String>(value: type, items: const [DropdownMenuItem(value: 'normal', child: Text('Normal')), DropdownMenuItem(value: 'zari', child: Text('Metallic zari'))], onChanged: (v) => set(() => type = v!)),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Save'))])));
    if (ok != true) return;
    await AppDb.save(Thread(id: t?.id, code: code.text, name: name.text, hex: hex.text, sampleHex: sample.text, type: type,
      costPer1000: double.tryParse(cost.text) ?? 0, inStock: t?.inStock ?? true, stockQty: t?.stockQty ?? 0, lowStockAt: t?.lowStockAt ?? 0));
    _load();
  }

  Future<void> _restore() async {
    final list = await AppDb.backups(); if (!mounted) return;
    final f = await showDialog(context: context, builder: (c) => SimpleDialog(title: const Text('Restore backup'),
      children: [for (final b in list) SimpleDialogOption(onPressed: () => Navigator.pop(c, b), child: Text(b.path.split('/').last))]));
    if (f != null) { await AppDb.restore(f); _load(); }
  }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Thread Stock'), actions: [IconButton(icon: const Icon(Icons.restore), onPressed: _restore)]),
    floatingActionButton: FloatingActionButton.large(onPressed: _edit, child: const Icon(Icons.add)),
    body: Column(children: [
      Padding(padding: const EdgeInsets.all(12), child: Row(children: [
        Expanded(child: TextField(controller: tester, decoration: const InputDecoration(labelText: 'Test: target HEX → nearest thread'))),
        const SizedBox(width: 8), FilledButton(onPressed: _test, child: const Text('Match'))])),
      if (result.isNotEmpty) Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text(result, style: Theme.of(context).textTheme.titleMedium)),
      Expanded(child: ListView.builder(itemCount: items.length, itemBuilder: (_, i) { final t = items[i]; return ListTile(
        leading: CircleAvatar(backgroundColor: _c(t.sampleHex)), title: Text('${t.name} · ${t.code}'),
        subtitle: Text('${t.type == 'zari' ? 'Zari' : 'Normal'} · stock ${t.stockQty}${t.lowStockAt > 0 && t.stockQty <= t.lowStockAt ? '  ⚠ LOW' : ''}'),
        trailing: Switch(value: t.inStock, onChanged: (v) async { await AppDb.setStock(t.id!, v); _load(); }), onTap: () => _edit(t)); })),
    ]));
}
