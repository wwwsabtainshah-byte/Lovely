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
      home: const LoginScreen(),
    );
  }
}

// 1. Exact Login Screen with Google Login Integration
class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  // Simulated Google Login action
  void _handleGoogleLogin(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B113A),
        title: const Text('Google Sign-In', style: TextStyle(color: Colors.white)),
        content: const Text('Opening Google account selector to sign in...', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const XenaMainHomeScreen()),
              );
            },
            child: const Text('Continue', style: TextStyle(color: Colors.pinkAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C061F),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Text(
                'Welcome to Xena',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              const Text(
                'Log in to connect with friends, live streaming and party rooms.',
                style: TextStyle(color: Colors.white60, fontSize: 14),
              ),
              const SizedBox(height: 40),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Enter Phone Number or Email',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF1B113A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              TextField(
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Password',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF1B113A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const XenaMainHomeScreen()),
                    );
                  },
                  child: const Text('Log In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 16),
              // Google Login Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: const Color(0xFF1B113A),
                  ),
                  onPressed: () => _handleGoogleLogin(context),
                  icon: const Icon(Icons.g_mobiledata, color: Colors.white, size: 28),
                  label: const Text('Sign in with Google', style: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 2. Main Navigation Screen
class XenaMainHomeScreen extends StatefulWidget {
  const XenaMainHomeScreen({Key? key}) : super(key: key);

  @override
  State<XenaMainHomeScreen> createState() => _XenaMainHomeScreenState();
}

class _XenaMainHomeScreenState extends State<XenaMainHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const PartyRoomsScreen(),
    const VideoLiveStreamingScreen(),
    const Center(child: Text('Message Screen', style: TextStyle(color: Colors.white))),
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
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Rooms'),
          BottomNavigationBarItem(icon: Icon(Icons.videocam), label: 'Live'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble), label: 'Message'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Me'),
        ],
      ),
    );
  }
}

// 3. Party Rooms Screen
class PartyRoomsScreen extends StatelessWidget {
  const PartyRoomsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: const TabBar(
                indicatorColor: Colors.pinkAccent,
                labelColor: Colors.pinkAccent,
                unselectedLabelColor: Colors.white54,
                tabs: [
                  Tab(text: 'Hot'),
                  Tab(text: 'Party'),
                  Tab(text: 'Follow'),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  _buildRoomCard(context, 'Xena Official Party Room', 'PK 🇵🇰', '1.2k'),
                  _buildRoomCard(context, 'Royal Music & Chat', 'PK 🇵🇰', '850'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomCard(BuildContext context, String title, String country, String online) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1B113A),
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: const CircleAvatar(
          radius: 26,
          backgroundImage: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150'),
        ),
        title: Row(
          children: [
            Text(country, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 6),
            Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          ],
        ),
        subtitle: Text('Online: $online', style: const TextStyle(color: Colors.pinkAccent, fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white38),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AudioPartyRoomInside(roomName: title)),
          );
        },
      ),
    );
  }
}

// Audio Party Room Inside (Seats & Controls)
class AudioPartyRoomInside extends StatelessWidget {
  final String roomName;
  const AudioPartyRoomInside({Key? key, required this.roomName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C061F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(roomName, style: const TextStyle(fontSize: 15)),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 20,
          crossAxisSpacing: 16,
        ),
        itemCount: 8,
        itemBuilder: (context, index) {
          return Column(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFF1B113A),
                child: Icon(index == 0 ? Icons.mic : Icons.lock, color: index == 0 ? Colors.pinkAccent : Colors.white38),
              ),
              const SizedBox(height: 6),
              Text('Seat ${index + 1}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
            ],
          );
        },
      ),
    );
  }
}

// 4. Video Live Streaming Screen
class VideoLiveStreamingScreen extends StatelessWidget {
  const VideoLiveStreamingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=600'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundImage: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150'),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text('Xena Live Host', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text('ID: 9409405', style: TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 5. Complete Profile Screen with all original items
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
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: const Color(0xFF1B113A), borderRadius: BorderRadius.circular(12)),
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
                      decoration: BoxDecoration(color: const Color(0xFF1B113A), borderRadius: BorderRadius.circular(12)),
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

// Edit Profile Screen
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

// Settings Screen
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
