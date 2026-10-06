import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  final String id;
  final String userId;
  final String fieldId;
  final DateTime start;
  final DateTime end;
  final String status; // pending, confirmed, cancelled

  Booking({
    required this.id,
    required this.userId,
    required this.fieldId,
    required this.start,
    required this.end,
    required this.status,
  });

  factory Booking.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) throw StateError('Missing booking data ${doc.id}');

    return Booking(
      id: doc.id,
      userId: (data['userId'] ?? '') as String,
      fieldId: (data['fieldId'] ?? '') as String,
      start: DateTime.parse((data['start'] ?? DateTime.now().toIso8601String()) as String),
      end: DateTime.parse((data['end'] ?? DateTime.now().toIso8601String()) as String),
      status: (data['status'] ?? 'pending') as String,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'fieldId': fieldId,
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
        'status': status,
      };
}
