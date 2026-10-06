import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Color primaryColor = const Color(0xFF911C21);
Color primaryColor = const Color(0xFFF1F3F2); // สีขาว/เทาอ่อน
Color LightBgColor = const Color(0xFF911C21); // สีแดงเข้ม
Color LightBgColor2 = const Color(0xFFE63946); // สีแดงสว่าง
Color secondaryColor = Colors.green;

TextStyle headerStyle = TextStyle(
  fontFamily: GoogleFonts.oswald().fontFamily,
  fontSize: 24,
  fontWeight: FontWeight.bold,
  color: primaryColor,
);

TextStyle subHeaderStyle = TextStyle(
  fontFamily: GoogleFonts.oswald().fontFamily,
  fontSize: 18,
  fontWeight: FontWeight.bold,
  color: Colors.black,
);

TextStyle bodyStyle = TextStyle(
  fontFamily: GoogleFonts.oswald().fontFamily,
  fontSize: 16,
  fontWeight: FontWeight.normal,
  color: Color(0xFFF1F3F2), // ปรับให้เหมาะกับพื้นหลังขาว
);
// ประกาศเป็นตัวแปรคงที่ (Constants) สำหรับเรียกใช้ซ้ำ
class BarcaStyle {
  static const Color barcaRed = Color(0xFFA50044);
  static const Color barcaBlue = Color(0xFF004D98);

  // ฟังก์ชันสร้างการตกแต่ง (Decoration) สำหรับรายการที่ถูกเลือก
  static BoxDecoration selectionDecoration({required bool isSelected}) {
    return BoxDecoration(
      // พื้นหลัง: ถ้าเลือกจะใช้สีแดงจางๆ (5%) ถ้าไม่เลือกจะโปร่งใส
      color: isSelected ? barcaRed.withOpacity(0.05) : Colors.transparent,
      
      // ความมนของขอบ
      borderRadius: BorderRadius.circular(10),
      
      // เส้นขอบ: ถ้าเลือกจะโชว์เฉพาะ "เส้นใต้" หนา 3px
      border: isSelected 
          ? const Border(bottom: BorderSide(color: barcaRed, width: 3)) 
          : null,
    );
  }

  // สไตล์ตัวอักษรสำหรับรายการที่ถูกเลือก
  static TextStyle selectionTextStyle({required bool isSelected, double fontSize = 18}) {
    return TextStyle(
      color: isSelected ? Colors.black : Colors.black54,
      fontSize: fontSize,
      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
    );
  }
}