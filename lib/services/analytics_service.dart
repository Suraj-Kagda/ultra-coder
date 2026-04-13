import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gymflow/models/member.dart';
import 'package:intl/intl.dart';

class AnalyticsService {
  AnalyticsService(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _logs => _firestore.collection('attendance_logs');
  CollectionReference<Map<String, dynamic>> get _members => _firestore.collection('members');

  Future<Map<String, int>> dailyCounts({int days = 7}) async {
    final from = DateTime.now().subtract(Duration(days: days));
    final snapshot = await _logs.where('checkedInAt', isGreaterThanOrEqualTo: Timestamp.fromDate(from)).get();
    final map = <String, int>{};
    for (final doc in snapshot.docs) {
      final date = (doc.data()['checkedInAt'] as Timestamp).toDate();
      final key = DateFormat('MM/dd').format(date);
      map[key] = (map[key] ?? 0) + 1;
    }
    return map;
  }

  Future<List<MapEntry<Member, int>>> mostActiveMembers({int top = 10}) async {
    final logs = await _logs.get();
    final counts = <String, int>{};
    for (final doc in logs.docs) {
      final memberId = doc.data()['memberId'] as String;
      counts[memberId] = (counts[memberId] ?? 0) + 1;
    }

    final ids = counts.keys.toList();
    if (ids.isEmpty) return [];

    final membersSnapshot = await _members.where(FieldPath.documentId, whereIn: ids.take(30).toList()).get();
    final members = {
      for (final doc in membersSnapshot.docs) doc.id: Member.fromMap(doc.id, doc.data()),
    };

    final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(top).where((e) => members.containsKey(e.key)).map((e) => MapEntry(members[e.key]!, e.value)).toList();
  }

  Future<List<Member>> inactiveMembers({int inactiveDays = 14}) async {
    final threshold = DateTime.now().subtract(Duration(days: inactiveDays));
    final snapshot = await _members.get();
    return snapshot.docs
        .map((doc) => Member.fromMap(doc.id, doc.data()))
        .where((m) => m.lastCheckInAt == null || m.lastCheckInAt!.isBefore(threshold))
        .toList();
  }
}
