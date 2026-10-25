import 'new_design/lovely_profile.dart';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const LovelyChatApp());
}

const Color bg = Color(0xFF0C061F);
const Color panel = Color(0xFF1B113A);
const Color purple = Color(0xFF9B6DFF);
const Color pink = Color(0xFFFF65BD);

class LovelyChatApp extends StatelessWidget {
  const LovelyChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lovely Chat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: purple,
          brightness: Brightness.dark,
        ).copyWith(
          surface: panel,
          primary: purple,
          secondary: pink,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: bg,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        useMaterial3: true,
      ),
      home: const LovelyAuthGate(),
    );
  }
}


// ---------------- LOGIN / REGISTER ----------------

const lovelyApi = 'https://lovely.fastapicloud.dev';
const lovelyStorage = FlutterSecureStorage();

class LovelyAuthGate extends StatefulWidget {
  const LovelyAuthGate({super.key});

  @override
  State<LovelyAuthGate> createState() => _LovelyAuthGateState();
}

class _LovelyAuthGateState extends State<LovelyAuthGate> {
  bool loading = true;
  bool loggedIn = false;

  @override
  void initState() {
    super.initState();
    checkLogin();
  }

  Future<void> checkLogin() async {
    final token = await lovelyStorage.read(key: 'lovely_token');

    if (token != null) {
      try {
        final response = await http.get(
          Uri.parse('$lovelyApi/me'),
          headers: {'Authorization': 'Bearer $token'},
        ).timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          loggedIn = true;
        } else {
          await lovelyStorage.delete(key: 'lovely_token');
        }
      } catch (_) {
        loggedIn = false;
      }
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return loggedIn
        ? const MainScreen()
        : const LovelyLoginPage();
  }
}

class LovelyLoginPage extends StatefulWidget {
  const LovelyLoginPage({super.key});

  @override
  State<LovelyLoginPage> createState() => _LovelyLoginPageState();
}

class _LovelyLoginPageState extends State<LovelyLoginPage> {
  final username = TextEditingController();
  final password = TextEditingController();

  bool register = false;
  bool busy = false;
  String message = '';

  Future<String> deviceId() async {
    var id = await lovelyStorage.read(key: 'lovely_device_id');

    if (id == null) {
      final random = Random.secure();
      id = List.generate(
        32,
        (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
      ).join();

      await lovelyStorage.write(key: 'lovely_device_id', value: id);
    }

    return id;
  }

  Future<void> submit() async {
    if (busy) return;

    setState(() {
      busy = true;
      message = '';
    });

    try {
      final id = await deviceId();

      final response = await http.post(
        Uri.parse('$lovelyApi/${register ? "register" : "login"}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username.text.trim(),
          'password': password.text,
          'device_id': id,
        }),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && register) {
        setState(() {
          register = false;
          message = 'Registration sent. Wait for Owner approval.';
        });
      } else if (response.statusCode == 200 &&
          !register &&
          data['token'] != null) {
        await lovelyStorage.write(
          key: 'lovely_token',
          value: data['token'].toString(),
        );

        await lovelyStorage.write(
          key: 'lovely_username',
          value: username.text.trim(),
        );

        if (!mounted) return;

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const MainScreen(),
          ),
        );
      } else {
        setState(() {
          message = data['detail']?.toString() ??
              data['message']?.toString() ??
              'Request failed';
        });
      }
    } catch (e) {
      setState(() {
        message = 'Server connection failed: $e';
      });
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  Future<void> googleLogin() async {
    if (busy) return;

    setState(() {
      busy = true;
      message = '';
    });

    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final idToken = await userCredential.user?.getIdToken();

      if (idToken == null) {
        throw Exception('Google identity token was not returned.');
      }

      final id = await deviceId();
      final response = await http.post(
        Uri.parse('$lovelyApi/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id_token': idToken,
          'device_id': id,
        }),
      ).timeout(const Duration(seconds: 20));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['token'] != null) {
        await lovelyStorage.write(
          key: 'lovely_token',
          value: data['token'].toString(),
        );
        await lovelyStorage.write(
          key: 'lovely_username',
          value: (data['username'] ?? googleUser.email).toString(),
        );

        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      } else {
        setState(() {
          message = data['detail']?.toString() ??
              data['message']?.toString() ??
              'Google login failed.';
        });
      }
    } catch (e) {
      setState(() {
        message = 'Google login failed: $e';
      });
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    username.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lovely Chat'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.favorite, size: 65, color: Colors.pink),
              const SizedBox(height: 20),
              Text(
                register ? 'Create Account' : 'Welcome Back',
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: username,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: password,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: busy ? null : submit,
                child: Text(
                  busy
                      ? 'Please wait...'
                      : register ? 'Register' : 'Login',
                ),
              ),
              if (!register) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: busy ? null : googleLogin,
                  icon: const Icon(Icons.g_mobiledata, size: 30),
                  label: const Text('Continue with Google'),
                ),
              ],
              TextButton(
                onPressed: busy
                    ? null
                    : () => setState(() {
                          register = !register;
                          message = '';
                        }),
                child: Text(
                  register
                      ? 'Already registered? Login'
                      : 'Create new account',
                ),
              ),
              if (message.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int index = 1;

  final List<Widget> pages = const [
    VideoRoomsPage(),
    VoiceRoomsPage(),
    MomentPage(),
    ChatPage(),
    LovelyNewProfile(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: index,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: panel,
        indicatorColor: purple.withValues(alpha: 0.25),
        selectedIndex: index,
        onDestinationSelected: (value) {
          setState(() => index = value);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.live_tv_outlined),
            selectedIcon: Icon(Icons.live_tv),
            label: 'Video Rooms',
          ),
          NavigationDestination(
            icon: Icon(Icons.graphic_eq),
            label: 'Voice Rooms',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_library_outlined),
            label: 'Moment',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Me',
          ),
        ],
      ),
    );
  }
}

