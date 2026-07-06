// Live JSON-RPC probe of the Odoo web server.
// - lists databases
// - authenticates
// - finds amarna/* models and their fields
// Usage: dart run tool/odoo_probe.dart
import 'dart:convert';
import 'dart:io';

Map<String, String> _env() {
  final out = <String, String>{};
  final f = File('.env');
  for (final line in f.readAsLinesSync()) {
    final t = line.trim();
    if (t.isEmpty || t.startsWith('#')) continue;
    final i = t.indexOf('=');
    if (i <= 0) continue;
    out[t.substring(0, i).trim()] = t.substring(i + 1).trim();
  }
  return out;
}

late String base;
final _client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
String? _cookie;

Future<dynamic> _post(String path, Map<String, dynamic> params) async {
  final req = await _client.postUrl(Uri.parse('$base$path'));
  req.headers.set('Content-Type', 'application/json');
  if (_cookie != null) req.headers.set('Cookie', _cookie!);
  req.add(utf8.encode(jsonEncode(
      {'jsonrpc': '2.0', 'method': 'call', 'params': params})));
  final res = await req.close();
  final sc = res.headers['set-cookie'];
  if (sc != null && sc.isNotEmpty) {
    _cookie = sc.map((p) => p.split(';').first).join('; ');
  }
  final body = await res.transform(utf8.decoder).join();
  final decoded = jsonDecode(body);
  if (decoded is Map && decoded['error'] != null) {
    throw Exception(jsonEncode(decoded['error']));
  }
  return decoded['result'];
}

Future<void> main() async {
  final e = _env();
  base = (e['AMARNA_ODOO_BASE_URL'] ?? '').replaceAll(RegExp(r'/$'), '');
  var db = e['AMARNA_ODOO_DB'] ?? '';
  final user = e['AMARNA_ODOO_USERNAME'] ?? '';
  final pass = e['AMARNA_ODOO_PASSWORD'] ?? '';
  stdout.writeln('Odoo: $base\n');

  // 1. List databases
  try {
    final dbs = await _post('/web/database/list', {});
    stdout.writeln('Databases: $dbs');
    if (dbs is List && dbs.isNotEmpty && !dbs.contains(db)) {
      stdout.writeln('  (note: .env DB "$db" not in list — using ${dbs.first})');
      db = dbs.first.toString();
    }
  } catch (err) {
    stdout.writeln('database/list unavailable ($err) — trying .env DB "$db"');
  }

  // 2. Authenticate
  stdout.writeln('\nAuthenticating as "$user" on "$db"...');
  final auth = await _post('/web/session/authenticate',
      {'db': db, 'login': user, 'password': pass});
  final uid = (auth as Map)['uid'];
  if (uid == null || uid == false) {
    stdout.writeln('AUTH FAILED — check login/password/db.');
    exit(1);
  }
  stdout.writeln('AUTH OK ✓  uid=$uid  name=${auth['name']}');

  Future<dynamic> callKw(String model, String method, List args,
          [Map kwargs = const {}]) =>
      _post('/web/dataset/call_kw/$model/$method', {
        'model': model,
        'method': method,
        'args': args,
        'kwargs': kwargs,
      });

  // 3. Find amarna models
  stdout.writeln('\nSearching for custom models...');
  final models = await callKw('ir.model', 'search_read', [
    [
      '|', '|', '|',
      ['model', 'like', 'amarna'],
      ['model', 'like', 'reservation'],
      ['model', 'like', 'subscription'],
      ['model', 'like', 'abonnement'],
    ],
    ['model', 'name'],
  ], {
    'limit': 50,
    'order': 'model',
  });

  if (models is! List || models.isEmpty) {
    stdout.writeln('No amarna/reservation/subscription models found.');
    _client.close();
    exit(0);
  }

  // 4. For each, print fields
  for (final m in models) {
    final model = m['model'];
    stdout.writeln('\n=== $model   (${m['name']}) ===');
    final fields = await callKw(model, 'fields_get', [], {
      'attributes': ['string', 'type', 'relation', 'required'],
    });
    (fields as Map).forEach((name, meta) {
      if (const [
        'create_uid', 'write_uid', 'create_date', 'write_date',
        '__last_update', 'display_name', 'id',
      ].contains(name)) return;
      final t = meta['type'];
      final rel = (meta['relation'] != null) ? ' -> ${meta['relation']}' : '';
      final req = (meta['required'] == true) ? ' [required]' : '';
      stdout.writeln('   $name  ($t$rel)$req   "${meta['string']}"');
    });
  }

  _client.close();
  exit(0);
}
