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
      home: const LovelyProfileScreen(),
    );
  }
}

class LovelyProfileScreen extends StatefulWidget {
  const LovelyProfileScreen({Key? key}) : super(key: key);

  @override
  State<LovelyProfileScreen> createState() => _LovelyProfileScreenState();
}

class _LovelyProfileScreenState extends State<LovelyProfileScreen> {
  int _currentIndex = 4; // 'Me' tab selected

  void _showWithdrawDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F1635),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
                  const Text(
                    'Withdraw Earnings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Available Diamonds: 0 (\$0.00)',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 15),
              TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Enter Diamond Amount',
                  labelStyle: const TextStyle(color: Colors.white54),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.pinkAccent),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white24),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Withdrawal request submitted!')),
                    );
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
                  const Text(
                    'Online Recharge Coins',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Select Payment Method:',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.phone_android, color: Colors.green),
                title: const Text('Easypaisa', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Instant Mobile Deposit', style: TextStyle(color: Colors.white54, fontSize: 12)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white54),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Selected Easypaisa for Recharge')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.phone_android, color: Colors.orange),
                title: const Text('JazzCash', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Instant Mobile Deposit', style: TextStyle(color: Colors.white54, fontSize: 12)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white54),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Selected JazzCash for Recharge')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.credit_card, color: Colors.blueAccent),
                title: const Text('Credit / Debit Card', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Visa / Mastercard', style: TextStyle(color: Colors.white54, fontSize: 12)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white54),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Selected Card Payment for Recharge')),
                  );
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
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  height: 180,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF4A154B), Color(0xFF1E1035)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
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
                              const Text(
                                'Addison',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
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
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const SettingsPage()),
                            );
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
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF633214), Color(0xFF381F0D)],
                      ),
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          onPressed: () {},
                          child: const Text('Activate', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),

                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1F1635),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.monetization_on, color: Colors.amber),
                                  SizedBox(height: 4),
                                  Text('0', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                ],
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                ),
                                onPressed: () => _showRechargeDialog(context),
                                child: const Text('Recharge', style: TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1F1635),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.diamond_outlined, color: Colors.pinkAccent),
                                  SizedBox(height: 4),
                                  Text('0', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                ],
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.pinkAccent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                ),
                                onPressed: () => _showWithdrawDialog(context),
                                child: const Text('Withdraw', style: TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF5D3906), Color(0xFF8B6508)]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        'Earn up to \$27 by inviting new users',
                        style: TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildGridItem(Icons.task, 'Task', Colors.amber),
                      _buildGridItem(Icons.trending_up, 'Level', Colors.pinkAccent),
                      _buildGridItem(Icons.favorite, 'Fans Club', Colors.redAccent),
                      _buildGridItem(Icons.sports_esports, 'Game', Colors.blueAccent),
                      _buildGridItem(Icons.backpack, 'Backpack', Colors.purpleAccent),
                      _buildGridItem(Icons.store, 'Dress Store', Colors.cyan),
                      _buildGridItem(Icons.flag, 'Event Center', Colors.pink),
                    ],
                  ),

                  const Divider(color: Colors.white24, height: 24),

                  _buildListTile(Icons.account_balance_wallet, 'Withdraw Method', onTap: () => _showWithdrawDialog(context)),
                  _buildListTile(Icons.star, 'VIP'),
                  _buildListTile(Icons.security, 'Guardian'),
                  _buildListTile(Icons.face, 'Real person detection'),
                  _buildListTile(Icons.help_outline, 'Help & Feedback'),
                  _buildListTile(Icons.headset_mic, 'Customer Service'),
                  _buildListTile(Icons.settings, 'Setting', onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsPage()),
                    );
                  }),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
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
          BottomNavigationBarItem(icon: Icon(Icons.celebration), label: 'Party'),
          BottomNavigationBarItem(icon: Icon(Icons.public), label: 'Moments'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble), label: 'Message'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Me'),
        ],
      ),
    );
  }

  Widget _buildGridItem(IconData icon, String title, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 6),
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.white70)),
      ],
    );
  }

  Widget _buildListTile(IconData icon, String title, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.purpleAccent),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white54),
      onTap: onTap ?? () {},
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1F1635),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Profile Management', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline, color: Colors.pinkAccent),
            title: const Text('Edit Profile Name & Info', style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white54),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Edit Profile settings tapped')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.badge, color: Colors.pinkAccent),
            title: const Text('Account ID & Region', style: TextStyle(color: Colors.white)),
            subtitle: const Text('ID: 41794595 (PK 18)', style: TextStyle(color: Colors.white54, fontSize: 12)),
            onTap: () {},
          ),
          const Divider(color: Colors.white24),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('App Settings', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_none, color: Colors.purpleAccent),
            title: const Text('Notifications', style: TextStyle(color: Colors.white)),
            trailing: Switch(value: true, onChanged: (val) {}, activeColor: Colors.pinkAccent),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline, color: Colors.purpleAccent),
            title: const Text('Privacy & Security', style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white54),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.language, color: Colors.purpleAccent),
            title: const Text('Language', style: TextStyle(color: Colors.white)),
            subtitle: const Text('English', style: TextStyle(color: Colors.white54, fontSize: 12)),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.purpleAccent),
            title: const Text('About Version', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Lovely Chat v1.0.0', style: TextStyle(color: Colors.white54, fontSize: 12)),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
