class PaymentModel {
  final String id;
  final String userId;
  final double amount;
  final String paymentReference;
  final String? proofUrl;
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;

  PaymentModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.paymentReference,
    this.proofUrl,
    required this.status,
    required this.submittedAt,
    this.reviewedAt,
    this.reviewedBy,
  });

  factory PaymentModel.fromMap(String id, Map<String, dynamic> data) {
    return PaymentModel(
      id: id,
      userId: data['userId'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      paymentReference: data['paymentReference'] ?? '',
      proofUrl: data['proofUrl'],
      status: data['status'] ?? 'pending',
      submittedAt: data['submittedAt'] != null
          ? DateTime.parse(data['submittedAt'])
          : DateTime.now(),
      reviewedAt: data['reviewedAt'] != null
          ? DateTime.parse(data['reviewedAt'])
          : null,
      reviewedBy: data['reviewedBy'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'amount': amount,
      'paymentReference': paymentReference,
      'proofUrl': proofUrl,
      'status': status,
      'submittedAt': submittedAt.toIso8601String(),
      'reviewedAt': reviewedAt?.toIso8601String(),
      'reviewedBy': reviewedBy,
    };
  }
}