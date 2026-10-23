import 'package:flutter/material.dart';

void main() {
  runApp(const XenaApp());
}

class XenaApp extends StatelessWidget {
  const XenaApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Xena',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF120B29),
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
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const XenaRoomsScreen(),
    const XenaVideoLiveScreen(),
    const Center(child: Text('Message Screen', style: TextStyle(color: Colors.white))),
    const XenaProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF190F3A),
        selectedItemColor: Colors.amberAccent,
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
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Message'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

// Xena Party Rooms Screen
class XenaRoomsScreen extends StatelessWidget {
  const XenaRoomsScreen({Key? key}) : super(key: key);

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
                indicatorColor: Colors.amberAccent,
                labelColor: Colors.amberAccent,
                unselectedLabelColor: Colors.white54,
                tabs: [
                  Tab(text: 'Hot'),
                  Tab(text: 'Party'),
                  Tab(text: 'Follow'),
                ],
              ),
              actions: [
                IconButton(icon: const Icon(Icons.search, color: Colors.white), onPressed: () {}),
              ],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  _buildRoomCard(context, 'Xena Official Party Room', 'PK 🇵🇰', '1.2k', true),
                  _buildRoomCard(context, 'Royal Music & Chat', 'PK 🇵🇰', '850', true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomCard(BuildContext context, String title, String country, String online, bool isAudioParty) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF22154A),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: ListTile(
        leading: const CircleAvatar(
          radius: 28,
          backgroundImage: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150'),
        ),
        title: Row(
          children: [
            Text(country, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 6),
            Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          ],
        ),
        subtitle: Text('Online: $online', style: const TextStyle(color: Colors.amberAccent, fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white54),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => XenaAudioRoomScreen(roomName: title)),
          );
        },
      ),
    );
  }
}

// Xena Audio Party Room with Seats & Settings
class XenaAudioRoomScreen extends StatelessWidget {
  final String roomName;
  const XenaAudioRoomScreen({Key? key, required this.roomName}) : super(key: key);

  void _showRoomSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1242),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Room Settings', style: TextStyle(color: Colors.amberAccent, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.pinkAccent),
                title: const Text('Edit Room Notice', style: TextStyle(color: Colors.white)),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.lock, color: Colors.amber),
                title: const Text('Room Password Lock', style: TextStyle(color: Colors.white)),
                trailing: Switch(value: false, onChanged: (val) {}, activeColor: Colors.amberAccent),
              ),
              ListTile(
                leading: const Icon(Icons.mic_off, color: Colors.redAccent),
                title: const Text('Lock All Seats', style: TextStyle(color: Colors.white)),
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
      backgroundColor: const Color(0xFF0C061F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(roomName, style: const TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () => _showRoomSettings(context),
          ),
        ],
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
                backgroundColor: const Color(0xFF2B1A5E),
                child: Icon(index == 0 ? Icons.mic : Icons.lock, color: index == 0 ? Colors.amberAccent : Colors.white30),
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

// Xena Video Live Screen
class XenaVideoLiveScreen extends StatelessWidget {
  const XenaVideoLiveScreen({Key? key}) : super(key: key);

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
                  const CircleAvatar(backgroundImage: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150')),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Xena Live Host', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text('ID: 8849201', style: TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white),
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

// Xena Profile & Wallet Screen
class XenaProfileScreen extends StatelessWidget {
  const XenaProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF3F196E), Color(0xFF190F3A)]),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 35,
                    backgroundImage: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150'),
                  ),
                  const SizedBox(width: 15),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Xena User', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                        SizedBox(height: 4),
                        Text('Xena ID: 5928104', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.amberAccent, size: 28),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22154A),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      const Column(
                        children: [
                          Text('Coins: 0', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          Text('Easypaisa / JazzCash', style: TextStyle(color: Colors.amberAccent, fontSize: 12)),
                        ],
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.amberAccent, foregroundColor: Colors.black),
                        onPressed: () {},
                        child: const Text('Recharge'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.account_balance_wallet, color: Colors.pinkAccent),
                  title: const Text('Withdraw', style: TextStyle(color: Colors.white)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white54),
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(Icons.security, color: Colors.purpleAccent),
                  title: const Text('Password & Security', style: TextStyle(color: Colors.white)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white54),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
