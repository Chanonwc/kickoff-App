import 'package:cloud_firestore/cloud_firestore.dart';

class Field {
  final String id;
  final String name;
  final double pricePerHour;
  final String description;
  final String image;
  final String location;


  Field({
    required this.id,
    required this.name,
    required this.pricePerHour,
    required this.description,
    required this.image,
    required this.location,

  });

factory Field.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    // ฟังก์ชันช่วยแปลงค่าเป็น double อย่างปลอดภัย ไม่ว่าใน Firebase จะเป็น String หรือ Number
    double parsePrice(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0.0;
    }

    return Field(
      id: doc.id,
      name: data['Name'] ?? data['name'] ?? '', // ดักไว้ทั้ง N ใหญ่ และ n เล็ก
      image: data['image'] ?? '', 
      description: data['description'] ?? '',
      location: data['location'] ?? 'ไม่ระบุสถานที่', 
      pricePerHour: parsePrice(data['pricePerHour']), // ใช้ฟังก์ชันช่วยแปลงค่า
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'pricePerHour': pricePerHour,
        'description': description,
        'image': image,
        'location': location,

      };
}
