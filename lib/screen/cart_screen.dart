import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
// ตรวจสอบว่าชื่อ package และ path ของ cart_constant.dart ถูกต้องตามโปรเจกต์ของคุณ
import 'package:Kikoff/constant/cart_constant.dart'; 

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'ตะกร้าสินค้า',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      // ถ้าตะกร้าว่างให้โชว์หน้า Empty ถ้ามีของให้โชว์รายการสินค้า
      body: CartManager.items.isEmpty ? _buildEmpty() : _buildList(),
      // แถบสรุปยอดเงินด้านล่าง (โชว์ตลอดเพื่อให้กดเช็คเงื่อนไขได้ตามที่คุณต้องการ)
      bottomNavigationBar: _buildCheckout(),
    );
  }

  // --- Widget กรณีตะกร้าว่าง ---
  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_basket_outlined, size: 80, color: Colors.grey[200]),
          const SizedBox(height: 20),
          const Text(
            'ตะกร้าของคุณยังว่างเปล่า',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  // --- Widget รายการสินค้าในตะกร้า ---
  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: CartManager.items.length,
      itemBuilder: (context, index) {
        final item = CartManager.items[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  item.image,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.broken_image, size: 70),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '฿${NumberFormat('#,###').format(item.price)}',
                      style: const TextStyle(color: BarcaStyle.barcaRed, fontSize: 14),
                    ),
                  ],
                ),
              ),
              // ส่วนปรับเพิ่ม/ลดจำนวน
              Row(
                children: [
                  _btn(Icons.remove, () {
                    setState(() {
                      if (item.quantity > 1) {
                        item.quantity--;
                      } else {
                        CartManager.items.removeAt(index);
                      }
                    });
                  }),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      '${item.quantity}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  _btn(Icons.add, () {
                    setState(() {
                      item.quantity++;
                    });
                  }),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ปุ่มบวก/ลบ จำนวนสินค้า
  Widget _btn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Icon(icon, size: 14, color: Colors.black),
      ),
    );
  }

  // --- Widget ส่วนสรุปยอดเงินและปุ่มดำเนินการ ---
  Widget _buildCheckout() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('รวมราคาสุทธิ', style: TextStyle(fontSize: 14, color: Colors.grey)),
              Text(
                '฿${NumberFormat('#,###.00').format(CartManager.totalPrice)}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: BarcaStyle.barcaRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: BarcaStyle.barcaBlue,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              onPressed: () {
                // ตรวจสอบเงื่อนไขตามที่คุณต้องการ
                if (CartManager.items.isEmpty) {
                  // ถ้าตะกร้าไม่มีอะไร ให้บอกว่าโปรดเลือกสินค้า
                  _showSimpleDialog('แจ้งเตือน', 'ตะกร้าว่างเปล่า โปรดเลือกสินค้าที่ต้องการก่อนชำระเงิน');
                } else {
                  // ถ้ามีสินค้า ให้เด้งว่าชำระเงินเรียบร้อย
                  _showSuccessDialog();
                }
              },
              child: const Text(
                'ดำเนินการสั่งซื้อ',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          )
        ],
      ),
    );
  }

  // ป๊อปอัพแจ้งชำระเงินสำเร็จ
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // ป้องกันการกดปิดด้านนอกเพื่อให้ต้องกดตกลงเท่านั้น
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green, size: 60),
            SizedBox(height: 15),
            Text('ชำระเงินเรียบร้อย', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'ขอบคุณที่ร่วมเป็นส่วนหนึ่งกับ Kikoff\nเราได้รับคำสั่งซื้อของคุณแล้ว',
          textAlign: TextAlign.center,
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: BarcaStyle.barcaBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                // ล้างข้อมูลในตะกร้าหลังจากชำระเงินสำเร็จ
                setState(() {
                  CartManager.items.clear();
                });
                Navigator.pop(ctx); // ปิดป๊อปอัพ
              },
              child: const Text('ตกลง', style: TextStyle(color: Colors.white)),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // ป๊อปอัพแจ้งเตือนทั่วไป (เช่น ตะกร้าว่าง)
  void _showSimpleDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('เข้าใจแล้ว', style: TextStyle(color: BarcaStyle.barcaBlue)),
          ),
        ],
      ),
    );
  }
}