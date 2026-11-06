import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role;
  final String? photoUrl;
  final String? year;
  final String? program;
  final String? institution;
  final String? phoneNumber;
  final bool isSuspended;
  final String? suspensionReason;
  final DateTime? suspendedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.photoUrl,
    this.year,
    this.program,
    this.institution,
    this.phoneNumber,
    this.isSuspended = false,
    this.suspensionReason,
    this.suspendedAt,
    this.createdAt,
    this.updatedAt,
  });

  /// Converts Firestore timestamps or normal DateTime/string values to DateTime.
  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  /// Creates a UserModel from a Firestore document.
  factory UserModel.fromMap(String uid, Map<String, dynamic> data) {
    return UserModel(
      uid: uid,
      email: data['email'] as String? ?? '',
      name: data['name'] as String? ?? '',
      role: data['role'] as String? ?? 'student',
      photoUrl: data['photoUrl'] as String?,
      year: data['year'] as String?,
      program: data['program'] as String?,
      institution: data['institution'] as String?,
      phoneNumber: data['phoneNumber'] as String?,
      isSuspended: data['isSuspended'] as bool? ?? false,
      suspensionReason: data['suspensionReason'] as String?,
      suspendedAt: _parseDate(data['suspendedAt']),
      createdAt: _parseDate(data['createdAt']),
      updatedAt: _parseDate(data['updatedAt']),
    );
  }

  /// Converts the user to a Firestore-compatible map.
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'role': role,
      'photoUrl': photoUrl,
      'year': year,
      'program': program,
      'institution': institution,
      'phoneNumber': phoneNumber,
      'isSuspended': isSuspended,
      'suspensionReason': suspensionReason,
      'suspendedAt': suspendedAt,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? role,
    String? photoUrl,
    String? year,
    String? program,
    String? institution,
    String? phoneNumber,
    bool? isSuspended,
    String? suspensionReason,
    DateTime? suspendedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearSuspensionReason = false,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      photoUrl: photoUrl ?? this.photoUrl,
      year: year ?? this.year,
      program: program ?? this.program,
      institution: institution ?? this.institution,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isSuspended: isSuspended ?? this.isSuspended,
      suspensionReason: clearSuspensionReason
          ? null
          : (suspensionReason ?? this.suspensionReason),
      suspendedAt: clearSuspensionReason
          ? null
          : (suspendedAt ?? this.suspendedAt),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
