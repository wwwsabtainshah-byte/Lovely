import 'lovely_family.dart';
import 'lovely_relationships.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const lovelyApi = 'https://lovely.fastapicloud.dev';
const lovelyStorage = FlutterSecureStorage();

Future<String> fetchLovelyOriginalId() async {
  final token = await lovelyStorage.read(key: 'lovely_token');
  if (token == null || token.isEmpty) return 'Original ID: Login required';

  try {
    final response = await http.get(
      Uri.parse('$lovelyApi/me'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 12));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map) {
        final code = data['user_code']?.toString();
        if (code != null && code.isNotEmpty) {
          return 'Original ID: $code';
        }
      }
      return 'Original ID: Pending';
    }
    return 'Original ID: Unavailable';
  } catch (_) {
    return 'Original ID: Tap to retry later';
  }
}


Future<Map<String, dynamic>> fetchLovelyProfile() async {
  final token = await lovelyStorage.read(key: 'lovely_token');
  if (token == null || token.isEmpty) return <String, dynamic>{};
  try {
    final response = await http.get(
      Uri.parse('$lovelyApi/me'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 12));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) return data;
    }
  } catch (_) {}
  return <String, dynamic>{};
}

class LovelyNewProfile extends StatefulWidget {
  const LovelyNewProfile({super.key});

  @override
  State<LovelyNewProfile> createState() => _LovelyNewProfileState();
}

class _LovelyNewProfileState extends State<LovelyNewProfile> {
  static const purple = Color(0xFF9B6DFF);
  late Future<Map<String, dynamic>> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = fetchLovelyProfile();
  }


  Widget button(BuildContext context, IconData icon, String name, {VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7541C5), Color(0xFF291247)],
        ),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Color(0xFFD8A9FF)),
        boxShadow: const [
          BoxShadow(color: Color(0x885E23C0), blurRadius: 10, offset: Offset(0, 5)),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap ?? () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$name page is being connected')),
            );
          },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C061F),
      appBar: AppBar(
        title: const Text('Me'),
        backgroundColor: const Color(0xFF0C061F),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LovelySettingsPage()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6531AD), Color(0xFF201037)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(color: Color(0x885B1BC0), blurRadius: 18, offset: Offset(0, 7)),
              ],
            ),
            child: Column(
              children: [
                FutureBuilder<Map<String, dynamic>>(
              future: _profileFuture,
              builder: (context, snapshot) {
                final profile = snapshot.data ?? <String, dynamic>{};
                final photo = (profile['profile_photo'] ?? '').toString();
                final name = (profile['display_name'] ?? '').toString();
                ImageProvider? image;
                if (photo.startsWith('data:image/') && photo.contains(',')) {
                  try { image = MemoryImage(base64Decode(photo.split(',').last)); } catch (_) {}
                }
                return Column(children: [
                  CircleAvatar(
                    radius: 43,
                    backgroundImage: image,
                    child: image == null ? const Icon(Icons.person, size: 48) : null,
                  ),
                  const SizedBox(height: 10),
                  Text(name.isEmpty ? 'Lovely User' : name,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ]);
              },
            ),
                FutureBuilder<String>(
  future: fetchLovelyOriginalId(),
  builder: (context, snapshot) => Text(
    snapshot.data ?? 'Original ID: Loading...',
    style: const TextStyle(color: Colors.white70),
  ),
),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, size: 30),
                    onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LovelyEditProfilePage(),
                            ),
                          );
                          if (mounted) {
                            setState(() {
                              _profileFuture = fetchLovelyProfile();
                            });
                          }
                        },
                  ),
                ),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text('Visitors\n0', textAlign: TextAlign.center),
                    Text('Following\n0', textAlign: TextAlign.center),
                    Text('Followers\n0', textAlign: TextAlign.center),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: button(context, Icons.workspace_premium, 'SVIP')),
              const SizedBox(width: 10),
              Expanded(child: button(context, Icons.star, 'Level')),
            ],
          ),
          for (final item in <(IconData, String)>[
            (Icons.account_balance_wallet, 'Wallet'),
            (Icons.storefront, 'Store'),
            (Icons.backpack, 'Bag'),
            (Icons.card_giftcard, 'Reward'),
            (Icons.people, 'Family'),
            (Icons.favorite, 'CP'),
            (Icons.group, 'Brother & Sister'),
            (Icons.person_add, 'Invite Friends'),
            (Icons.mic, 'Host Center'),
            (Icons.support_agent, 'Contact Us'),
          ])
            button(
                  context,
                  item.$1,
                  item.$2,
                  onTap: item.$2 == 'Family'
                    ? () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LovelyFamilyPage(),
                          ),
                        )
                    : item.$2 == 'CP'
                        ? () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LovelyRelationshipsPage(siblings: false),
                              ),
                            )
                        : item.$2 == 'Brother & Sister'
                            ? () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const LovelyRelationshipsPage(siblings: true),
                                  ),
                                )
                    : item.$2 == 'Wallet'
                      ? () async {
                          try {
                            final token = await lovelyStorage.read(
                              key: 'lovely_token',
                            );

                            if (!context.mounted) return;

                            if (token == null || token.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please login again.'),
                                ),
                              );
                              return;
                            }

                            final response = await http.get(
                              Uri.parse('$lovelyApi/wallet/me'),
                              headers: {
                                'Authorization': 'Bearer $token',
                              },
                            ).timeout(const Duration(seconds: 15));

                            if (!context.mounted) return;

                            if (response.statusCode == 200) {
                              final data = jsonDecode(response.body);
                              if (data is! Map) {
                                throw const FormatException(
                                  'Invalid wallet response',
                                );
                              }

                              showDialog<void>(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  title: const Text('My Wallet'),
                                  content: Text(
                                    'Coins: ${data['coins'] ?? 0}\n'
                                    'Diamonds: ${data['diamonds'] ?? 0}',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(dialogContext),
                                      child: const Text('Close'),
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Wallet server error: ${response.statusCode}',
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Wallet error: $e'),
                              ),
                            );
                          }
                        }
                      : null,
                ),
        ],
      ),
    );
  }
}

