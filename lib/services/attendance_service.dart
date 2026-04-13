import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gymflow/models/attendance.dart';
import 'package:gymflow/models/member.dart';
import 'package:intl/intl.dart';

class AttendanceService {
  AttendanceService(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _logs => _firestore.collection('attendance_logs');
  CollectionReference<Map<String, dynamic>> get _members => _firestore.collection('members');
  CollectionReference<Map<String, dynamic>> get _analyticsDaily => _firestore.collection('analytics_daily');
  CollectionReference<Map<String, dynamic>> get _memberStats => _firestore.collection('member_stats');

  String _dayKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);
  String _docDayKey(DateTime date) => DateFormat('yyyyMMdd').format(date);

  Future<bool> checkIn(Member member) async {
    if (member.isExpired) return false;

    final now = DateTime.now();
    final dayKey = _dayKey(now);
    final docId = '${member.id}_${_docDayKey(now)}';
    final logRef = _logs.doc(docId);
    final log = AttendanceLog(
      id: '',
      memberId: member.id,
      memberName: member.name,
      branchId: member.branchId,
      checkedInAt: now,
      dayKey: dayKey,
    ).toMap();

    try {
      await logRef.create(log);
    } on FirebaseException catch (e) {
      if (e.code == 'already-exists') {
        return false;
      }
      rethrow;
    }

    await _members.doc(member.id).update({'lastCheckInAt': Timestamp.fromDate(now)});
    await _analyticsDaily.doc(dayKey).set({
      'dayKey': dayKey,
      'branchId': member.branchId,
      'totalAttendance': FieldValue.increment(1),
      'activeMembers': FieldValue.arrayUnion([member.id]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _memberStats.doc(member.id).set({
      'memberId': member.id,
      'memberName': member.name,
      'branchId': member.branchId,
      'totalCheckIns': FieldValue.increment(1),
      'lastCheckInAt': Timestamp.fromDate(now),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return true;
  }

  Stream<int> watchDailyCount() {
    final dayKey = _dayKey(DateTime.now());
    return _logs.where('dayKey', isEqualTo: dayKey).snapshots().map((s) => s.size);
  }

  Future<List<AttendanceLog>> recentLogs({int days = 30}) async {
    final fromDate = DateTime.now().subtract(Duration(days: days));
    final snapshot = await _logs.where('checkedInAt', isGreaterThanOrEqualTo: Timestamp.fromDate(fromDate)).get();
    return snapshot.docs.map((doc) => AttendanceLog.fromMap(doc.id, doc.data())).toList();
  }
}
