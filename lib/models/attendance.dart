import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceLog {
  const AttendanceLog({
    required this.id,
    required this.memberId,
    required this.memberName,
    required this.branchId,
    required this.checkedInAt,
    required this.dayKey,
  });

  final String id;
  final String memberId;
  final String memberName;
  final String branchId;
  final DateTime checkedInAt;
  final String dayKey;

  Map<String, dynamic> toMap() {
    return {
      'memberId': memberId,
      'memberName': memberName,
      'branchId': branchId,
      'checkedInAt': Timestamp.fromDate(checkedInAt),
      'dayKey': dayKey,
    };
  }

  factory AttendanceLog.fromMap(String id, Map<String, dynamic> map) {
    return AttendanceLog(
      id: id,
      memberId: map['memberId'] as String? ?? '',
      memberName: map['memberName'] as String? ?? '',
      branchId: map['branchId'] as String? ?? 'main',
      checkedInAt: (map['checkedInAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dayKey: map['dayKey'] as String? ?? '',
    );
  }
}
