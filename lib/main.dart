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
          title: const Text('Live & Party Rooms', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
            _buildRoomCard(
              context,
              roomName: 'Shah G Live Video Stream',
              type: 'Video Room',
              onlineUsers: '520',
              badge: '🇵🇰',
              isVideo: true,
            ),
            _buildRoomCard(
              context,
              roomName: 'Murshad Audio Party',
              type: 'Audio Room',
              onlineUsers: '138',
              badge: '🇵🇰',
              isVideo: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomCard(
    BuildContext context, {
    required String roomName,
    required String type,
    required String onlineUsers,
    required String badge,
    required bool isVideo,
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
          backgroundColor: isVideo ? Colors.pink.shade700 : Colors.purple.shade700,
          child: Icon(isVideo ? Icons.videocam : Icons.mic, color: Colors.white),
        ),
        title: Row(
          children: [
            Text(badge),
            const SizedBox(width: 4),
            Expanded(child: Text(roomName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            Text(onlineUsers, style: const TextStyle(color: Colors.pinkAccent, fontSize: 12)),
          ],
        ),
        subtitle: Text(type, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        onTap: () {
          if (isVideo) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => VideoLiveRoomScreen(roomName: roomName)),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AudioPartyRoomScreen(roomName: roomName)),
            );
          }
        },
      ),
    );
  }
}

// Video Live Streaming Room Screen
class VideoLiveRoomScreen extends StatelessWidget {
  final String roomName;

  const VideoLiveRoomScreen({Key? key, required this.roomName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Video Placeholder / Stream Feed
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
          // Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black54, Colors.transparent, Colors.black87],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          // Top Host Info Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150'),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(roomName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      const Text('ID: 41794595 • 520 Watching', style: TextStyle(color: Colors.white70, fontSize: 10)),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ),
          // Bottom Chat & Interaction Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Text('Say something to the host...', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const CircleAvatar(
                    backgroundColor: Colors.pinkAccent,
                    child: Icon(Icons.card_giftcard, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  const CircleAvatar(
                    backgroundColor: Colors.purple,
                    child: Icon(Icons.favorite, color: Colors.white),
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

// Audio Party Room Screen
class AudioPartyRoomScreen extends StatelessWidget {
  final String roomName;

  const AudioPartyRoomScreen({Key? key, required this.roomName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090414),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(roomName, style: const TextStyle(fontSize: 16, color: Colors.white)),
      ),
      body: const Center(
        child: Text('Audio Party Room Seats & Chat', style: TextStyle(color: Colors.white54)),
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
