import 'package:flutter/material.dart';

void main() {
  runApp(const LovelyApp());
}

class LovelyApp extends StatelessWidget {
  const LovelyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lovely Chat',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0B1E),
        primarySwatch: Colors.purple,
      ),
      home: const MainHomeScreen(),
    );
  }
}

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({Key? key}) : super(key: key);

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const PartyRoomsHomeScreen(),
    const Center(child: Text('Moments Screen', style: TextStyle(color: Colors.white))),
    const Center(child: Text('Chat Screen', style: TextStyle(color: Colors.white))),
    const LovelyProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF150F24),
        selectedItemColor: Colors.pinkAccent,
        unselectedItemColor: Colors.white60,
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.live_tv), label: 'Live'),
          BottomNavigationBarItem(icon: Icon(Icons.public), label: 'Moments'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble), label: 'Message'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Me'),
        ],
      ),
    );
  }
}

class PartyRoomsHomeScreen extends StatelessWidget {
  const PartyRoomsHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: DefaultTabController(
        length: 4,
        initialIndex: 1,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  const Expanded(
                    child: TabBar(
                      isScrollable: true,
                      indicatorColor: Colors.pinkAccent,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white54,
                      tabs: [
                        Tab(text: 'Mine'),
                        Tab(text: 'Hot'),
                        Tab(text: 'Message'),
                        Tab(text: 'Follow'),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.white),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF633214), Color(0xFF381F0D)]),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.diamond, color: Colors.amber, size: 36),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('King of Kings', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: 16)),
                              Text('Become and enjoy exclusive privileges', style: TextStyle(fontSize: 12, color: Colors.white70)),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
                          onPressed: () {},
                          child: const Text('Activate'),
                        ),
                      ],
                    ),
                  ),
                  _buildRoomCard(context, 'Shah G Video Live Room', 'Video Stream', '520', true),
                  _buildRoomCard(context, 'Murshad Audio Party Room', 'Audio Party', '138', false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomCard(BuildContext context, String name, String type, String online, bool isVideo) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1635),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isVideo ? Colors.pinkAccent : Colors.purple,
          child: Icon(isVideo ? Icons.videocam : Icons.mic, color: Colors.white),
        ),
        title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(type, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        trailing: Text(online, style: const TextStyle(color: Colors.pinkAccent)),
        onTap: () {
          if (isVideo) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => VideoLiveRoomScreen(roomName: name)));
          } else {
            Navigator.push(context, MaterialPageRoute(builder: (context) => AudioPartyRoomScreen(roomName: name)));
          }
        },
      ),
    );
  }
}

class VideoLiveRoomScreen extends StatelessWidget {
  final String roomName;
  const VideoLiveRoomScreen({Key? key, required this.roomName}) : super(key: key);

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
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  const CircleAvatar(backgroundImage: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150')),
                  const SizedBox(width: 8),
                  Text(roomName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AudioPartyRoomScreen extends StatelessWidget {
  final String roomName;
  const AudioPartyRoomScreen({Key? key, required this.roomName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090414),
      appBar: AppBar(backgroundColor: Colors.transparent, title: Text(roomName)),
      body: const Center(child: Text('Audio Party Room Seats', style: TextStyle(color: Colors.white54))),
    );
  }
}

class LovelyProfileScreen extends StatefulWidget {
  const LovelyProfileScreen({Key? key}) : super(key: key);

  @override
  State<LovelyProfileScreen> createState() => _LovelyProfileScreenState();
}

class _LovelyProfileScreenState extends State<LovelyProfileScreen> {
  void _showWithdrawDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F1635),
      builder: (context) => const Padding(
        padding: EdgeInsets.all(20.0),
        child: Text('Withdraw Earnings: Available Diamonds 0 (\$0.00)', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _showRechargeDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F1635),
      builder: (context) => const Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Online Recharge Coins', style: TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            ListTile(leading: Icon(Icons.phone_android, color: Colors.green), title: Text('Easypaisa')),
            ListTile(leading: Icon(Icons.phone_android, color: Colors.orange), title: Text('JazzCash')),
            ListTile(leading: Icon(Icons.credit_card, color: Colors.blue), title: Text('Credit / Debit Card')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                height: 180,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF4A154B), Color(0xFF1E1035)]),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 32,
                        backgroundImage: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150'),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Addison', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                            SizedBox(height: 4),
                            Text('ID: 41794595 • PK 18', style: TextStyle(fontSize: 12, color: Colors.white70)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings, color: Colors.white),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage())),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF633214), Color(0xFF381F0D)]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.diamond, color: Colors.amber, size: 36),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('King of Kings', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: 16)),
                            Text('Become and enjoy exclusive privileges', style: TextStyle(fontSize: 12, color: Colors.white70)),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
                        onPressed: () {},
                        child: const Text('Activate'),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: const Color(0xFF1F1635), borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Coins: 0', style: TextStyle(color: Colors.white)),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
                              onPressed: () => _showRechargeDialog(context),
                              child: const Text('Recharge'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: const Color(0xFF1F1635), borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Diamonds: 0', style: TextStyle(color: Colors.white)),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent, foregroundColor: Colors.white),
                              onPressed: () => _showWithdrawDialog(context),
                              child: const Text('Withdraw'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: const [
                    Column(children: [Icon(Icons.task, color: Colors.amber), SizedBox(height: 4), Text('Task', style: TextStyle(fontSize: 12))]),
                    Column(children: [Icon(Icons.trending_up, color: Colors.pinkAccent), SizedBox(height: 4), Text('Level', style: TextStyle(fontSize: 12))]),
                    Column(children: [Icon(Icons.backpack, color: Colors.purpleAccent), SizedBox(height: 4), Text('Backpack', style: TextStyle(fontSize: 12))]),
                    Column(children: [Icon(Icons.store, color: Colors.cyan), SizedBox(height: 4), Text('Store', style: TextStyle(fontSize: 12))]),
                  ],
                ),
                const Divider(color: Colors.white24, height: 24),
                ListTile(
                  leading: const Icon(Icons.settings, color: Colors.purpleAccent),
                  title: const Text('Setting', style: TextStyle(color: Colors.white)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white54),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage())),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1F1635),
      ),
      body: ListView(
        children: const [
          ListTile(
            leading: Icon(Icons.person, color: Colors.pinkAccent),
            title: Text('Edit Profile Name', style: TextStyle(color: Colors.white)),
            subtitle: Text('Addison', style: TextStyle(color: Colors.white54, fontSize: 12)),
          ),
          ListTile(
            leading: Icon(Icons.lock, color: Colors.purpleAccent),
            title: Text('Password & Security', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