// ---------------- LOVELY CHAT VIDEO ROOMS ----------------

class VideoRoomsPage extends StatefulWidget {
  const VideoRoomsPage({super.key});

  @override
  State<VideoRoomsPage> createState() => _VideoRoomsPageState();
}

class _VideoRoomsPageState extends State<VideoRoomsPage> {
  int _tab = 1;
  final Set<int> _liked = {};
  final Set<int> _followed = {};
  final Set<int> _saved = {};
  final Map<int, List<String>> _comments = {};
  final PageController _pageController = PageController();

  final List<Map<String, String>> _clips = const [
    {
      'name': 'Lovely Star',
      'caption': 'Welcome to Lovely Chat 💜',
      'song': '♪ Lovely vibes',
      'avatar': '🌟',
    },
    {
      'name': 'Xena Queen',
      'caption': 'Make every moment beautiful ✨',
      'song': '♪ Trending sound',
      'avatar': '👑',
    },
    {
      'name': 'Lovely Friends',
      'caption': 'Meet new friends around the world 🌍',
      'song': '♪ Original audio',
      'avatar': '💜',
    },
  ];

  void _message(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _action({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 19),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 31),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Future<void> _openComments(int index) async {
    final input = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheet) => StatefulBuilder(
        builder: (sheet, refresh) {
          final list = _comments.putIfAbsent(index, () => <String>[]);

          void send() {
            final value = input.text.trim();
            if (value.isEmpty) return;

            setState(() => list.add(value));
            input.clear();
            refresh(() {});
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 18,
              bottom: MediaQuery.of(sheet).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Comments',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (list.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('Abhi koi comment nahi.'),
                  )
                else
                  SizedBox(
                    height: 220,
                    child: ListView(
                      children: list.map((value) => ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(value),
                      )).toList(),
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: input,
                        onSubmitted: (_) => send(),
                        decoration: const InputDecoration(
                          hintText: 'Comment likhein...',
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: send,
                      icon: const Icon(Icons.send),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    input.dispose();
  }

  Future<void> _openSearch() async {
    final input = TextEditingController();
    String query = '';
    await showDialog<void>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (dialog, refresh) {
          final results = _clips.asMap().entries.where((e) =>
            '${e.value['name']} ${e.value['caption']}'.toLowerCase().contains(query.toLowerCase())).toList();
          return AlertDialog(
            title: const Text('Search Lovely'),
            content: SizedBox(width: double.maxFinite, child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: input, autofocus: true,
                  onChanged: (v) => refresh(() => query = v),
                  decoration: const InputDecoration(hintText: 'Creator ya video search')),
                Flexible(child: ListView(shrinkWrap: true, children: results.map((e) =>
                  ListTile(title: Text(e.value['name'] ?? ''),
                    subtitle: Text(e.value['caption'] ?? ''),
                    onTap: () {
                      Navigator.pop(dialog);
                      if (_pageController.hasClients) _pageController.jumpToPage(e.key);
                    })).toList())),
              ],
            )),
          );
        },
      ),
    );
    input.dispose();
  }

  Future<void> _openGifts() async {
    final token = await lovelyStorage.read(key: 'lovely_token');
    if (!mounted) return;
    if (token == null || token.isEmpty) {
      _message('Login required', 'Gift store dekhne ke liye login karein.');
      return;
    }
    try {
      final response = await http.get(
        Uri.parse('$lovelyApi/store/items'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (!mounted) return;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        _message('Gift store', 'Store load nahi hua: ${response.statusCode}');
        return;
      }
      final data = jsonDecode(response.body);
      final items = data is List ? data :
        (data is Map ? (data['items'] as List? ?? []) : []);
      if (items.isEmpty) {
        _message('Gift store', 'Filhal koi gift item nahi mila.');
        return;
      }
      showModalBottomSheet<void>(
        context: context,
        builder: (sheet) => ListView(shrinkWrap: true, children: [
          const ListTile(title: Text('Lovely Gift Store')),
          ...items.map<Widget>((raw) {
            final item = raw is Map ? raw : {};
            return ListTile(
              leading: const Icon(Icons.card_giftcard, color: Colors.pink),
              title: Text('${item['name'] ?? item['title'] ?? 'Gift'}'),
              subtitle: Text('${item['price'] ?? item['coins'] ?? ''} coins'),
            );
          }),
        ]),
      );
    } catch (_) {
      if (mounted) _message('Gift store', 'Store load nahi ho saka. Internet check karein.');
    }
  }

  Widget _clip(int index) {
    final item = _clips[index % _clips.length];
    final liked = _liked.contains(index);
    final followed = _followed.contains(index);

    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF241047),
                Color(0xFF6B238E),
                Color(0xFF171126),
                Color(0xFF08070D),
              ],
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.play_circle_outline_rounded,
                  color: Colors.white70,
                  size: 76,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Lovely Video',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 7),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Video source will appear here',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => _message(
                      'LIVE',
                      'Live video streaming ko real streaming service aur backend se connect karna hoga.',
                    ),
                    icon: const Icon(Icons.live_tv, color: Colors.white),
                  ),
                  const Spacer(),
                  _topTab('Following', 0),
                  const SizedBox(width: 16),
                  _topTab('For You', 1),
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: _openSearch,
                    icon: const Icon(Icons.search, color: Colors.white, size: 28),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          right: 12,
          bottom: 112,
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF70C8), Color(0xFF7C4DFF)],
                  ),
                ),
                child: Center(
                  child: Text(
                    item['avatar']!,
                    style: const TextStyle(fontSize: 23),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _action(
                icon: liked ? Icons.favorite : Icons.favorite_border,
                label: liked ? 'Liked' : 'Like',
                color: liked ? Colors.pinkAccent : Colors.white,
                onTap: () => setState(() {
                  if (liked) {
                    _liked.remove(index);
                  } else {
                    _liked.add(index);
                  }
                }),
              ),
              _action(
                icon: Icons.mode_comment_outlined,
                label: 'Comment',
                onTap: () => _openComments(index),
              ),
              _action(
                icon: _saved.contains(index) ? Icons.bookmark : Icons.bookmark_border,
                label: _saved.contains(index) ? 'Saved' : 'Save',
                onTap: () => setState(() {
                  if (_saved.contains(index)) { _saved.remove(index); }
                  else { _saved.add(index); }
                }),
              ),
              _action(
                icon: Icons.card_giftcard,
                label: 'Gift',
                color: const Color(0xFFFF80C8),
                onTap: _openGifts,
              ),
              _action(
                icon: Icons.share_outlined,
                label: 'Share',
                onTap: () async {
                  await Clipboard.setData(ClipboardData(
                    text: 'Check out @${item['name']} on Lovely Chat! ${item['caption']}',
                  ));
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Share text copied!')),
                  );
                },
              ),
            ],
          ),
        ),
        Positioned(
          left: 16,
          right: 88,
          bottom: 28,
          child: SafeArea(
            top: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '@${item['name']}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: () => setState(() {
                        if (followed) {
                          _followed.remove(index);
                        } else {
                          _followed.add(index);
                        }
                      }),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white70),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        minimumSize: const Size(0, 32),
                      ),
                      child: Text(followed ? 'Following' : 'Follow'),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  item['caption']!,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.music_note, color: Colors.white, size: 17),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        item['song']!,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _topTab(String title, int value) {
    final selected = _tab == value;
    return GestureDetector(
      onTap: () => setState(() => _tab = value),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              color: selected ? Colors.white : Colors.white70,
              fontSize: 15,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 5),
          if (selected)
            Container(
              width: 24,
              height: 3,
              decoration: BoxDecoration(
                color: const Color(0xFFFF70C8),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: 30,
        itemBuilder: (context, index) => _clip(index),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

// ---------------- VOICE ROOMS ----------------

class VoiceRoomsPage extends StatefulWidget {
  const VoiceRoomsPage({super.key});

  @override
  State<VoiceRoomsPage> createState() => _VoiceRoomsPageState();
}

class _VoiceRoomsPageState extends State<VoiceRoomsPage> {
  final List<Map<String, dynamic>> _rooms = [
    {
      'name': 'Lovely Friends 💗',
      'host': 'Lovely Host',
      'seats': 10,
      'members': 1,
      'live': true,
    },
    {
      'name': 'Music & Chat 🎵',
      'host': 'Room Owner',
      'seats': 10,
      'members': 0,
      'live': true,
    },
  ];

  void _createRoom() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create Voice Room'),
        content: TextField(
          controller: controller,
          maxLength: 40,
          decoration: const InputDecoration(
            labelText: 'Room name',
            hintText: 'Enter a room name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isEmpty) return;

              setState(() {
                _rooms.insert(0, {
                  'name': name,
                  'host': 'You',
                  'seats': 10,
                  'members': 1,
                  'live': true,
                });
              });

              Navigator.pop(dialogContext);
              _openRoom(_rooms.first);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _openRoom(Map<String, dynamic> room) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VoiceRoomDetailPage(
          roomName: room['name'] as String,
          hostName: room['host'] as String,
          seatCount: room['seats'] as int,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Rooms 🎙️'),
        actions: [
          IconButton(
            onPressed: _createRoom,
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Create room',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createRoom,
        icon: const Icon(Icons.add),
        label: const Text('Create Room'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.purple.shade800,
                  Colors.pink.shade700,
                ],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.graphic_eq, size: 36, color: Colors.white),
                SizedBox(height: 10),
                Text(
                  'Talk. Listen. Make Friends.',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Join a room or create your own.',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Popular Rooms',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          for (final room in _rooms)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.purple.shade100,
                  child: const Icon(
                    Icons.record_voice_over,
                    color: Colors.deepPurple,
                  ),
                ),
                title: Text(
                  room['name'] as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${room['host']} • '
                    '${room['members']} members • '
                    '${room['seats']} seats',
                  ),
                ),
                trailing: FilledButton(
                  onPressed: () => _openRoom(room),
                  child: const Text('Join'),
                ),
              ),
            ),
          const SizedBox(height: 10),
          const Text(
            'نوٹ: ابھی روم کا UI اور مقامی کنٹرول فعال ہیں۔ '
            'دوسرے فونز سے حقیقی آواز اور مشترکہ رومز کے لیے '
            'آن لائن signaling server اور WebRTC audio درکار ہیں۔',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }
}



class VoiceRoomDetailPage extends StatefulWidget {
  final String roomName;
  final String hostName;
  final int seatCount;

  const VoiceRoomDetailPage({
    super.key,
    required this.roomName,
    required this.hostName,
    required this.seatCount,
  });

  @override
  State<VoiceRoomDetailPage> createState() => _VoiceRoomDetailPageState();
}

class _VoiceRoomDetailPageState extends State<VoiceRoomDetailPage> {
  static const gold = Color(0xFFFFC451);
  static const dark = Color(0xFF160900);
  static const panel = Color(0xFF2B1708);

  MediaStream? _localStream;
  bool _muted = true;
  bool _speaker = true;
  bool _starting = false;
  bool _minimized = false;
  final _message = TextEditingController();
  final List<String> _messages = ['Welcome to Lovely Party Room! 🎉'];

  Future<void> _toggleMic() async {
    if (_starting) return;
    if (_localStream != null) {
      setState(() {
        _muted = !_muted;
        for (final t in _localStream!.getAudioTracks()) {
          t.enabled = !_muted;
        }
      });
      return;
    }
    setState(() => _starting = true);
    try {
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': false,
      });
      for (final t in _localStream!.getAudioTracks()) {
        t.enabled = true;
      }
      if (mounted) setState(() => _muted = false);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission nahi mili')),
        );
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _leaveRoom() async {
    await _localStream?.dispose();
    _localStream = null;
    if (mounted) Navigator.pop(context);
  }

  void _sendMessage() {
    final text = _message.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add('You: $text');
      _message.clear();
    });
  }

  void _panel(String title, IconData icon, List<String> options) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: panel,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(icon, color: gold, size: 28),
                const SizedBox(width: 12),
                Expanded(child: Text(title, style: const TextStyle(
                  color: Colors.white, fontSize: 21, fontWeight: FontWeight.bold,
                ))),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ]),
              const Divider(color: gold),
              ...options.map((option) => ListTile(
                leading: const Icon(Icons.circle, color: gold, size: 10),
                title: Text(option, style: const TextStyle(color: Colors.white)),
                trailing: const Icon(Icons.chevron_right, color: gold),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$option — baad mein configure hoga')),
                  );
                },
              )),
            ],
          ),
        ),
      ),
    );
  }

  void _settings() => _panel('Room Settings', Icons.settings, const [
    'Music & Playlist',
    'Room Information',
    'Change Room Name',
    'Room Announcement',
    'Room Cover',
    'Room Mode',
    'Room Theme & Decoration',
    'Seat Settings',
    'Member Management',
    'Invite Friends',
  ]);

  Widget _action(IconData icon, String label, VoidCallback tap,
      {bool active = false, Color? iconColor}) {
    return SizedBox(
      width: 66,
      child: InkWell(
        onTap: tap,
        borderRadius: BorderRadius.circular(30),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? const Color(0xFF064B38) : panel,
              border: Border.all(
                color: active ? const Color(0xFF00E6A1) : gold.withOpacity(.7),
              ),
            ),
            child: Icon(icon, color: iconColor ??
                (active ? const Color(0xFF00E6A1) : gold)),
          ),
          const SizedBox(height: 4),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 9)),
        ]),
      ),
    );
  }

  Widget _seat(int number, {String? name, bool host = false, bool special = false}) {
    return InkWell(
      onTap: () => _panel(
        host ? 'Room Host' : (special ? 'Special Seat' : 'Seat $number'),
        Icons.event_seat,
        const ['Take a seat', 'Request microphone', 'View profile'],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: host ? 74 : 53,
          height: host ? 74 : 53,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF0A3), Color(0xFFFFA21D), Color(0xFF6F3100)],
            ),
            boxShadow: [BoxShadow(color: gold.withOpacity(.2), blurRadius: 8)],
          ),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle, color: Color(0xFF281406),
            ),
            child: Icon(
              special ? Icons.add : Icons.person,
              color: gold, size: host ? 36 : 27,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          constraints: const BoxConstraints(maxWidth: 92),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            host ? '👑 ${name ?? widget.hostName}' :
              (special ? 'Special Seat' : '$number  ${name ?? "Join"}'),
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(color: special ? gold : Colors.white, fontSize: 9),
          ),
        ),
      ]),
    );
  }

  Widget _sideButton(IconData icon, String title, String subtitle,
      VoidCallback tap) {
    return Expanded(
      child: InkWell(
        onTap: tap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
          decoration: BoxDecoration(
            color: panel, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: gold.withOpacity(.35)),
          ),
          child: Row(children: [
            Icon(icon, color: gold, size: 22),
            const SizedBox(width: 5),
            Expanded(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(
                  color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold,
                )),
                Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white60, fontSize: 8)),
              ],
            )),
            const Icon(Icons.chevron_right, color: gold, size: 15),
          ]),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _localStream?.dispose();
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.seatCount.clamp(1, 50);

    return Scaffold(
      backgroundColor: dark,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFF492000), Color(0xFF1B0B02), Color(0xFF080402)],
          ),
        ),
        child: SafeArea(child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 5, 5, 7),
            child: Row(children: [
              Container(
                width: 47, height: 47,
                decoration: BoxDecoration(
                  shape: BoxShape.circle, border: Border.all(color: gold, width: 2),
                ),
                child: const Icon(Icons.person, color: gold, size: 29),
              ),
              const SizedBox(width: 8),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.roomName, maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white,
                      fontWeight: FontWeight.bold, fontSize: 15)),
                  const Text('Room ID: 728394',
                    style: TextStyle(color: Colors.white70, fontSize: 10)),
                ],
              )),
              IconButton(
                onPressed: () => _panel('Share Room', Icons.share,
                    const ['Invite Friends', 'Copy Room ID']),
                icon: const Icon(Icons.share, color: gold),
              ),
              IconButton(
                onPressed: () => setState(() => _minimized = !_minimized),
                icon: Icon(_minimized ? Icons.fullscreen : Icons.fullscreen_exit,
                    color: gold),
              ),
              IconButton(
                onPressed: _leaveRoom,
                icon: const Icon(Icons.close, color: Colors.redAccent),
              ),
            ]),
          ),
          if (!_minimized) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(.4),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: gold.withOpacity(.4)),
              ),
              child: const Row(children: [
                Expanded(child: _PartyStat(Icons.people, '1 / 50', 'Visitors')),
                _PartyDivider(),
                Expanded(child: _PartyStat(Icons.card_giftcard, '0', 'Total Gifts')),
                _PartyDivider(),
                Expanded(child: _PartyStat(Icons.local_fire_department, 'New', 'Popularity')),
              ]),
            ),
            const SizedBox(height: 12),
            SizedBox(height: 112, child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _seat(0, special: true),
                _seat(1, name: widget.hostName, host: true),
                _seat(2, special: true),
              ],
            )),
          ],
          Expanded(child: Container(
            margin: const EdgeInsets.fromLTRB(8, 6, 8, 6),
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(.18),
              border: Border(top: BorderSide(color: gold.withOpacity(.3))),
            ),
            child: GridView.builder(
              itemCount: count,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5, mainAxisSpacing: 7,
                crossAxisSpacing: 3, childAspectRatio: .78,
              ),
              itemBuilder: (context, i) => _seat(
                i + 1,
                name: i < 4 ? ['Zain', 'Nimra', 'Ali', 'Sana'][i] : null,
              ),
            ),
          )),
          SizedBox(height: 150, child: Row(children: [
            Expanded(flex: 7, child: Container(
              margin: const EdgeInsets.fromLTRB(8, 0, 3, 5),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(.45),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: gold.withOpacity(.25)),
              ),
              child: Column(children: [
                Expanded(child: ListView.builder(
                  itemCount: _messages.length,
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(_messages[i], maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: i == 0 ? gold : Colors.white, fontSize: 10)),
                  ),
                )),
                Row(children: [
                  Expanded(child: TextField(
                    controller: _message,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: const TextStyle(color: Colors.white54, fontSize: 11),
                      filled: true, fillColor: const Color(0xFF211207),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  )),
                  IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send, color: gold, size: 20),
                  ),
                ]),
              ]),
            )),
            Expanded(flex: 3, child: Column(children: [
              _sideButton(Icons.sports_esports, 'Games', 'Play games',
                () => _panel('Games', Icons.sports_esports,
                    const ['Games will be added later'])),
              const SizedBox(height: 4),
              _sideButton(Icons.card_giftcard, 'Gifts', 'Send gifts',
                () => _panel('Gifts', Icons.card_giftcard,
                    const ['Gift shop will be added later'])),
              const SizedBox(height: 4),
              _sideButton(Icons.workspace_premium, 'Rewards', 'Room rewards',
                () => _panel('Rewards', Icons.workspace_premium,
                    const ['Rewards panel'])),
            ])),
          ])),
          Container(
            padding: const EdgeInsets.fromLTRB(2, 8, 2, 7),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(.55),
              border: Border(top: BorderSide(color: gold.withOpacity(.25))),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _action(Icons.emoji_emotions, 'Emoji',
                  () => _panel('Emoji', Icons.emoji_emotions, const ['Emoji panel'])),
                _action(Icons.card_giftcard, 'Gifts',
                  () => _panel('Gifts', Icons.card_giftcard, const ['Gift shop coming later'])),
                _action(Icons.sports_esports, 'Games',
                  () => _panel('Games', Icons.sports_esports, const ['Games coming later'])),
                _action(_muted ? Icons.mic_off : Icons.mic,
                  _starting ? 'Starting' : (_muted ? 'Mic OFF' : 'Mic ON'),
                  _toggleMic, active: !_muted),
                _action(_speaker ? Icons.volume_up : Icons.volume_off,
                  _speaker ? 'Speaker ON' : 'Speaker OFF', () async {
                    final next = !_speaker;
                    try { await Helper.setSpeakerphoneOn(next); } catch (_) {}
                    if (mounted) setState(() => _speaker = next);
                  }, active: _speaker),
                _action(Icons.people, 'Invite',
                  () => _panel('Invite Friends', Icons.people,
                      const ['Invite Friends', 'Copy Room ID'])),
                _action(Icons.chat_bubble, 'Chat',
                  () => _panel('Room Chat', Icons.chat_bubble,
                      const ['Use the message box in the room'])),
                _action(Icons.settings, 'Settings', _settings),
                _action(Icons.logout, 'Leave', _leaveRoom,
                    iconColor: Colors.redAccent),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text(_muted ? 'Mic off' : 'Mic on — local microphone only',
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white54, fontSize: 9)),
          ),
        ])),
      ),
    );
  }
}

