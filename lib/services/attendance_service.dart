import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gymflow/models/attendance.dart';
import 'package:gymflow/models/member.dart';
import 'package:intl/intl.dart';

class AttendanceService {
  AttendanceService(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _logs => _firestore.collection('attendance_logs');
  CollectionReference<Map<String, dynamic>> get _members => _firestore.collection('members');

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
