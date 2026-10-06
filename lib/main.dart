import 'package:Kikoff/screen/fields_list.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screen/profile_screen.dart';
import 'screen/login_screen.dart';
import 'screen/Home_screen_new.dart';
import 'screen/field_detail.dart';
import 'screen/booking_screen.dart';
import 'screen/intro_screen.dart'; // 1. เพิ่มการ Import หน้า Intro
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

bool seen = false; // ตัวแปรเก็บสถานะว่าเคยดู Intro หรือยัง

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // เริ่มต้น Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2. ดึงค่าสถานะ 'seen' จาก SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  seen = prefs.getBool('seen') ?? false;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.white,
      primaryColor: const Color(0xFFFFF8E1),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFFF8E1),
        foregroundColor: Colors.black,
        elevation: 2,
      ),
      textTheme: const TextTheme(bodyMedium: TextStyle(color: Colors.black)),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KickOff',
      theme: theme,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            // 3. ปรับ Logic การแสดงหน้าแรก: 
            // หาก seen เป็น true (เคยดูแล้ว) ไปหน้า HomeScreen
            // หาก seen เป็น false (ยังไม่เคยดู) ไปหน้า IntroScreen
            return MaterialPageRoute(
              builder: (ctx) => seen ? const HomeScreen() :  IntroScreen(),
            );
          case '/login':
            return MaterialPageRoute(builder: (ctx) => const LoginScreen());
          case '/profile':
            return MaterialPageRoute(builder: (ctx) => const ProfileScreen());
          case '/detail':
            return MaterialPageRoute(builder: (ctx) => FieldDetailScreen(data: settings.arguments));
          case '/booking':
            return MaterialPageRoute(builder: (ctx) => BookingScreen(field: settings.arguments));
          default:
            return null;
        }
      },
    );
  }
}