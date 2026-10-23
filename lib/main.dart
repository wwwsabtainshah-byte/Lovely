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
      home: const XenaMainScreen(),
    );
  }
}

class XenaMainScreen extends StatefulWidget {
  const XenaMainScreen({Key? key}) : super(key: key);

  @override
  State<XenaMainScreen> createState() => _XenaMainScreenState();
}

class _XenaMainScreenState extends State<XenaMainScreen> {
  int _currentIndex = 3; // 'Me' tab selected by default as in video

  final List<Widget> _pages = [
    const Center(child: Text('Home Screen', style: TextStyle(color: Colors.white))),
    const Center(child: Text('Moment Screen', style: TextStyle(color: Colors.white))),
    const Center(child: Text('Chat Screen', style: TextStyle(color: Colors.white))),
    const XenaProfileScreen(),
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
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.public), label: 'Moment'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Me'),
        ],
      ),
    );
  }
}

class XenaProfileScreen extends StatelessWidget {
  const XenaProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white54),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              // Profile Header
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen()));
                    },
                    child: const CircleAvatar(
                      radius: 32,
                      backgroundImage: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Text('Shah G', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                          SizedBox(width: 6),
                          Icon(Icons.verified, size: 16, color: Colors.blueAccent),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text('ID: 1002370', style: TextStyle(fontSize: 12, color: Colors.white54)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Visitors, Following, Followers Stats Box
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B113A),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const [
                    _StatItem(count: '358', label: 'Visitors'),
                    _StatItem(count: '60', label: 'Following'),
                    _StatItem(count: '202', label: 'Followers'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Get VIP Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF3B1E63), Color(0xFF1B113A)]),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.star, color: Colors.amber, size: 28),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Get VIP, Exclusive Benefits', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ),
                    Chip(
                      backgroundColor: Colors.pinkAccent,
                      label: Text('Get VIP >', style: TextStyle(color: Colors.white, fontSize: 11)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // SVIP & Level Banners
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B113A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text('SVIP', style: TextStyle(fontStyle: FontStyle.italic, fontWeight: FontWeight.bold, fontSize: 18, color: Colors.amberAccent)),
                          Icon(Icons.diamond, color: Colors.amber, size: 28),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B113A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text('Level', style: TextStyle(fontStyle: FontStyle.italic, fontWeight: FontWeight.bold, fontSize: 18, color: Colors.pinkAccent)),
                          Icon(Icons.flash_on, color: Colors.pinkAccent, size: 28),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Wallet, Store, Bag, Reward Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const [
                  _FeatureButton(icon: Icons.account_balance_wallet, label: 'Wallet'),
                  _FeatureButton(icon: Icons.store, label: 'Store'),
                  _FeatureButton(icon: Icons.backpack, label: 'Bag'),
                  _FeatureButton(icon: Icons.card_giftcard, label: 'Reward'),
                ],
              ),
              const SizedBox(height: 16),

              // List Options matching video exactly
              _buildListTile(Icons.group, 'Family'),
              _buildListTile(Icons.favorite, 'CP'),
              _buildListTile(Icons.people, 'Brother and Sister'),
              _buildListTile(Icons.person_add, 'Invite Friends'),
              _buildListTile(Icons.support_agent, 'Host Center'),
              _buildListTile(Icons.business_center, 'BD Center'),
              _buildListTile(Icons.headset_mic, 'Contact us'),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListTile(IconData icon, String title) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF150B2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.purpleAccent, size: 22),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white38),
        onTap: () {},
      ),
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
        Text(count, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white54)),
      ],
    );
  }
}

class _FeatureButton extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureButton({Key? key, required this.icon, required this.label}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: const Color(0xFF1B113A),
          child: Icon(icon, color: Colors.amberAccent, size: 22),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}

// Edit Profile Screen (from video timestamp 0:16)
class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF150B2E),
        title: const Text('Edit Profile', style: TextStyle(color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Stack(
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundImage: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150'),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.pinkAccent,
                    child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildEditTile('User Name', 'Shah G'),
          _buildEditTile('Gender', 'Male'),
          _buildEditTile('Birthday', '29-08-2008'),
          _buildEditTile('Country', 'Pakistan'),
          const SizedBox(height: 20),
          const Text('Photo Album', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(4, (index) => Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFF1B113A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: const Icon(Icons.add, color: Colors.purpleAccent),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildEditTile(String label, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF150B2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}

// Settings Screen (from video timestamp 0:21)
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF150B2E),
        title: const Text('Setting', style: TextStyle(color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildSettingTile('Language'),
          _buildSettingTile('Connection options'),
          _buildSettingTile('Account Security'),
          _buildSettingTile('Feedback'),
          _buildSettingTile('About Us'),
          const SizedBox(height: 40),
          Center(
            child: Container(
              width: double.infinity,
              height: 45,
              decoration: BoxDecoration(
                color: const Color(0xFF1B113A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.pinkAccent.withOpacity(0.5)),
              ),
              child: const Center(
                child: Text('LogOut', style: TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile(String title) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF150B2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white38),
        onTap: () {},
      ),
    );
  }
}
