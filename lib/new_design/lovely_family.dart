import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class LovelyFamilyPage extends StatefulWidget {
  const LovelyFamilyPage({super.key});

  @override
  State<LovelyFamilyPage> createState() => _LovelyFamilyPageState();
}

class _LovelyFamilyPageState extends State<LovelyFamilyPage> {
  static const api = 'https://lovely.fastapicloud.dev';
  static const storage = FlutterSecureStorage();

  bool loading = true;
  Map<String, dynamic>? family;
  int? myAccountId;
  List<dynamic> members = [];
  List<dynamic> ranking = [];
  List<dynamic> incomingRequests = [];
  List<dynamic> outgoingRequests = [];

  Future<Map<String, String>> headers() async {
    final token = await storage.read(key: 'lovely_token');
    return {
      'Authorization': 'Bearer ${token ?? ""}',
      'Content-Type': 'application/json',
    };
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      final h = await headers();
      final results = await Future.wait([
        http.get(Uri.parse('$api/family/me'), headers: h),
        http.get(Uri.parse('$api/family/ranking'), headers: h),

      http.get(Uri.parse('$api/family/requests'), headers: h),]);

      if (results.any((r) => r.statusCode != 200)) {
        throw Exception('Family server unavailable');
      }

      final me = jsonDecode(results[0].body);
      final ranks = jsonDecode(results[1].body);
      final requests = jsonDecode(results[2].body);

      if (!mounted) return;
      setState(() {
        family = me['family'];
        myAccountId = me['my_account_id'];
        members = me['members'] ?? [];
        ranking = ranks['families'] ?? [];
        incomingRequests = requests['incoming'] ?? [];
        outgoingRequests = requests['outgoing'] ?? [];
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  Future<void> createFamily() async {
    final controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Family'),
        content: TextField(
          controller: controller,
          maxLength: 30,
          decoration: const InputDecoration(
            hintText: 'Family name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (name == null || name.length < 3) return;

    final response = await http.post(
      Uri.parse('$api/family/create'),
      headers: await headers(),
      body: jsonEncode({'name': name}),
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      await load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Create failed: ${response.body}')),
      );
    }
  }

  Future<void> joinFamily(int id) async {
    final response = await http.post(
      Uri.parse('$api/family/join/$id'),
      headers: await headers(),
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      await load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Join failed: ${response.body}')),
      );
    }
  }


  Future<void> leaveFamily() async {
    final response = await http.post(
      Uri.parse('$api/family/leave'),
      headers: await headers(),
    );
    if (!mounted) return;
    if (response.statusCode == 200) {
      await load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Leave failed: ${response.body}')),
      );
    }
  }

  Future<void> editAnnouncement() async {
    final controller = TextEditingController(
      text: '${family?['announcement'] ?? ''}',
    );

    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Family Announcement'),
        content: TextField(
          controller: controller,
          maxLength: 300,
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (value == null) return;

    final response = await http.put(
      Uri.parse('$api/family/announcement'),
      headers: await headers(),
      body: jsonEncode({'announcement': value}),
    );

    if (!mounted) return;
    if (response.statusCode == 200) {
      await load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: ${response.body}')),
      );
    }
  }



  Future<void> respondToJoinRequest(int requestId, String action) async {
    final response = await http.post(
      Uri.parse('$api/family/join-requests/$requestId/respond'),
      headers: await headers(),
      body: jsonEncode({'action': action}),
    );
    if (!mounted) return;
    if (response.statusCode == 200) {
      await load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(action == 'accept' ? 'Join request accepted.' : 'Join request rejected.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request failed: ${response.body}')),
      );
    }
  }

  Future<void> removeMember(int memberId, String username) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Member?'),
        content: Text('Remove $username from your family? This is free.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final response = await http.delete(
      Uri.parse('$api/family/members/$memberId'),
      headers: await headers(),
    );
    if (!mounted) return;
    if (response.statusCode == 200) {
      await load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Remove failed: ${response.body}')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF130923),
      appBar: AppBar(
        title: const Text('Lovely Family'),
        backgroundColor: const Color(0xFF6531AD),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (family == null)
                    ElevatedButton.icon(
                      onPressed: createFamily,
                      icon: const Icon(Icons.add),
                      label: const Text('Create Family'),
                    )
                  else ...[
                    Card(
                      child: ListTile(
                        title: Text('${family!['name']}'),
                        subtitle: Text(
                          'Level ${family!['level']} • '
                          'Points ${family!['points']}\n'
                          '${family!['announcement']}',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (myAccountId == family!['leader_id'])
                      ElevatedButton(
                        onPressed: editAnnouncement,
                        child: const Text('Edit Announcement'),
                      ),
                    if (myAccountId != family!['leader_id'])
                      ElevatedButton(
                        onPressed: leaveFamily,
                        child: const Text('Leave Family'),
                      ),
                    if (myAccountId == family!['leader_id'] &&
                        incomingRequests.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text('Join Requests', style: TextStyle(fontSize: 20)),
                      for (final request in incomingRequests)
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.person_add_alt_1),
                            title: Text('${request['username']}'),
                            subtitle: const Text('Wants to join your family'),
                            trailing: Wrap(
                              spacing: 4,
                              children: [
                                IconButton(
                                  tooltip: 'Accept',
                                  icon: const Icon(Icons.check_circle, color: Colors.green),
                                  onPressed: () => respondToJoinRequest(
                                    request['request_id'] as int, 'accept',
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Reject',
                                  icon: const Icon(Icons.cancel, color: Colors.red),
                                  onPressed: () => respondToJoinRequest(
                                    request['request_id'] as int, 'reject',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],

                    const Text(
                      'Family Members',
                      style: TextStyle(fontSize: 20),
                    ),
                    for (final member in members)
                      ListTile(
                        leading: const Icon(Icons.person),
                        title: Text('${member['username']}'),
                        trailing: myAccountId == family!['leader_id'] &&
                                member['id'] != myAccountId
                            ? IconButton(
                                tooltip: 'Remove member',
                                icon: const Icon(Icons.person_remove, color: Colors.red),
                                onPressed: () => removeMember(
                                  member['id'] as int,
                                  '${member['username']}',
                                ),
                              )
                            : null,
                      ),
                  ],
                  const SizedBox(height: 20),
                  const Text(
                    'Family Ranking',
                    style: TextStyle(fontSize: 22),
                  ),
                  for (final item in ranking)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.groups),
                        title: Text('${item['name']}'),
                        subtitle: Text(
                          'Level ${item['level']} • '
                          '${item['members']} members',
                        ),
                        trailing: family != null
                        ? null
                        : outgoingRequests.any(
                            (request) => request['family_id'] == item['id'],
                          )
                            ? const Text('Pending')
                            : TextButton(
                                onPressed: () => joinFamily(item['id'] as int),
                                child: const Text('Join'),
                              ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
