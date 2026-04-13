import 'package:cloud_firestore/cloud_firestore.dart';

enum MembershipPlan { monthly, yearly }

class Member {
  const Member({
    required this.id,
    required this.name,
    required this.profilePhotoUrl,
    required this.phoneNumber,
    required this.plan,
    required this.startDate,
    required this.expiryDate,
    required this.branchId,
    this.createdAt,
    this.lastCheckInAt,
  });

  final String id;
  final String name;
  final String profilePhotoUrl;
  final String phoneNumber;
  final MembershipPlan plan;
  final DateTime startDate;
  final DateTime expiryDate;
  final String branchId;
  final DateTime? createdAt;
  final DateTime? lastCheckInAt;

  bool get isExpired => expiryDate.isBefore(DateTime.now());

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'profilePhotoUrl': profilePhotoUrl,
      'phoneNumber': phoneNumber,
      'plan': plan.name,
      'startDate': Timestamp.fromDate(startDate),
      'expiryDate': Timestamp.fromDate(expiryDate),
      'branchId': branchId,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'lastCheckInAt': lastCheckInAt != null ? Timestamp.fromDate(lastCheckInAt!) : null,
    };
  }

  factory Member.fromMap(String id, Map<String, dynamic> map) {
    return Member(
      id: id,
      name: map['name'] as String? ?? '',
      profilePhotoUrl: map['profilePhotoUrl'] as String? ?? '',
      phoneNumber: map['phoneNumber'] as String? ?? '',
      plan: MembershipPlan.values.firstWhere(
        (e) => e.name == map['plan'],
        orElse: () => MembershipPlan.monthly,
      ),
      startDate: (map['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiryDate: (map['expiryDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      branchId: map['branchId'] as String? ?? 'main',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      lastCheckInAt: (map['lastCheckInAt'] as Timestamp?)?.toDate(),
    );
  }
}
