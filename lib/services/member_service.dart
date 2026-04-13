import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import 'package:gymflow/models/member.dart';

class MemberService {
  MemberService(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _members => _firestore.collection('members');

  Future<MemberPage> fetchMembersPage({
    String branchId = 'main',
    int limit = 50,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) async {
    Query<Map<String, dynamic>> query = _members
        .where('branchId', isEqualTo: branchId)
        .orderBy('name_lower')
        .limit(limit);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();
    return MemberPage(
      members: snapshot.docs.map((doc) => Member.fromMap(doc.id, doc.data())).toList(),
      lastDoc: snapshot.docs.isEmpty ? null : snapshot.docs.last,
      hasMore: snapshot.docs.length == limit,
    );
  }

  Stream<List<Member>> watchMembers({String branchId = 'main', int limit = 100, DocumentSnapshot? startAfter}) {
    Query<Map<String, dynamic>> query = _members.where('branchId', isEqualTo: branchId).orderBy('name_lower').limit(limit);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    return query.snapshots().map((snapshot) => snapshot.docs.map((doc) => Member.fromMap(doc.id, doc.data())).toList());
  }

  Future<void> addMember(Member member) => _members.doc(member.id).set(member.toMap());

  Future<void> updateMember(Member member) => _members.doc(member.id).update(member.toMap());

  Future<void> deleteMember(String memberId) => _members.doc(memberId).delete();

  Future<List<Member>> searchMembers(String query, {String branchId = 'main'}) async {
    if (query.trim().isEmpty) return [];
    final normalized = query.toLowerCase();
    final snapshot = await _members
        .where('branchId', isEqualTo: branchId)
        .orderBy('name_lower')
        .where('name_lower', isGreaterThanOrEqualTo: normalized)
        .where('name_lower', isLessThanOrEqualTo: '$normalized\uf8ff')
        .limit(50)
        .get();
    return snapshot.docs.map((doc) => Member.fromMap(doc.id, doc.data())).toList();
  }

  Future<int> importFromCsvBytes(Uint8List bytes, {String branchId = 'main'}) async {
    final csvText = utf8.decode(bytes);
    final rows = const CsvToListConverter(eol: '\n').convert(csvText, shouldParseNumbers: false);
    if (rows.length < 2) return 0;

    final batch = _firestore.batch();
    int count = 0;

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length < 6) continue;
      final id = _members.doc().id;
      final member = Member(
        id: id,
        name: row[0].toString().trim(),
        profilePhotoUrl: row[1].toString().trim(),
        phoneNumber: row[2].toString().trim(),
        plan: row[3].toString().toLowerCase() == 'yearly' ? MembershipPlan.yearly : MembershipPlan.monthly,
        startDate: DateTime.tryParse(row[4].toString()) ?? DateTime.now(),
        expiryDate: DateTime.tryParse(row[5].toString()) ?? DateTime.now(),
        branchId: branchId,
      );
      if (member.name.isEmpty || member.phoneNumber.isEmpty) continue;
      batch.set(_members.doc(id), member.toMap());
      count++;
    }

    await batch.commit();
    return count;
  }
}

class MemberPage {
  const MemberPage({
    required this.members,
    required this.lastDoc,
    required this.hasMore,
  });

  final List<Member> members;
  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;
  final bool hasMore;
}
