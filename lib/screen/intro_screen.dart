import 'package:Kikoff/screen/Home_screen_new.dart';
import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'fields_list.dart';
class IntroScreen extends StatelessWidget {
  IntroScreen({super.key});

  // สีประจำสโมสรบาร์เซโลน่า
  final Color barcaBlue = const Color(0xFF004D98);
  final Color barcaRed = const Color(0xFFA50044);
  final Color barcaGold = const Color(0xFFEDBB00);

  // สไตล์ข้อความพื้นฐานสำหรับโหมดเต็มจอ (สีขาว + เงา)
  final TextStyle titleStyle = const TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    shadows: [
      Shadow(blurRadius: 10, color: Colors.black, offset: Offset(2, 2)),
    ],
  );

  final TextStyle bodyStyle = const TextStyle(
    fontSize: 18,
    color: Colors.white,
    shadows: [
      Shadow(blurRadius: 8, color: Colors.black, offset: Offset(1, 1)),
    ],
  );

  @override
  Widget build(BuildContext context) {
    // ปรับปรุงเนื้อหาให้เกี่ยวกับแอป KickOff
    final List<PageViewModel> pages = [
      PageViewModel(
        title: "ยินดีต้อนรับสู่ KickOff",
        body: "แอปพลิเคชันจองสนามฟุตบอลที่ง่ายและรวดเร็วที่สุดสำหรับแฟนบอลตัวจริง",
        image: _buildFullscreenImage('lib/images/page-1.jpg'),
        decoration: PageDecoration(
          fullScreen: true,
          titleTextStyle: titleStyle,
          bodyTextStyle: bodyStyle,
        ),
      ),
      PageViewModel(
        title: "จองสนามได้ทันใจ",
        body: "เลือกสนามที่คุณชอบ ระบุวันเวลาที่ต้องการ แล้วกดจองได้ทันที พร้อมระบบคำนวณราคาอัตโนมัติ",
        image: _buildFullscreenImage('lib/images/page-2.jpg'),
        decoration: PageDecoration(
          fullScreen: true,
          titleTextStyle: titleStyle,
          bodyTextStyle: bodyStyle,
        ),
      ),
      PageViewModel(
        title: "ตรวจสอบตารางการใช้งาน",
        body: "เช็คสถานะสนามว่างและจัดการประวัติการจองของคุณได้ในที่เดียว ไม่ต้องรอนาน",
        image: _buildFullscreenImage('lib/images/page-3.jpg'),
        decoration: PageDecoration(
          fullScreen: true,
          titleTextStyle: titleStyle,
          bodyTextStyle: bodyStyle,
        ),
      ),
    ];

    return Scaffold(
      body: IntroductionScreen(
        pages: pages,
        // ปรับแต่งจุดบอกตำแหน่ง (Dots)
        dotsDecorator: DotsDecorator(
          color: Colors.white.withOpacity(0.5),
          activeColor: barcaGold,
          size: const Size(10, 10),
          activeSize: const Size(22, 10),
          activeShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        
        // ปุ่มควบคุม
        showSkipButton: true,
        skip: const Text('ข้าม', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        
        showNextButton: true,
        next: Icon(Icons.arrow_forward, color: barcaGold),
        
        showDoneButton: true,
        done: Text('เริ่มเลย', style: TextStyle(fontWeight: FontWeight.bold, color: barcaGold)),

        // เมื่อกด Done หรือเริ่มใช้งาน
        onDone: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('seen', true);

          if (context.mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          }
        },
      ),
    );
  }

  // Helper Function สำหรับสร้าง Widget รูปภาพเต็มจอ
  Widget _buildFullscreenImage(String assetName) {
    return Image.asset(
      assetName,
      fit: BoxFit.cover, 
      height: double.infinity,
      width: double.infinity,
      alignment: Alignment.center,
    );
  }
}