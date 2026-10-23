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
        selectedItemColor: Colors.purpleAccent,
        unselectedItemColor: Colors.white60,
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.live_tv), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.public), label: 'Moment'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Me'),
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
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Party Rooms', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () {},
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            _buildPartyRoomCard(
              context,
              roomName: 'Shah G ★★ Room',
              vipLevel: 'SVIP 1',
              welcomeText: 'Welcome everyone! Let\'s chat and have fun together.',
              onlineUsers: '392',
              badge: '🇵🇰',
            ),
            _buildPartyRoomCard(
              context,
              roomName: 'Murshad 🍁 G',
              vipLevel: 'SVIP 1',
              welcomeText: 'Welcome to audio party room.',
              onlineUsers: '138',
              badge: '🇵🇰',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartyRoomCard(
    BuildContext context, {
    required String roomName,
    required String vipLevel,
    required String welcomeText,
    required String onlineUsers,
    required String badge,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF231340), Color(0xFF150B28)]),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 26,
          backgroundColor: Colors.purple.shade700,
          child: const Icon(Icons.mic, color: Colors.white),
        ),
        title: Row(
          children: [
            Text(badge),
            const SizedBox(width: 4),
            Expanded(child: Text(roomName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            Text(onlineUsers, style: const TextStyle(color: Colors.pinkAccent, fontSize: 12)),
          ],
        ),
        subtitle: Text(welcomeText, style: const TextStyle(color: Colors.white54, fontSize: 12), maxLines: 1),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AudioPartyRoomScreen(roomName: roomName),
            ),
          );
        },
      ),
    );
  }
}

// Live Audio Party Room Screen with Internal Room Settings
class AudioPartyRoomScreen extends StatelessWidget {
  final String roomName;

  const AudioPartyRoomScreen({Key? key, required this.roomName}) : super(key: key);

  void _showRoomSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F1635),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Room Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber)),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.pinkAccent),
                title: const Text('Edit Room Notice & Name', style: TextStyle(color: Colors.white)),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.lock_outline, color: Colors.purpleAccent),
                title: const Text('Room Password Lock', style: TextStyle(color: Colors.white)),
                trailing: Switch(value: false, onChanged: (val) {}, activeColor: Colors.pinkAccent),
              ),
              ListTile(
                leading: const Icon(Icons.mic_off, color: Colors.redAccent),
                title: const Text('Lock All Seats', style: TextStyle(color: Colors.white)),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.volume_up, color: Colors.blueAccent),
                title: const Text('Background Music & Sound Effects', style: TextStyle(color: Colors.white)),
                onTap: () {},
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
      backgroundColor: const Color(0xFF090414),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(roomName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            const Text('ID: 1002394 • 392 Online', style: TextStyle(fontSize: 11, color: Colors.white54)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () => _showRoomSettings(context),
          ),
          IconButton(
            icon: const Icon(Icons.power_settings_new, color: Colors.redAccent),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 16,
                crossAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              itemCount: 10,
              itemBuilder: (context, index) {
                return Column(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xFF1F1635),
                      child: Icon(
                        index == 0 ? Icons.mic : Icons.lock,
                        color: index == 0 ? Colors.purpleAccent : Colors.white30,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('No.${index + 1}', style: const TextStyle(color: Colors.white54, fontSize: 10)),
                  ],
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            height: 100,
            child: ListView(
              children: const [
                Text('Welcome to the party room!', style: TextStyle(color: Colors.amberAccent, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFF150F24),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF23163E),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Say Hi...', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 10),
                const CircleAvatar(
                  backgroundColor: Color(0xFF23163E),
                  child: Icon(Icons.mic_none, color: Colors.white),
                ),
                const SizedBox(width: 8),
                const CircleAvatar(
                  backgroundColor: Color(0xFF23163E),
                  child: Icon(Icons.card_giftcard, color: Colors.pinkAccent),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LovelyProfileScreen extends StatelessWidget {
  const LovelyProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Profile Screen', style: TextStyle(color: Colors.white)),
    );
  }
}
