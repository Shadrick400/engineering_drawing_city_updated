import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionModel {
  final String id;
  final String userId;
  final String status; // 'active', 'expired', 'pending'
  final DateTime startDate;
  final DateTime expiryDate;
  final double amount;
  final String paymentReference;
  final String? approvedBy;
  final DateTime createdAt;

  SubscriptionModel({
    required this.id,
    required this.userId,
    required this.status,
    required this.startDate,
    required this.expiryDate,
    required this.amount,
    required this.paymentReference,
    this.approvedBy,
    required this.createdAt,
  });

  static DateTime _readDate(dynamic value, DateTime fallback) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? fallback;
    return fallback;
  }

  factory SubscriptionModel.fromMap(String id, Map<String, dynamic> data) {
    final now = DateTime.now();
    return SubscriptionModel(
      id: id,
      userId: data['userId'] ?? '',
      status: data['status'] ?? 'pending',
      startDate: _readDate(data['startDate'], now),
      expiryDate: _readDate(data['expiryDate'], now.add(const Duration(days: 30))),
      amount: (data['amount'] ?? 0.0).toDouble(),
      paymentReference: data['paymentReference'] ?? '',
      approvedBy: data['approvedBy'],
      createdAt: _readDate(data['createdAt'], now),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'status': status,
      'startDate': Timestamp.fromDate(startDate),
      'expiryDate': Timestamp.fromDate(expiryDate),
      'amount': amount,
      'paymentReference': paymentReference,
      'approvedBy': approvedBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
