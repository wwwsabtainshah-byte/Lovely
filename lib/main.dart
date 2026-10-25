import 'new_design/lovely_profile.dart';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
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
                    onPressed: () => _message(
                      'Search',
                      'Video search ko server feed se connect karna baqi hai.',
                    ),
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
                onTap: () => _message(
                  'Comments',
                  'Comments ko backend API se connect karna baqi hai.',
                ),
              ),
              _action(
                icon: Icons.bookmark_border,
                label: 'Save',
                onTap: () => _message('Save video', 'Save feature abhi demo hai.'),
              ),
              _action(
                icon: Icons.card_giftcard,
                label: 'Gift',
                color: const Color(0xFFFF80C8),
                onTap: () => _message(
                  'Send Gift',
                  'Real gifts aur coins ke liye existing wallet API connect karni hogi.',
                ),
              ),
              _action(
                icon: Icons.share_outlined,
                label: 'Share',
                onTap: () => _message('Share', 'Video sharing integration baqi hai.'),
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
        scrollDirection: Axis.vertical,
        itemCount: 30,
        itemBuilder: (context, index) => _clip(index),
      ),
    );
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
  MediaStream? _localStream;
  bool _muted = true;
  bool _speaker = true;
  bool _starting = false;
  String _status = 'Mic off — audio not connected';

  Future<void> _toggleMic() async {
    if (_starting) return;
    if (_localStream != null) {
      final tracks = _localStream!.getAudioTracks();
      if (tracks.isNotEmpty) {
        _muted = !_muted;
        for (final track in tracks) {
          track.enabled = !_muted;
        }
        if (mounted) {
          setState(() => _status = _muted
              ? 'Microphone muted (local only)'
              : 'Microphone on (local only; room audio not connected)');
        }
      }
      return;
    }

    setState(() {
      _starting = true;
      _status = 'Requesting microphone permission...';
    });

    try {
      final stream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': false,
      });
      for (final track in stream.getAudioTracks()) {
        track.enabled = true;
      }
      _localStream = stream;
      _muted = false;
      if (mounted) {
        setState(() => _status =
            'Microphone active on this phone; remote audio is not connected yet');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _status = 'Microphone error: $e');
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

  @override
  void dispose() {
    _localStream?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.roomName,
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          const CircleAvatar(radius: 42, child: Icon(Icons.person, size: 48)),
          const SizedBox(height: 8),
          Text(widget.hostName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Text('Room Host'),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(_status, textAlign: TextAlign.center),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.seatCount,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 18,
                crossAxisSpacing: 12,
                childAspectRatio: 0.8,
              ),
              itemBuilder: (context, index) => Column(
                children: [
                  CircleAvatar(
                    radius: 29,
                    backgroundColor:
                        index == 0 ? Colors.pink.shade100 : Colors.grey.shade800,
                    child: Icon(index == 0 ? Icons.person : Icons.add, size: 28),
                  ),
                  const SizedBox(height: 5),
                  Text(index == 0 ? 'Host' : 'Seat ${index + 1}',
                      style: const TextStyle(fontSize: 11),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(mainAxisSize: MainAxisSize.min, children: [
                  IconButton.filled(
                    onPressed: _starting ? null : _toggleMic,
                    icon: Icon(_muted ? Icons.mic_off : Icons.mic),
                  ),
                  Text(_starting ? 'Starting...' : (_muted ? 'Mic Off' : 'Mic On')),
                ]),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  IconButton.filled(
                    onPressed: () async {
                      _speaker = !_speaker;
                      await Helper.setSpeakerphoneOn(_speaker);
                      if (mounted) setState(() {});
                    },
                    icon: Icon(_speaker ? Icons.volume_up : Icons.volume_off),
                  ),
                  Text(_speaker ? 'Speaker' : 'Earpiece'),
                ]),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: _leaveRoom,
                    icon: const Icon(Icons.call_end),
                  ),
                  const Text('Leave'),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
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
