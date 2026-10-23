import 'package:flutter/material.dart';

void main() {
  runApp(const XenaExactApp());
}

class XenaExactApp extends StatelessWidget {
  const XenaExactApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Xena',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0C061F),
        primarySwatch: Colors.deepPurple,
      ),
      home: const XenaHomeScreen(),
    );
  }
}

class XenaHomeScreen extends StatefulWidget {
  const XenaHomeScreen({Key? key}) : super(key: key);

  @override
  State<XenaHomeScreen> createState() => _XenaHomeScreenState();
}

class _XenaHomeScreenState extends State<XenaHomeScreen> {
  int _currentIndex = 3; // Default to Profile tab like the video

  final List<Widget> _pages = [
    const Center(child: Text('Live Stream Screen', style: TextStyle(color: Colors.white))),
    const Center(child: Text('Message Screen', style: TextStyle(color: Colors.white))),
    const Center(child: Text('Square / Moments', style: TextStyle(color: Colors.white))),
    const XenaProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF150B2E),
        selectedItemColor: Colors.pinkAccent,
        unselectedItemColor: Colors.white54,
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.live_tv), label: 'Live'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble), label: 'Message'),
          BottomNavigationBarItem(icon: Icon(Icons.public), label: 'Square'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class XenaProfileTab extends StatelessWidget {
  const XenaProfileTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150'),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Shah G', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                Text('ID:9409405', style: TextStyle(fontSize: 10, color: Colors.white54)),
              ],
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              const SizedBox(height: 10),
              // Friends / Following / Follower Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const [
                  _StatItem(count: '9', label: 'Friends'),
                  _StatItem(count: '21', label: 'Following'),
                  _StatItem(count: '12', label: 'Follower'),
                ],
              ),
              const SizedBox(height: 16),

              // Xcoins & Diamonds Cards
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E123F),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.monetization_on, color: Colors.amber),
                          SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Xcoins', style: TextStyle(color: Colors.white70, fontSize: 11)),
                              Text('0', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E123F),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.diamond, color: Colors.blueAccent),
                          SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Diamonds', style: TextStyle(color: Colors.white70, fontSize: 11)),
                              Text('14000', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Agency Center Banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF321E5E), Color(0xFF190F33)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.shield_outlined, color: Colors.amber, size: 32),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Agency Center', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                          Text('Agency management & income detail', style: TextStyle(color: Colors.white54, fontSize: 11)),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white54),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Grid Icons (VIP Center, Noble, Level, Group, Relationship, Store, Backpack, Game Center)
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 10,
                children: [
                  _buildGridIcon(Icons.star, 'VIP Center', Colors.amber),
                  _buildGridIcon(Icons.workspace_premium, 'Noble', Colors.purpleAccent),
                  _buildGridIcon(Icons.trending_up, 'Level', Colors.greenAccent),
                  _buildGridIcon(Icons.group, 'Group', Colors.blueAccent),
                  _buildGridIcon(Icons.favorite, 'Relationship', Colors.pinkAccent),
                  _buildGridIcon(Icons.store, 'Store', Colors.cyan),
                  _buildGridIcon(Icons.backpack, 'Backpack', Colors.orangeAccent),
                  _buildGridIcon(Icons.sports_esports, 'Game Center', Colors.redAccent),
                ],
              ),
              const SizedBox(height: 10),

              // List Options (My Room, My Xena Card, Agency CS, Settings)
              _buildListTile(context, Icons.meeting_room, 'My Room', onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const PartyRoomInsideScreen()));
              }),
              _buildListTile(context, Icons.card_membership, 'My Xena Card'),
              _buildListTile(context, Icons.headset_mic, 'Agency CS', onTap: () {
                _showAgencyCsBottomSheet(context);
              }),
              _buildListTile(context, Icons.settings, 'Settings', onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
              }),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridIcon(IconData icon, String label, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11), textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildListTile(BuildContext context, IconData icon, String title, {VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF190F3A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.purpleAccent),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white54),
        onTap: onTap ?? () {},
      ),
    );
  }

  void _showAgencyCsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF190F3A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Agency CS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 10),
              const TextField(
                decoration: InputDecoration(
                  hintText: 'Please tell us about your issue in a bit more detail...',
                  hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                  border: InputBorder.none,
                ),
                maxLines: 4,
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 10),
              Row(
                children: const [
                  Icon(Icons.sentiment_satisfied, color: Colors.amber),
                  SizedBox(width: 10),
                  Icon(Icons.add_circle_outline, color: Colors.purpleAccent),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  final String count;
  final String label;
  const _StatItem({Key? key, required this.count, required this.label}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(count, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white60)),
      ],
    );
  }
}

