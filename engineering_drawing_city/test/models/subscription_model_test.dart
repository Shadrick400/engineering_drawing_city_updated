import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:engineering_drawing_city/models/subscription_model.dart';

void main() {
  group('SubscriptionModel', () {
    final start = DateTime.utc(2026, 11, 1);
    final expiry = DateTime.utc(2026, 12, 1);

    test('serializes access dates as Firestore timestamps', () {
      final subscription = SubscriptionModel(
        id: 'student-uid',
        userId: 'student-uid',
        status: 'active',
        startDate: start,
        expiryDate: expiry,
        amount: 50,
        paymentReference: 'verified-reference',
        createdAt: start,
      );

      final map = subscription.toMap();

      expect(map['startDate'], isA<Timestamp>());
      expect(map['expiryDate'], isA<Timestamp>());
      expect((map['expiryDate'] as Timestamp).toDate().isAtSameMomentAs(expiry), isTrue);
    });

    test('reads legacy ISO date strings during migration', () {
      final subscription = SubscriptionModel.fromMap('student-uid', {
        'userId': 'student-uid',
        'status': 'active',
        'startDate': start.toIso8601String(),
        'expiryDate': expiry.toIso8601String(),
        'amount': 50,
        'paymentReference': 'old-reference',
        'createdAt': start.toIso8601String(),
      });

      expect(subscription.startDate, start);
      expect(subscription.expiryDate, expiry);
    });
  });
}
