import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gymflow/models/member.dart';
import 'package:intl/intl.dart';

class AnalyticsService {
  AnalyticsService(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _analyticsDaily => _firestore.collection('analytics_daily');
  CollectionReference<Map<String, dynamic>> get _memberStats => _firestore.collection('member_stats');
  CollectionReference<Map<String, dynamic>> get _members => _firestore.collection('members');

  Future<Map<String, int>> dailyCounts({int days = 7}) async {
    final from = DateTime.now().subtract(Duration(days: days));
    final fromKey = DateFormat('yyyy-MM-dd').format(from);
    final snapshot = await _analyticsDaily.where('dayKey', isGreaterThanOrEqualTo: fromKey).orderBy('dayKey').get();
    final map = <String, int>{};
    for (final doc in snapshot.docs) {
      final dayKey = doc.data()['dayKey'] as String? ?? '';
      if (dayKey.isEmpty) continue;
      final date = DateTime.tryParse(dayKey);
      if (date == null) continue;
      final key = DateFormat('MM/dd').format(date);
      map[key] = (doc.data()['totalAttendance'] as num?)?.toInt() ?? 0;
    }
    return map;
  }

  Future<List<MapEntry<Member, int>>> mostActiveMembers({int top = 10}) async {
    final statsSnapshot = await _memberStats.orderBy('totalCheckIns', descending: true).limit(top).get();
    if (statsSnapshot.docs.isEmpty) return [];

    final memberFutures = statsSnapshot.docs.map((doc) async {
      final memberId = doc.id;
      final count = (doc.data()['totalCheckIns'] as num?)?.toInt() ?? 0;
      final memberDoc = await _members.doc(memberId).get();
      if (!memberDoc.exists || memberDoc.data() == null) return null;
      return MapEntry(Member.fromMap(memberDoc.id, memberDoc.data()!), count);
    });

    final results = await Future.wait(memberFutures);
    return results.whereType<MapEntry<Member, int>>().toList();
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
