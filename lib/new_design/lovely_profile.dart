import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const lovelyApi = 'https://lovely.fastapicloud.dev';
const lovelyStorage = FlutterSecureStorage();

class LovelyNewProfile extends StatelessWidget {
  const LovelyNewProfile({super.key});

  static const purple = Color(0xFF9B6DFF);

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
                const CircleAvatar(radius: 43, child: Icon(Icons.person, size: 48)),
                const SizedBox(height: 10),
                const Text('Lovely User', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const Text('Original ID', style: TextStyle(color: Colors.white70)),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, size: 30),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LovelyEditProfilePage()),
                    ),
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
                  onTap: item.$2 == 'Wallet'
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

class LovelyEditProfilePage extends StatelessWidget {
  const LovelyEditProfilePage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Edit Profile')),
    body: const ListTile(
      title: Text('Photo • Name • Region • Bio'),
      subtitle: Text('Profile editing will connect to your account API.'),
    ),
  );
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