// Settings Screen matching video
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF150B2E),
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          ListTile(
            title: const Text('Account & Security', style: TextStyle(color: Colors.white)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text('Medium', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white54),
              ],
            ),
            onTap: () {},
          ),
          const Divider(color: Colors.white12),
          ListTile(
            title: const Text('Privacy', style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white54),
            onTap: () {},
          ),
          const Divider(color: Colors.white12),
          ListTile(
            title: const Text('Language', style: TextStyle(color: Colors.white)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text('English', style: TextStyle(color: Colors.white54)),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white54),
              ],
            ),
            onTap: () {},
          ),
          const Divider(color: Colors.white12),
          ListTile(
            title: const Text('Share', style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white54),
            onTap: () {},
          ),
          const Divider(color: Colors.white12),
          ListTile(
            title: const Text('About', style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white54),
            onTap: () {},
          ),
          const SizedBox(height: 40),
          Center(
            child: TextButton(
              onPressed: () {},
              child: const Text('Sign Out', style: TextStyle(color: Colors.pinkAccent, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

// Party Room Inside Screen matching video (20 Seats & Bottom Menu)
class PartyRoomInsideScreen extends StatelessWidget {
  const PartyRoomInsideScreen({Key? key}) : super(key: key);

  void _showRoomTools(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF190F3A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Interactive features', style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const [
                  _ToolItem(icon: Icons.confirmation_number, label: 'Counter', color: Colors.purpleAccent),
                  _ToolItem(icon: Icons.sports_kabaddi, label: 'PK', color: Colors.pinkAccent),
                  _ToolItem(icon: Icons.local_fire_department, label: 'Salute', color: Colors.orangeAccent),
                  _ToolItem(icon: Icons.card_giftcard, label: 'Red envelope', color: Colors.redAccent),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Management tool', style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const [
                  _ToolItem(icon: Icons.cleaning_services, label: 'Clean Text', color: Colors.blueAccent),
                  _ToolItem(icon: Icons.settings, label: 'Setting', color: Colors.greenAccent),
                  _ToolItem(icon: Icons.music_note, label: 'Music', color: Colors.amber),
                  _ToolItem(icon: Icons.mic, label: 'Voice Effect', color: Colors.purple),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const [
                  _ToolItem(icon: Icons.lock, label: 'Lock room', color: Colors.cyan),
                  _ToolItem(icon: Icons.mic_external_on, label: 'Mic Mode', color: Colors.pink, isNew: true),
                  _ToolItem(icon: Icons.image, label: 'Background', color: Colors.orange),
                  _ToolItem(icon: Icons.person_remove, label: 'Kick Record', color: Colors.red),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C061F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150'),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Shah G★★', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                Text('ID:9409405', style: TextStyle(fontSize: 9, color: Colors.white54)),
              ],
            ),
          ],
        ),
        actions: [
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: const [
                  Icon(Icons.emoji_events, size: 14, color: Colors.amber),
                  SizedBox(width: 4),
                  Text('27.7K', style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            alignment: Alignment.centerLeft,
            child: const Text('🔥 Hourly No. 100+', style: TextStyle(color: Colors.amber, fontSize: 12)),
          ),
          const SizedBox(height: 10),
          // 20 Seats Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.85,
              ),
              itemCount: 20,
              itemBuilder: (context, index) {
                return Column(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xFF1E123F),
                      child: Icon(
                        index == 0 ? Icons.person : Icons.lock_outline,
                        color: index == 0 ? Colors.amber : Colors.white38,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text('${index + 1}', style: const TextStyle(color: Colors.white60, fontSize: 10)),
                  ],
                );
              },
            ),
          ),
          // Room Announcement & Chat Box
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF150B2E),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Room Announcement', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 4),
                const Text('اس روم میں خوش آمدید! یہاں صرف شائستگی اور باوقار گفتگو کی جگہ ہے۔ بدتمیزی کی کوئی گنجائش نہیں۔', style: TextStyle(color: Colors.white70, fontSize: 11)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF22154A),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('Say Hi...', style: TextStyle(color: Colors.white38, fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const CircleAvatar(
                      backgroundColor: Color(0xFF22154A),
                      radius: 18,
                      child: Icon(Icons.card_giftcard, color: Colors.pinkAccent, size: 18),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _showRoomTools(context),
                      child: const CircleAvatar(
                        backgroundColor: Color(0xFF22154A),
                        radius: 18,
                        child: Icon(Icons.menu, color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isNew;
  const _ToolItem({Key? key, required this.icon, required this.label, required this.color, this.isNew = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFF22154A),
              child: Icon(icon, color: color, size: 22),
            ),
            if (isNew)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(color: Colors.pinkAccent, borderRadius: BorderRadius.circular(6)),
                  child: const Text('NEW', style: TextStyle(fontSize: 7, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }
}
