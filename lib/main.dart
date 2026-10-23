import 'package:flutter/material.dart';

void main() {
  runApp(const LovelyApp());
}

class LovelyApp extends StatelessWidget {
  const LovelyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lovely Chat',
      theme: ThemeData(
        primarySwatch: Colors.pink,
      ),
      home: const LovelyHomeScreen(),
    );
  }
}

class LovelyHomeScreen extends StatelessWidget {
  const LovelyHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lovely Live Streaming & Host Center'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildFeatureCard(context, 'Wallet & Coins', Icons.account_balance_wallet, Colors.amber),
          _buildFeatureCard(context, 'VIP Center', Icons.star, Colors.purple),
          _buildFeatureCard(context, 'Inventory', Icons.inventory, Colors.blue),
          _buildFeatureCard(context, 'Host Center', Icons.live_tv, Colors.red),
          _buildFeatureCard(context, 'Live Streaming Room', Icons.video_call, Colors.green),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context, String title, IconData icon, Color color) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: Icon(icon, color: color, size: 36),
        title: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Opening $title...')),
          );
        },
      ),
    );
  }
}
