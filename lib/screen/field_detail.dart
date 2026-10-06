import 'package:flutter/material.dart';
import '../data/product_firestore.dart';
import '/constant/my_constant.dart'; // นำเข้าไฟล์คอนสแตนต์
class FieldDetailScreen extends StatelessWidget {
  final dynamic data;
  const FieldDetailScreen({super.key, this.data});

  @override
  Widget build(BuildContext context) {
    final Field field = data as Field;
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(field.image, fit: BoxFit.cover),
            ),
            backgroundColor: BarcaStyle.barcaBlue, // ใช้ BarcaStyle
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.05),
                    borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(field.name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold))),
                          Text('฿${field.pricePerHour}/ชม.', 
                            style: const TextStyle(fontSize: 20, color: BarcaStyle.barcaRed, fontWeight: FontWeight.bold)), // ใช้ BarcaStyle
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 18, color: Colors.grey),
                          const SizedBox(width: 6),
                          Expanded(child: Text(field.location, style: const TextStyle(color: Colors.grey, fontSize: 14))),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('รายละเอียดสนาม', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Text(field.description, style: const TextStyle(color: Colors.black87, height: 1.6, fontSize: 15)),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
        child: SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: BarcaStyle.barcaRed, // ใช้ BarcaStyle
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            onPressed: () => Navigator.pushNamed(context, '/booking', arguments: field),
            child: const Text('จองทันที', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}