import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screen/login_screen.dart';
import '../constant/my_constant.dart';





Widget MenuTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    bool isPrimary = false,
    bool isLogout = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
      decoration: BoxDecoration(
        color: isPrimary ? LightBgColor2 : Colors.transparent,
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isPrimary ? Colors.white : (isLogout ? LightBgColor2 : Colors.grey[700]),
        ),
        title: Text(
          title,
          style: bodyStyle.copyWith(
            color: isPrimary ? Colors.white : (isLogout ? LightBgColor2 : Colors.black87),
            fontWeight: isPrimary ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: isPrimary ? Colors.white : Colors.grey,
        ),
        onTap: () async {
          if (isLogout) {
            try {
              await FirebaseAuth.instance.signOut();
            } catch (_) {}
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
            return;
          }
          // ใส่ Logic การเปลี่ยนหน้าตรงนี้ สำหรับเมนูอื่นๆ
        },
      ),
    );
  }
