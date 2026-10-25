import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const String _api = 'https://lovely.fastapicloud.dev';
const FlutterSecureStorage _storage = FlutterSecureStorage();

class LovelyRelationshipsPage extends StatefulWidget {
  final bool siblings;
  const LovelyRelationshipsPage({super.key, required this.siblings});

  @override
  State<LovelyRelationshipsPage> createState() =>
      _LovelyRelationshipsPageState();
}

class _LovelyRelationshipsPageState extends State<LovelyRelationshipsPage> {
  Map<String, dynamic> data = {};
  final TextEditingController _search = TextEditingController();
  bool loading = true;
  bool busy = false;
  Map<String, dynamic>? foundUser;

  String get _kind => widget.siblings ? 'sibling_invite' : 'cp_invite';
  String get _title => widget.siblings ? 'Brother & Sister' : 'CP';

  Future<Map<String, String>?> _headers() async {
    final token = await _storage.read(key: 'lovely_token');
    if (token == null || token.isEmpty) return null;
    return {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'};
  }

  Map<String, dynamic> _json(http.Response r) {
    try {
      final value = jsonDecode(r.body);
      if (value is Map<String, dynamic>) return value;
    } catch (_) {}
    return {'detail': r.body.isEmpty ? 'Request failed' : r.body};
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final h = await _headers();
      if (h == null) {
        _message('Please login again.');
        return;
      }
      final r = await http.get(Uri.parse('$_api/relationships/me'), headers: h);
      final j = _json(r);
      if (r.statusCode >= 200 && r.statusCode < 300 && j['success'] == true) {
        data = j;
      } else {
        _message('${j['detail'] ?? 'Could not load relationships'}');
      }
    } catch (e) {
      _message('Connection error: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _action(
    String path, {
    String method = 'POST',
    Map<String, dynamic>? body,
    String success = 'Done',
  }) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final h = await _headers();
      if (h == null) {
        _message('Please login again.');
        return;
      }
      final uri = Uri.parse('$_api$path');
      final r = method == 'GET'
          ? await http.get(uri, headers: h)
          : await http.post(uri, headers: h, body: jsonEncode(body ?? {}));
      final j = _json(r);
      if (r.statusCode >= 200 && r.statusCode < 300 &&
          j['success'] != false) {
        _message('${j['message'] ?? success}');
        foundUser = null;
        _search.clear();
        await _load();
      } else {
        _message('${j['detail'] ?? j['message'] ?? 'Request failed'}');
      }
    } catch (e) {
      _message('Connection error: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _findUser() async {
    final code = _search.text.trim();
    if (code.isEmpty) {
      _message('User Original ID enter karo.');
      return;
    }
    setState(() => busy = true);
    try {
      final h = await _headers();
      if (h == null) {
        _message('Please login again.');
        return;
      }
      final r = await http.get(
        Uri.parse('$_api/relationships/search/${Uri.encodeComponent(code)}'),
        headers: h,
      );
      final j = _json(r);
      if (r.statusCode >= 200 && r.statusCode < 300 && j['success'] == true) {
        setState(() => foundUser = j['user'] is Map<String, dynamic>
            ? j['user'] as Map<String, dynamic>
            : null);
        if (foundUser == null) _message('User nahi mila.');
      } else {
        _message('${j['detail'] ?? 'User nahi mila.'}');
        setState(() => foundUser = null);
      }
    } catch (e) {
      _message('Connection error: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _invite() async {
    final user = foundUser;
    if (user == null) return;
    final code = '${user['user_code'] ?? _search.text.trim()}';
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Send $_title invitation?'),
        content: const Text(
          'Invitation bhejne par 1,000,000 coins aapke wallet se deduct honge. '
          'Doosre user ko accept karne ki fee nahi hogi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final path = widget.siblings
        ? '/relationships/siblings/invite/${Uri.encodeComponent(code)}'
        : '/relationships/cp/invite/${Uri.encodeComponent(code)}';
    await _action(path, success: 'Invitation sent');
  }

  Future<void> _respond(Map<String, dynamic> request, String action) async {
    await _action(
      '/relationships/requests/${request['id']}/respond',
      body: {'action': action},
      success: action == 'accept' ? 'Request accepted' : 'Request rejected',
    );
  }

  Future<void> _selfRemoveCp() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove CP?'),
        content: const Text(
          'Khud CP remove karne par 5,000,000 coins charge honge. '
          'Agar partner removal request bheje aur aap accept karein to free hai.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove — 5M coins'),
          ),
        ],
      ),
    );
    if (ok == true) await _action('/relationships/cp/remove');
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Map<String, dynamic>? _profile(dynamic value) =>
      value is Map<String, dynamic> ? value : null;

  String _name(dynamic value) {
    final p = _profile(value);
    if (p == null) return 'User';
    return '${p['display_name'] ?? p['username'] ?? 'User'}'
        '  (${p['user_code'] ?? p['id'] ?? ''})';
  }

  List<Map<String, dynamic>> _requests(String field, Set<String> kinds) {
    final raw = data[field];
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .where((e) => kinds.contains('${e['kind']}'))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final kinds = widget.siblings
        ? <String>{'sibling_invite', 'sibling_remove'}
        : <String>{'cp_invite', 'cp_remove'};
    final incoming = _requests('incoming_requests', kinds);
    final outgoing = _requests('outgoing_requests', kinds);
    final cpPartner = _profile(data['cp_partner']);
    final rawSiblings = data['siblings'];
    final siblings = rawSiblings is List
        ? rawSiblings.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
        : <Map<String, dynamic>>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: [
          IconButton(
            onPressed: loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Find user by Original ID',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          const Text('Invitation fee: 1,000,000 coins. Receiver accepts free.'),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _search,
                            textInputAction: TextInputAction.search,
                            onSubmitted: (_) => _findUser(),
                            decoration: const InputDecoration(
                              labelText: 'User Original ID',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          FilledButton.icon(
                            onPressed: busy ? null : _findUser,
                            icon: const Icon(Icons.search),
                            label: const Text('Search user'),
                          ),
                          if (foundUser != null) ...[
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const CircleAvatar(child: Icon(Icons.person)),
                              title: Text(_name(foundUser)),
                              subtitle: Text('ID: ${foundUser!['user_code'] ?? ''}'),
                            ),
                            FilledButton(
                              onPressed: busy ? null : _invite,
                              child: Text('Send $_title invitation — 1M coins'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(widget.siblings ? 'My Brother & Sister' : 'My CP',
                      style: Theme.of(context).textTheme.titleLarge),
                  if (widget.siblings)
                    if (siblings.isEmpty)
                      const ListTile(title: Text('Abhi koi sibling relationship nahi.'))
                    else
                      for (final p in siblings)
                        Card(
                          child: ListTile(
                            leading: const CircleAvatar(child: Icon(Icons.person)),
                            title: Text(_name(p)),
                            trailing: IconButton(
                              tooltip: 'Request removal',
                              icon: const Icon(Icons.person_remove),
                              onPressed: busy
                                  ? null
                                  : () => _action(
                                        '/relationships/siblings/${p['id']}/removal-request',
                                        success: 'Removal request sent',
                                      ),
                            ),
                          ),
                        )
                  else if (cpPartner == null)
                    const ListTile(title: Text('Abhi koi active CP nahi.'))
                  else
                    Card(
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.favorite)),
                        title: Text(_name(cpPartner)),
                        subtitle: const Text('Request removal for free, or remove yourself for 5M coins.'),
                        isThreeLine: true,
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'request') {
                              _action('/relationships/cp/removal-request',
                                  success: 'Removal request sent');
                            } else if (value == 'remove') {
                              _selfRemoveCp();
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'request', child: Text('Request free removal')),
                            PopupMenuItem(value: 'remove', child: Text('Self-remove — 5M coins')),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Text('Incoming requests',
                      style: Theme.of(context).textTheme.titleLarge),
                  if (incoming.isEmpty)
                    const ListTile(title: Text('Koi pending incoming request nahi.')),
                  for (final req in incoming)
                    Card(
                      child: ListTile(
                        title: Text(_name(req['sender'])),
                        subtitle: Text(req['kind'] == 'cp_remove'
                            ? 'Partner CP removal request — accept karna free hai.'
                            : req['kind'] == 'sibling_remove'
                                ? 'Sibling removal request'
                                : '$_title invitation'),
                        isThreeLine: true,
                        trailing: req['kind'] == 'cp_remove' ||
                                req['kind'] == 'sibling_remove' ||
                                req['kind'] == _kind
                            ? Wrap(
                                spacing: 4,
                                children: [
                                  IconButton(
                                    tooltip: 'Accept',
                                    onPressed: busy ? null : () => _respond(req, 'accept'),
                                    icon: const Icon(Icons.check_circle, color: Colors.green),
                                  ),
                                  IconButton(
                                    tooltip: 'Reject',
                                    onPressed: busy ? null : () => _respond(req, 'reject'),
                                    icon: const Icon(Icons.cancel, color: Colors.red),
                                  ),
                                ],
                              )
                            : null,
                      ),
                    ),
                  const SizedBox(height: 12),
                  Text('Outgoing requests',
                      style: Theme.of(context).textTheme.titleLarge),
                  if (outgoing.isEmpty)
                    const ListTile(title: Text('Koi pending outgoing request nahi.')),
                  for (final req in outgoing)
                    Card(
                      child: ListTile(
                        title: Text('To user ID ${req['receiver_id'] ?? ''}'),
                        subtitle: Text('Status: ${req['status'] ?? 'pending'} · ${req['kind'] ?? ''}'),
                        trailing: const Icon(Icons.hourglass_top),
                      ),
                    ),
                  if (busy)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
            ),
    );
  }
}
