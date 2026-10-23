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
  int _currentIndex = 0; // 0: Home/Live, 1: Moment, 2: Chat, 3: Me

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

class PartyRoomsHomeScreen extends StatefulWidget {
  const PartyRoomsHomeScreen({Key? key}) : super(key: key);

  @override
  State<PartyRoomsHomeScreen> createState() => _PartyRoomsHomeScreenState();
}

class _PartyRoomsHomeScreenState extends State<PartyRoomsHomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: 1);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Top Header Bar (Mine, Hot, Message, Search & Add)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    indicatorColor: Colors.pinkAccent,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white54,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    tabs: const [
                      Tab(text: 'Mine'),
                      Tab(text: 'Hot'),
                      Tab(text: 'Message'),
                      Tab(text: 'Follow'),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.white),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const SearchRoomScreen()));
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Top Offer Banner
                  Container(
                    margin: const EdgeInsets.all(12),
                    height: 90,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF5B1782), Color(0xFF280B43)],
                      ),
                      border: Border.all(color: Colors.amber.withOpacity(0.4)),
                    ),
                    child: const Center(
                      child: Text(
                        'COMMISSION STRUCTURE & PAYMENTS\nCoin Seller & Agent Bonus',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  // Country Category Badges
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        _buildCategoryChip('ALL', true),
                        _buildCategoryChip('Pakistan 🇵🇰', false),
                        _buildCategoryChip('Philippines 🇵🇭', false),
                        _buildCategoryChip('Indonesia 🇮🇩', false),
                        _buildCategoryChip('KSA 🇸🇦', false),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // CP, Family & Rank Cards
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Row(
                      children: [
                        Expanded(child: _buildSmallCard('CP', Colors.purpleAccent, Icons.favorite)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildSmallCard('Family', Colors.blueAccent, Icons.group)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildSmallCard('Rank', Colors.amber, Icons.emoji_events)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Room Cards List
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
                    welcomeText: 'Welcome everyone! Let\'s chat and have fun.',
                    onlineUsers: '138',
                    badge: '🇵🇰',
                  ),
                  _buildPartyRoomCard(
                    context,
                    roomName: 'Pak cs activity',
                    vipLevel: 'SVIP 2',
                    welcomeText: 'Welcome to pakistan customer service room',
                    onlineUsers: '42',
                    badge: '🇵🇰',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? Colors.purpleAccent : const Color(0xFF1F1635),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSmallCard(String title, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1635),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
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
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF231340), Color(0xFF150B28)],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Stack(
          alignment: Alignment.center,
          children: [
            const CircleAvatar(
              radius: 26,
              backgroundImage: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150'),
            ),
            Positioned(
              top: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(4)),
                child: Text(vipLevel, style: const TextStyle(fontSize: 8, color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        title: Row(
          children: [
            Text(badge, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            Expanded(child: Text(roomName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
            Row(
              children: [
                const Icon(Icons.equalizer, color: Colors.pinkAccent, size: 14),
                const SizedBox(width: 2),
                Text(onlineUsers, style: const TextStyle(color: Colors.pinkAccent, fontSize: 12)),
              ],
            ),
          ],
        ),
        subtitle: Text(
          welcomeText,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AudioPartyRoomScreen(roomName: roomName, onlineUsers: onlineUsers),
            ),
          );
        },
      ),
    );
  }
}

// Live Audio Party Room Screen
class AudioPartyRoomScreen extends StatelessWidget {
  final String roomName;
  final String onlineUsers;

  const AudioPartyRoomScreen({Key? key, required this.roomName, required this.onlineUsers}) : super(key: key);

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
            Text('ID: 1002394 • $onlineUsers Online', style: const TextStyle(fontSize: 11, color: Colors.white54)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.share, color: Colors.white), onPressed: () {}),
          IconButton(icon: const Icon(Icons.power_settings_new, color: Colors.redAccent), onPressed: () => Navigator.pop(context)),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),

          // 10 Seats Grid Layout
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
                    Text(
                      'No.${index + 1}',
                      style: const TextStyle(color: Colors.white54, fontSize: 10),
                    ),
                  ],
                );
              },
            ),
          ),

          // Chat Messages Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            height: 120,
            child: ListView(
              children: const [
                Text('Welcome everyone! Let\'s chat and have fun together.', style: TextStyle(color: Colors.amberAccent, fontSize: 12)),
                SizedBox(height: 4),
                Text('User entered the room', style: TextStyle(color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),

          // Bottom Bar (Say Hi, Mic, Gift)
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

// Search Room / User Screen
class SearchRoomScreen extends StatelessWidget {
  const SearchRoomScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1635),
        title: TextField(
          decoration: const InputDecoration(
            hintText: 'Enter Room ID / User ID',
            hintStyle: TextStyle(color: Colors.white54),
            border: InputBorder.none,
          ),
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.purpleAccent),
            SizedBox(height: 12),
            Text('User Info not found', style: TextStyle(color: Colors.white54)),
          ],
        ),
      ),
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
                  const Text('Withdraw Earnings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber)),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 10),
              const Text('Available Diamonds: 0 (\$0.00)', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 15),
              TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Enter Diamond Amount',
                  labelStyle: const TextStyle(color: Colors.white54),
                  focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.pinkAccent), borderRadius: BorderRadius.circular(10)),
                  enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white24), borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent, padding: const EdgeInsets.symmetric(vertical: 12)),
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Withdrawal request submitted!')));
                  },
                  child: const Text('Submit Request', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRechargeDialog(BuildContext context) {
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
                  const Text('Online Recharge Coins', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber)),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.phone_android, color: Colors.green),
                title: const Text('Easypaisa', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selected Easypaisa for Recharge')));
                },
              ),
              ListTile(
                leading: const Icon(Icons.phone_android, color: Colors.orange),
                title: const Text('JazzCash', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selected JazzCash for Recharge')));
                },
              ),
              ListTile(
                leading: const Icon(Icons.credit_card, color: Colors.blueAccent),
                title: const Text('Credit / Debit Card', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selected Card Payment for Recharge')));
                },
              ),
            ],
          ),
        );
      },
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Addison', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(10)),
                                  child: const Text('PK 18', style: TextStyle(fontSize: 10, color: Colors.white)),
                                ),
                                const SizedBox(width: 8),
                                const Text('ID: 41794595', style: TextStyle(fontSize: 12, color: Colors.white70)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings, color: Colors.white),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage()));
                        },
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
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
                        onPressed: () => _showRechargeDialog(context),
                        child: const Text('Recharge'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent, foregroundColor: Colors.white),
                        onPressed: () => _showWithdrawDialog(context),
                        child: const Text('Withdraw'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.settings, color: Colors.purpleAccent),
                  title: const Text('Setting', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage()));
                  },
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