class LovelyEditProfilePage extends StatefulWidget {
  const LovelyEditProfilePage({super.key});
  @override
  State<LovelyEditProfilePage> createState() => _LovelyEditProfilePageState();
}

class _LovelyEditProfilePageState extends State<LovelyEditProfilePage> {
  final _name = TextEditingController();
  final _picker = ImagePicker();
  String _photo = '';
  bool _loading = true, _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await fetchLovelyProfile();
    if (!mounted) return;
    _name.text = (profile['display_name'] ?? '').toString();
    _photo = (profile['profile_photo'] ?? '').toString();
    setState(() => _loading = false);
  }

  Future<void> _choosePhoto() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 65,
        maxWidth: 800, maxHeight: 800,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.length > 1800000) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo too large. Choose a smaller photo.')),
          );
        }
        return;
      }
      final mime = file.name.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
      setState(() => _photo = 'data:$mime;base64,${base64Encode(bytes)}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Photo error: $e')));
      }
    }
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty || name.length > 40) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name must be 1–40 characters.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final token = await lovelyStorage.read(key: 'lovely_token');
      if (token == null || token.isEmpty) throw Exception('Please login again.');
      final response = await http.put(
        Uri.parse('$lovelyApi/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'display_name': name, 'profile_photo': _photo}),
      ).timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) {
        throw Exception('Server ${response.statusCode}: ${response.body}');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved successfully.')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? image;
    if (_photo.startsWith('data:image/') && _photo.contains(',')) {
      try { image = MemoryImage(base64Decode(_photo.split(',').last)); } catch (_) {}
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(20), children: [
              Center(
                child: GestureDetector(
                  onTap: _choosePhoto,
                  child: CircleAvatar(
                    radius: 52, backgroundImage: image,
                    child: image == null ? const Icon(Icons.add_a_photo, size: 35) : null,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _choosePhoto,
                icon: const Icon(Icons.photo_library),
                label: const Text('Choose profile photo'),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _name, maxLength: 40,
                decoration: const InputDecoration(
                  labelText: 'Your name', border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save Profile'),
              ),
            ]),
    );
  }
}

class LovelySettingsPage extends StatelessWidget {
  const LovelySettingsPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Settings')),
    body: ListView(
      children: [
        for (final name in [
          'Create / Change Password',
          'Original ID',
          'Language',
          'Account Security',
          'Privacy',
          'Notifications',
          'Blocked Users',
          'Connected Accounts',
          'Help & Support',
          'Logout',
        ])
          ListTile(title: Text(name), trailing: const Icon(Icons.chevron_right)),
      ],
    ),
  );
}