class _PartyStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _PartyStat(this.icon, this.value, this.label);

  @override
  Widget build(BuildContext context) => Column(children: [
    Icon(icon, color: const Color(0xFFFFC451), size: 20),
    const SizedBox(height: 3),
    Text(value, style: const TextStyle(
      color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
    Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
      style: const TextStyle(color: Colors.white70, fontSize: 9)),
  ]);
}

class _PartyDivider extends StatelessWidget {
  const _PartyDivider();

  @override
  Widget build(BuildContext context) => Container(
    height: 34, width: 1, color: const Color(0x66FFC451));
}

// ---------------- MOMENT ----------------

class MomentPage extends StatelessWidget {
  const MomentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Moment')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text('Latest'),
              Text('Hot'),
              Text('Following'),
            ],
          ),
          const SizedBox(height: 24),
          featureCard(
            Icons.add_a_photo_outlined,
            'Create a Moment',
            'Share a photo or video',
            () => showInfo(
              context,
              'Create Moment',
              'پوسٹ اپ لوڈ کرنے کے لیے '
                  'تصویری storage اور backend شامل کرنا ہوگا۔',
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Your feed will appear here',
              style: TextStyle(color: Colors.white60),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- CHAT ----------------

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final List<WebSocketChannel> _channels = [];
  WebSocketChannel? _channel;
  bool _connecting = false;
  String _status = 'Login required';
  String _username = '';
  String _recipient = '';

  // Set the server address here when the backend is reachable.
  // For testing on the same phone, use 127.0.0.1.
  final String _server = '127.0.0.1:8000';

  Future<void> _connect() async {
    if (_connecting) return;
    setState(() {
      _connecting = true;
      _status = 'Connection needs login token';
    });

    // Authentication integration is intentionally not guessed here.
    // The app must pass its actual saved login token and username.
    setState(() {
      _connecting = false;
      _status = 'Configure saved login token to connect';
    });
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final channel = _channel;
    if (channel == null) {
      setState(() {
        _status = 'Not connected to chat server';
      });
      return;
    }

    if (_recipient.trim().isEmpty) {
      setState(() {
        _status = 'Enter recipient username first';
      });
      return;
    }

    channel.sink.add(
      '{"to":${_jsonString(_recipient.trim())},'
      '"message":${_jsonString(text)}}',
    );

    setState(() {
      _messages.add({'text': text, 'mine': '1'});
      _controller.clear();
    });
  }

  String _jsonString(String value) {
    return jsonEncode(value);
  }

  @override
  void dispose() {
    _controller.dispose();
    for (final channel in _channels) {
      channel.sink.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lovely Chat 💗'),
        actions: [
          IconButton(
            onPressed: _connect,
            icon: const Icon(Icons.wifi),
            tooltip: 'Connect',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(_status),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: TextField(
              onChanged: (value) => _recipient = value,
              decoration: const InputDecoration(
                labelText: 'Recipient username',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return Align(
                  alignment: message['mine'] == '1'
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: message['mine'] == '1'
                          ? Colors.pink.shade100
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(message['text'] ?? ''),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Message...',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  IconButton(
                    onPressed: _send,
                    icon: const Icon(Icons.send),
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

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? account;
  bool accountLoading = true;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    try {
      final token = await lovelyStorage.read(key: 'lovely_token');
      if (token == null) {
        if (mounted) setState(() => accountLoading = false);
        return;
      }
      final response = await http.get(
        Uri.parse('$lovelyApi/me'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        account = jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {
      // Keep the profile usable if the server is temporarily unavailable.
    }
    if (mounted) setState(() => accountLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => showInfo(
              context,
              'Settings',
              'Account settings aglay marhalay mein connect hongi.',
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF39206F),
                  Color(0xFF21123F),
                  Color(0xFF120A29),
                ],
              ),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: const Color(0xFFD6A6FF),
                width: 1.3,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x664F1C99),
                  blurRadius: 26,
                  offset: Offset(0, 10),
                ),
                BoxShadow(
                  color: Color(0x33F4DFFF),
                  blurRadius: 2,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFF65C3),
                      width: 2,
                    ),
                  ),
                  child: const CircleAvatar(
                    radius: 43,
                    backgroundColor: Color(0xFF281747),
                    child: Icon(
                      Icons.person_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 13),
                Text(
                  account?['username']?.toString() ?? 'Lovely User',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'ID: ${account?['user_code']?.toString() ?? 'Pending'}',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ProfileStat(label: 'Following', value: '0'),
                      ProfileStat(label: 'Followers', value: '0'),
                      ProfileStat(label: 'Visitors', value: '0'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 27),
          const Row(
            children: [
              Icon(
                Icons.grid_view_rounded,
                color: Color(0xFFD29AFF),
                size: 23,
              ),
              SizedBox(width: 9),
              Text(
                'My Services',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          featureCard(
            Icons.account_balance_wallet_rounded,
            'Wallet',
            'Coins and Diamonds',
            () async {
  try {
    final token = await lovelyStorage.read(key: 'lovely_token');
    if (token == null) {
      if (context.mounted) showInfo(context, 'Wallet', 'Please login again.');
      return;
    }

    final response = await http.get(
      Uri.parse('$lovelyApi/wallet/me'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 15));

    if (!context.mounted) return;

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      showInfo(
        context,
        'My Wallet',
        'Coins: ${data['coins'] ?? 0}\nDiamonds: ${data['diamonds'] ?? 0}',
      );
    } else {
      showInfo(context, 'Wallet Error', 'Server error: ${response.statusCode}');
    }
  } catch (e) {
    if (context.mounted) showInfo(context, 'Wallet Error', e.toString());
  }
},
          ),
          featureCard(
            Icons.card_giftcard_rounded,
            'Gift Bag',
            'Gifts and inventory',
            () async {
  try {
    final token = await lovelyStorage.read(key: 'lovely_token');
    if (token == null) {
      if (context.mounted) showInfo(context, 'Gift Bag', 'Please login again.');
      return;
    }

    final response = await http.get(
      Uri.parse('$lovelyApi/inventory/me'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 15));

    if (!context.mounted) return;

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      showInfo(context, 'My Gift Bag', const JsonEncoder.withIndent('  ').convert(data));
    } else {
      showInfo(context, 'Gift Bag Error', 'Server error: ${response.statusCode}');
    }
  } catch (e) {
    if (context.mounted) showInfo(context, 'Gift Bag Error', e.toString());
  }
},
          ),
          featureCard(
            Icons.workspace_premium_rounded,
            'VIP & Frames',
            'VIP levels and profile frames',
            () async {
  try {
    final token = await lovelyStorage.read(key: 'lovely_token');

    if (token == null) {
      if (context.mounted) {
        showInfo(context, 'VIP & Frames', 'Please login again.');
      }
      return;
    }

    final headers = {'Authorization': 'Bearer $token'};

    final results = await Future.wait([
      http.get(
        Uri.parse('$lovelyApi/vip/me'),
        headers: headers,
      ),
      http.get(
        Uri.parse('$lovelyApi/store/items'),
        headers: headers,
      ),
    ]).timeout(const Duration(seconds: 15));

    if (!context.mounted) return;

    if (results[0].statusCode == 200 &&
        results[1].statusCode == 200) {

      final vip = jsonDecode(results[0].body);
      final store = jsonDecode(results[1].body);

      final items = store['items'] as List? ?? [];

      final itemNames = items.map((item) =>
        '${item['name']} - ${item['price']}'
      ).join('\n');

      showInfo(
        context,
        'VIP & Frames',
        'VIP Level: ${vip['vip_level']}\n'
        'Expiry: ${vip['expires_at'] ?? 'Not active'}\n\n'
        'Available Items:\n$itemNames',
      );
    } else {
      showInfo(
        context,
        'VIP Error',
        'Server response: ${results[0].statusCode}, ${results[1].statusCode}',
      );
    }
  } catch (e) {
    if (context.mounted) {
      showInfo(context, 'VIP Error', e.toString());
    }
  }
},
          ),
          featureCard(
            Icons.people_alt_rounded,
            'Family & CP',
            'Families, couples and friends',
            () => showInfo(
              context,
              'Family & CP',
              'Yeh feature aglay marhalay mein shamil hoga.',
            ),
          ),
          if (account?['role'] == 'bd')
            featureCard(
              Icons.business_center_rounded,
              'BD Center',
              'BD account tools and targets',
              () => showInfo(
                context,
                'BD Center',
                'BD tools ko secure backend endpoints se connect karna baqi hai.',
              ),
            ),
          if (account?['role'] == 'super_admin')
            featureCard(
              Icons.admin_panel_settings_rounded,
              'Super Admin Panel',
              'Authorized owner controls',
              () => showInfo(
                context,
                'Super Admin Panel',
                'Admin controls ko secure backend endpoints se connect karna baqi hai.',
              ),
            ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Lovely Chat • Connect, Share & Enjoy',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.48),
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileStat extends StatelessWidget {
  final String label;
  final String value;

  const ProfileStat({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.white60)),
      ],
    );
  }
}

// ---------------- SHARED WIDGETS ----------------

Widget featureCard(
  IconData icon,
  String title,
  String subtitle,
  VoidCallback onTap,
) {
  return Container(
    margin: const EdgeInsets.only(bottom: 13),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF402078),
          Color(0xFF21113F),
          Color(0xFF160D2B),
        ],
      ),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFB78AFF), width: 1.1),
      boxShadow: const [
        BoxShadow(
          color: Color(0x663F16A5),
          blurRadius: 12,
          offset: Offset(0, 6),
        ),
        BoxShadow(
          color: Color(0x55FFFFFF),
          blurRadius: 1,
          offset: Offset(0, 1),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFE0B7FF), Color(0xFF8B45E8), Color(0xFF5524A5)],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: const Color(0xFFFFE4FF), width: 1),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x884F1C99),
                      blurRadius: 7,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        shadows: [Shadow(color: Color(0xAA000000), blurRadius: 4, offset: Offset(0, 2))],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Color(0xFFD8C6F5), fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFE1C7FF), size: 17),
            ],
          ),
        ),
      ),
    ),
  );
}

void showInfo(BuildContext context, String title, String message) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: panel,
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
