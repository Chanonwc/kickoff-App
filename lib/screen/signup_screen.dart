import 'package:Kikoff/screen/Home_screen_new.dart';
import 'package:flutter/material.dart';
import '/constant/my_constant.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

void signUp() async {
  // เช็คเบื้องต้นว่ารหัสผ่านตรงกันไหม
  if (_passwordController.text != _confirmPasswordController.text) {
    _showCenteredSnackBar(
      'Passwords do not match', 
      Icons.warning_amber_rounded, 
      Colors.orangeAccent
    );
    return;
  }

  try {
    final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );
    
    final uid = credential.user!.uid;
    
    // สร้าง user document ใน Firestore
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'displayName': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'role': 'user',
      'avatarUrl': '',
      'createdAt': FieldValue.serverTimestamp(),
    });

    print("User registered: $uid");

    // สำเร็จ: ไอคอนเขียว + พื้นหลังดำโปร่งใส
    _showCenteredSnackBar(
      'Registration Successful', 
      Icons.check_circle, 
      Colors.greenAccent
    );

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );

  } on FirebaseAuthException catch (e) {
    String errorMessage = 'Registration Failed';
    
    // จัดการ Error Message ตามสากล
    if (e.code == 'email-already-in-use') {
      errorMessage = 'This email is already registered';
    } else if (e.code == 'weak-password') {
      errorMessage = 'Password is too weak';
    } else if (e.code == 'invalid-email') {
      errorMessage = 'Invalid email format';
    }

    _showCenteredSnackBar(
      errorMessage, 
      Icons.cancel, 
      Colors.redAccent
    );
  } catch (e) {
    _showCenteredSnackBar(
      'An error occurred', 
      Icons.error_outline, 
      Colors.redAccent
    );
  }
}

  void _showCenteredSnackBar(String message, IconData icon, Color accentColor) {
  final mq = MediaQuery.of(context).size;
  
  final snack = SnackBar(
    behavior: SnackBarBehavior.floating,
    margin: EdgeInsets.only(
      bottom: mq.height * 0.45, 
      left: mq.width * 0.15, 
      right: mq.width * 0.15
    ),
    backgroundColor: Colors.black.withOpacity(0.85), // ดำโปร่งใส
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 25),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(color: accentColor.withOpacity(0.4), width: 1),
    ),
    duration: const Duration(seconds: 2),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: accentColor, size: 45), // ไอคอนเด่นๆ
        const SizedBox(height: 15),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white, 
            fontSize: 16, 
            fontWeight: FontWeight.bold,
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
      resizeToAvoidBottomInset: true, 
      body: Stack(
        children: [
          // --- 1. Background (ใช้รูปเดียวกับหน้า Login) ---
          SizedBox.expand(
            child: Image.network(
              'https://img.20mn.fr/h8-cV-RDQUqLkFH49b400Ck/1444x920_camp-nou-accueillera-aucun-match-2024-2025',
              fit: BoxFit.cover,
              cacheWidth: 1000,
            ),
          ),
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black.withOpacity(0.4),
          ),
          

          // --- 2. Header ---
          Positioned(
            top: 40,
            left: 30,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Create', style: subHeaderStyle.copyWith(color: Colors.white, fontSize: 28)),
                Text('Account!', style: subHeaderStyle.copyWith(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          // --- 3. Main Card ---
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.78, // เพิ่มความสูงเล็กน้อยเพื่อรองรับ Social Login
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.75),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 25),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _CustomUnderlineField(
                      controller: _nameController,
                      labelText: 'Full Name',
                      hintText: 'John Doe',
                      suffixIcon: const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 10),
                    _CustomUnderlineField(
                      controller: _emailController,
                      labelText: 'Email',
                      hintText: 'example@gmail.com',
                      suffixIcon: const Icon(Icons.email_outlined, size: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    _CustomUnderlineField(
                      controller: _phoneController,
                      labelText: 'Phone',
                      hintText: '0812345678',
                      suffixIcon: const Icon(Icons.phone_outlined, size: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    _CustomUnderlineField(
                      controller: _passwordController,
                      labelText: 'Password',
                      hintText: '********',
                      obscureText: !_isPasswordVisible,
                      suffixIcon: IconButton(
                        icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, size: 16, color: Colors.grey),
                        onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _CustomUnderlineField(
                      controller: _confirmPasswordController,
                      labelText: 'Confirm Password',
                      hintText: '********',
                      obscureText: !_isConfirmPasswordVisible,
                      suffixIcon: IconButton(
                        icon: Icon(_isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off, size: 16, color: Colors.grey),
                        onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ปุ่ม SIGN UP
                    _buildSignUpButton(),
                    
                    const SizedBox(height: 8),

                    // --- ส่วน Social Login (เพิ่มเข้ามาให้เหมือนหน้า Login) ---
                    Row(
                      children: const [
                        Expanded(child: Divider(color: Colors.grey, thickness: 0.5)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text("Or sign up with", style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ),
                        Expanded(child: Divider(color: Colors.grey, thickness: 0.5)),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildSocialButton(
                          iconUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1200px-Google_%22G%22_logo.svg.png',
                          onTap: () => print("Sign up with Google"),
                        ),
                        const SizedBox(width: 8),
                        _buildSocialButton(
                          iconUrl: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABwAAAAcCAAAAABXZoBIAAAA/0lEQVR4AbXPIazCMACE4d+L2qoZFEGSIGcRc/gJJB5XMzGJmK9EN0HMi+qaibkKVF1txdQe4g0YzPK5yyWXHL9TaPNQ89LojH87N1rbJcXkMF4Fk31UMrf34hm14KUeoQxGArALHTMuQD2cAWQfJXOpgTbksGr9ng8qluShJTPhyCdx63POg7rEim95ZyR68I1ggQpnCEGwyPicw6hZtPEGmnhkycqOio1zm6XuFtyw5XDXfGvuau0dXHzJp8pfBPuhIXO9ZK5ILUCdSvLYMpc6ASBtl3EaC97I4KaFaOCaBE9Zn5jUsVqR2vcTJZO1DdbGoZryVp94Ka/mQfE7f2T3df0WBhLDAAAAAElFTkSuQmCC',
                          onTap: () => print("Sign up with X"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // กลับไปหน้า Login
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Already have account? ", style: TextStyle(color: Colors.grey, fontSize: 13)),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text(
                            "Sign in", 
                            style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(255, 255, 0, 64), fontSize: 13)
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget ปุ่ม Sign Up
  Widget _buildSignUpButton() {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: const LinearGradient(colors: [Color(0xFFB22222), Color(0xFF4B0082)]),
      ),
      child: ElevatedButton(
        onPressed: () {
            signUp();
          },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        ),
        child: const Text('SIGN UP', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // Widget ปุ่ม Social (Google / X)
  Widget _buildSocialButton({required String iconUrl, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Image.network(
          iconUrl,
          height: 22,
          width: 22,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.error, size: 22),
        ),
      ),
    );
  }
}

// Custom TextField Widget
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
        Text(labelText, style: const TextStyle(color: Color.fromARGB(255, 255, 0, 64), fontWeight: FontWeight.bold, fontSize: 12)),
        TextField(
          controller: controller,
          obscureText: obscureText,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
            suffixIcon: suffixIcon,
            suffixIconConstraints: const BoxConstraints(minHeight: 24, minWidth: 24),
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24, width: 0.8)),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color.fromARGB(255, 255, 0, 64), width: 1.2)),
          ),
        ),
      ],
    );
  }
}