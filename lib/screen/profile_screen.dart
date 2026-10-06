import 'package:flutter/foundation.dart'; // สำหรับตรวจสอบ Platform และรองรับ Uint8List
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final Color barcaBlue = const Color(0xFF004D98);
  final Color barcaRed = const Color(0xFFA50044);
  final Color barcaGold = const Color(0xFFEDBB00);

  // ✅ ฟังก์ชันอัปโหลดรูปที่รันได้ทั้งบน Web (Chrome) และ Mobile
  Future<void> _pickAndUploadImage(String uid) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    
    if (pickedFile != null) {
      try {
        final ref = FirebaseStorage.instance.ref().child('avatars').child('$uid.jpg');

        // อ่านข้อมูลเป็น Bytes แทนการใช้คลาส File เพื่อให้รันบนเว็บได้
        final Uint8List imageData = await pickedFile.readAsBytes();
        
        // อัปโหลดข้อมูลแบบ Data (Bytes)
        await ref.putData(
          imageData,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        
        final url = await ref.getDownloadURL();
        await FirebaseFirestore.instance.collection('users').doc(uid).update({'avatarUrl': url});
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('อัปเดตรูปโปรไฟล์เรียบร้อย!'), backgroundColor: Colors.green)
          );
        }
      } catch (e) {
        debugPrint("Upload Error: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('เกิดข้อผิดพลาดในการอัปโหลด: $e'), backgroundColor: Colors.red)
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData) return _buildGatekeeper();
        return _buildModernProfile(snapshot.data!.uid);
      },
    );
  }

  Widget _buildModernProfile(String uid) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('โปรไฟล์ผู้ใช้งาน', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final String avatar = data['avatarUrl'] ?? '';
          final Timestamp? createdAt = data['createdAt'] as Timestamp?;
          final String memberDate = createdAt != null ? DateFormat('MMM yyyy').format(createdAt.toDate()) : 'N/A';
          final String role = data['role'] ?? 'user';

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                // 1. User Info Card + Stats
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
                  ),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () => _pickAndUploadImage(uid),
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 55,
                              backgroundColor: barcaBlue.withOpacity(0.1),
                              backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
                              child: avatar.isEmpty ? Icon(Icons.person, size: 55, color: barcaBlue) : null,
                            ),
                            CircleAvatar(radius: 18, backgroundColor: barcaRed, child: const Icon(Icons.camera_alt, size: 16, color: Colors.white)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(data['displayName'] ?? 'User', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      Text(data['email'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                      const SizedBox(height: 20),
                      
                      // Row สถิติ (User Stats)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatColumn('เริ่มใช้งาน', memberDate),
                          Container(width: 1, height: 30, color: Colors.grey.shade200),
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('bookings')
                                .where('userId', isEqualTo: uid)
                                .where('status', isEqualTo: 'confirmed')
                                .snapshots(),
                            builder: (context, bookSnap) {
                              final count = bookSnap.data?.docs.length ?? 0;
                              return _buildStatColumn('จองสนามแล้ว', '$count ครั้ง');
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 25),
                
                // 2. เมนูการตั้งค่า
                _buildMenuSection([
                  _menuItem(Icons.verified_user_outlined, 'Account Type', trailingText: role.toUpperCase()),
                  _menuItem(Icons.phone_android_outlined, 'Phone', trailingText: data['phone'] != "" ? data['phone'] : 'Not set'),
                  _menuItem(Icons.language_outlined, 'Language', trailingText: 'ไทย'),
                ]),
                
                const SizedBox(height: 15),
                
                _buildMenuSection([
                  _menuItem(Icons.help_outline_rounded, 'Help & Support'),
                  _menuItem(Icons.info_outline_rounded, 'About KickOff App'),
                ]),

                const SizedBox(height: 25),
                
                // ปุ่ม Logout
                ListTile(
                  onTap: () => FirebaseAuth.instance.signOut(),
                  leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                  title: const Text('Sign Out', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildMenuSection(List<Widget> items) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(children: items),
    );
  }

  Widget _menuItem(IconData icon, String title, {String? trailingText}) {
    return ListTile(
      leading: Icon(icon, color: barcaBlue, size: 22),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null) 
            Text(trailingText, style: TextStyle(color: trailingText == 'ADMIN' ? barcaGold : Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(width: 5),
          const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
        ],
      ),
    );
  }

  Widget _buildGatekeeper() {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(child: Image.network('https://img.20mn.fr/h8-cV-RDQUqLkFH49b400Ck/1444x920_camp-nou-accueillera-aucun-match-2024-2025', fit: BoxFit.cover)),
          Container(color: Colors.black.withOpacity(0.5)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(flex: 3),
                const Text('KickOff Profile', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                const Text('Sign in to manage your football bookings.', style: TextStyle(color: Colors.white70, fontSize: 16)),
                const Spacer(flex: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    children: [
                      Expanded(child: TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const LoginScreen())), child: const Text('Sign in', style: TextStyle(color: Colors.white)))),
                      Expanded(child: ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const SignUpScreen())), child: const Text('Sign up'))),
                    ],
                  ),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ],
      ),
    );
  }
}