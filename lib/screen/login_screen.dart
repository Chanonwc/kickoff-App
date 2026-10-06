import 'package:Kikoff/screen/Home_screen_new.dart';
import 'package:Kikoff/screen/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/constant/my_constant.dart';
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
// 1. ฟังก์ชัน signIn (ปรับการส่งค่า) + Firebase Firestore
Future<void> signIn() async {
  try {
    final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );
    
    final uid = credential.user!.uid;
    
    // ดึง/อัปเดต user data จาก Firestore
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final userDoc = await userRef.get();
    
    if (!userDoc.exists) {
      // ถ้ยังไม่มี user doc ให้สร้างใหม่
      await userRef.set({
        'displayName': credential.user?.displayName ?? 'User',
        'email': credential.user?.email,
        'phone': '',
        'role': 'user',
        'avatarUrl': '',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    
    // สำเร็จ: ไอคอนเขียว
    _showCenteredSnackBar(
      'Sign In Successful', 
      Icons.check_circle, 
      Colors.greenAccent
    );

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) =>  const HomeScreen()),
    );
  } on FirebaseAuthException catch (e) {
    // ล้มเหลว: ไอคอนแดง + ข้อความสากล
    _showCenteredSnackBar(
      'Invalid email or password', 
      Icons.cancel, 
      Colors.redAccent
    );
  } catch (e) {
    _showCenteredSnackBar(
      'Something went wrong', 
      Icons.warning_amber_rounded, 
      Colors.orangeAccent
    );
  }
}

