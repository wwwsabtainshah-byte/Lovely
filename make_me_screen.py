from pathlib import Path

p = Path("lib/main.dart")
s = p.read_text()

start = s.index("class ProfilePage extends StatelessWidget")
end = s.index("class ProfileStat extends StatelessWidget")

new = r'''
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ImagePicker picker = ImagePicker();
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  String username = 'Lovely User';
  String userId = 'ID: Loading...';
  String? photoPath;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    final name = await storage.read(key: 'lovely_username');
    if (!mounted) return;
    setState(() {
      if (name != null && name.isNotEmpty) username = name;
      userId = 'ID: ${name ?? 'Lovely User'}';
    });
  }

  Future<void> choosePhoto() async {
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      imageQuality: 70,
    );
    if (image != null && mounted) {
      setState(() => photoPath = image.path);
    }
  }

  void copyId() {
    Clipboard.setData(
      ClipboardData(text: userId.replaceFirst('ID: ', '')),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ID copied')),
    );
  }

  Widget service(IconData icon, String title) {
    return InkWell(
      onTap: () => showInfo(context, title, '$title will be added here.'),
      borderRadius: BorderRadius.circular(15),
      child: Container(
        decoration: BoxDecoration(
          color: panel,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: purple.withValues(alpha: 0.25)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: pink, size: 30),
            const SizedBox(height: 9),
            Text(title, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget balance(IconData icon, String title, String amount) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: panel,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: purple.withValues(alpha: 0.35)),
        ),
        child: Row(children: [
          Icon(icon, color: pink, size: 27),
          const SizedBox(width: 9),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 4),
              Text(amount, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          )),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Me'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => showInfo(context, 'Setting', 'Account settings will be added here.'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF49306D), panel],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: purple.withValues(alpha: 0.4)),
            ),
            child: Column(children: [
              Row(children: [
                GestureDetector(
                  onTap: choosePhoto,
                  child: Stack(children: [
                    CircleAvatar(
                      radius: 39,
                      backgroundColor: purple,
                      backgroundImage: photoPath == null ? null : FileImage(File(photoPath!)),
                      child: photoPath == null
                          ? const Icon(Icons.person, size: 43, color: Colors.white)
                          : null,
                    ),
                    const Positioned(
                      right: 0, bottom: 0,
                      child: CircleAvatar(
                        radius: 13, backgroundColor: pink,
                        child: Icon(Icons.camera_alt, size: 14, color: Colors.white),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(width: 13),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(username, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Row(children: [
                      Expanded(child: Text(userId, maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70, fontSize: 12))),
                      IconButton(
                        onPressed: copyId,
                        icon: const Icon(Icons.copy, size: 17),
                        visualDensity: VisualDensity.compact,
                      ),
                    ]),
                    const Row(children: [
                      Icon(Icons.flag_circle, color: pink, size: 17),
                      SizedBox(width: 5),
                      Text('Pakistan', style: TextStyle(fontSize: 12)),
                    ]),
                  ],
                )),
              ]),
              const SizedBox(height: 18),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ProfileStat(label: 'Following', value: '0'),
                  ProfileStat(label: 'Followers', value: '0'),
                  ProfileStat(label: 'Visitors', value: '0'),
                ],
              ),
            ]),
          ),
          const SizedBox(height: 15),
          Row(children: [
            balance(Icons.account_balance_wallet, 'Wallet', '0 Coins'),
            const SizedBox(width: 10),
            balance(Icons.diamond, 'Diamonds', '0'),
          ]),
          const SizedBox(height: 23),
          const Text('My Services',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.95,
            children: [
              service(Icons.assignment_turned_in, 'Task'),
              service(Icons.military_tech, 'Level'),
              service(Icons.workspace_premium, 'VIP'),
              service(Icons.groups, 'Fans Club'),
              service(Icons.mic, 'Host Center'),
              service(Icons.backpack, 'Backpack'),
              service(Icons.checkroom, 'Dress Store'),
              service(Icons.event, 'Event Center'),
              service(Icons.favorite, 'Guardian'),
              service(Icons.support_agent, 'Help & Feedback'),
              service(Icons.headset_mic, 'Customer Service'),
              service(Icons.settings, 'Setting'),
            ],
          ),
        ],
      ),
    );
  }
}

'''

p.write_text(s[:start] + new + s[end:])
print("OK: Me screen design saved")