// 2. ฟังก์ชันแสดง SnackBar (ดีไซน์ใหม่)
void _showCenteredSnackBar(String message, IconData icon, Color accentColor) {
  final mq = MediaQuery.of(context).size;
  
  final snack = SnackBar(
    behavior: SnackBarBehavior.floating,
    // ปรับตำแหน่งให้อยู่กลางจอ
    margin: EdgeInsets.only(
      bottom: mq.height * 0.45, 
      left: mq.width * 0.15, 
      right: mq.width * 0.15
    ),
    // พื้นหลังสีดำโปร่งใส 0.8 ตามที่ต้องการ
    backgroundColor: Colors.black.withOpacity(0.8),
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15),
      side: BorderSide(color: accentColor.withOpacity(0.5), width: 1), // เพิ่มขอบสีจางๆ ตามสถานะ
    ),
    duration: const Duration(seconds: 2),
    content: Column(
      mainAxisSize: MainAxisSize.min, // ให้กรอบสูงพอดีกับเนื้อหา
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: accentColor, size: 40), // ไอคอนขนาดใหญ่ตรงกลาง
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white, 
            fontSize: 16, 
            fontWeight: FontWeight.bold,
            letterSpacing: 0.4,
          ),
        ),
      ],
    ),
  );

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(snack);
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ป้องกัน Layout เพี้ยนเวลาคีย์บอร์ดเด้งขึ้นมา
      resizeToAvoidBottomInset: false, 
      body: Stack(
        children: [
          // --- 1. พื้นหลังรูปภาพ ---
          SizedBox.expand(
            child: Image.network(
              'https://img.20mn.fr/h8-cV-RDQUqLkFH49b400Ck/1444x920_camp-nou-accueillera-aucun-match-2024-2025',
              fit: BoxFit.cover,
              cacheWidth: 1000, 
            ),
          ),

          // Overlay สีดำจางๆ เพื่อให้ Text สีขาวเด่นขึ้น
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black.withOpacity(0.3),
          ),

          // --- 2. Header Text ---
          Positioned(
            top: 75,
            left: 30,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hello', style: subHeaderStyle.copyWith(color: Colors.white, fontSize: 30)),
                Text('Sign in!', style: subHeaderStyle.copyWith(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          // --- 3. ส่วนการ์ดข้อมูล (Black Transparent Card) ---
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.7, // ขยายความสูงเล็กน้อยเพื่อรองรับปุ่มโซเชียล
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.75),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Email
                    _CustomUnderlineField(
                      controller: _emailController,
                      hintText: 'example@gmail.com',
                      suffixIcon: const Icon(Icons.check, size: 18, color: Colors.grey),
                      labelText: 'Gmail',
                    ),
                      
                    const SizedBox(height: 6),
                    
                    // Password
                    _CustomUnderlineField(
                      controller: _passwordController,
                      labelText: 'Password',
                      hintText: '********',
                      obscureText: !_isPasswordVisible, 
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          size: 16,
                          color: Colors.grey,
                        ),
                        onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                      ),
                    ),
                    
                    // Forgot Password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: const Text('Forgot Password?', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ),
                    ),
                    const SizedBox(height: 2),

                    // ปุ่ม SIGN IN (Custom Gradient)
                    _buildSignInButton(),
                    
                    const SizedBox(height: 6),

                    // --- ส่วน Social Login (Google & X) ---
                    Row(
                      children: const [
                        Expanded(child: Divider(color: Colors.grey, thickness: 0.5)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text("Or login with", style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ),
                        Expanded(child: Divider(color: Colors.grey, thickness: 0.5)),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // ปุ่ม Google
                        _buildSocialButton(
                          iconUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1200px-Google_%22G%22_logo.svg.png',
                          onTap: () => print("Login with Google"),
                        ),
                        const SizedBox(width: 8),
                        // ปุ่ม X (Twitter)
                        _buildSocialButton(
                          iconUrl: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABwAAAAcCAAAAABXZoBIAAAA/0lEQVR4AbXPIazCMACE4d+L2qoZFEGSIGcRc/gJJB5XMzGJmK9EN0HMi+qaibkKVF1txdQe4g0YzPK5yyWXHL9TaPNQ89LojH87N1rbJcXkMF4Fk31UMrf34hm14KUeoQxGArALHTMuQD2cAWQfJXOpgTbksGr9ng8qluShJTPhyCdx63POg7rEim95ZyR68I1ggQpnCEGwyPicw6hZtPEGmnhkycqOio1zm6XuFtyw5XDXfGvuau0dXHzJp8pfBPuhIXO9ZK5ILUCdSvLYMpc6ASBtl3EaC97I4KaFaOCaBE9Zn5jUsVqR2vcTJZO1DdbGoZryVp94Ka/mQfE7f2T3df0WBhLDAAAAAElFTkSuQmCC',
                          onTap: () => print("Login with X"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Sign Up Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have account? ", style: TextStyle(color: Colors.grey)),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const SignUpScreen()),
                            );
                          },
                          child: const Text(
                            "Sign up", 
                            style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 255, 0, 64))
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget ปุ่ม Sign In
  Widget _buildSignInButton() {
    return Container(
      width: double.infinity,
      height: 45,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(colors: [Color(0xFFB22222), Color(0xFF4B0082)]),
      ),
      child: ElevatedButton(
        onPressed: signIn,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: const Text('SIGN IN', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // Widget ปุ่ม Social Login
  Widget _buildSocialButton({required String iconUrl, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Image.network(
          iconUrl,
          height: 25,
          width: 25,
          fit: BoxFit.contain,
          // จัดการกรณีรูปโหลดไม่ได้
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.error, size: 25),
        ),
      ),
    );
  }
}

// Widget สำหรับ TextField แบบขีดเส้นใต้
class _CustomUnderlineField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final bool obscureText;
  final Widget suffixIcon;

  const _CustomUnderlineField({
    required this.controller,
    required this.labelText,
    required this.hintText,
    this.obscureText = false,
    required this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(labelText, style: const TextStyle(color: Color.fromARGB(255, 255, 0, 64), fontWeight: FontWeight.bold, fontSize: 14)),
        TextField(
          controller: controller,
          obscureText: obscureText,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
            suffixIcon: suffixIcon,
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFB22222))),
          ),
        ),
      ],
    );
  }
}