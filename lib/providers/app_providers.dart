import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymflow/models/member.dart';
import 'package:gymflow/services/analytics_service.dart';
import 'package:gymflow/services/attendance_service.dart';
import 'package:gymflow/services/auth_service.dart';
import 'package:gymflow/services/member_service.dart';
import 'package:gymflow/services/notification_service.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((_) => FirebaseAuth.instance);
final firestoreProvider = Provider<FirebaseFirestore>((_) => FirebaseFirestore.instance);
final firebaseMessagingProvider = Provider<FirebaseMessaging>((_) => FirebaseMessaging.instance);

final authServiceProvider = Provider<AuthService>((ref) => AuthService(ref.read(firebaseAuthProvider)));
final memberServiceProvider = Provider<MemberService>((ref) => MemberService(ref.read(firestoreProvider)));
final attendanceServiceProvider = Provider<AttendanceService>((ref) => AttendanceService(ref.read(firestoreProvider)));
final analyticsServiceProvider = Provider<AnalyticsService>((ref) => AnalyticsService(ref.read(firestoreProvider)));
final notificationServiceProvider = Provider<NotificationService>((ref) => NotificationService(ref.read(firebaseMessagingProvider)));

final authStateProvider = StreamProvider<User?>((ref) => ref.read(authServiceProvider).authStateChanges());

final memberSearchQueryProvider = StateProvider<String>((_) => '');

final memberListProvider = StreamProvider<List<Member>>((ref) {
  return ref.read(memberServiceProvider).watchMembers(limit: 250);
});

final filteredMembersProvider = Provider<AsyncValue<List<Member>>>((ref) {
  final query = ref.watch(memberSearchQueryProvider).toLowerCase();
  final membersAsync = ref.watch(memberListProvider);

  return membersAsync.whenData((members) {
    if (query.isEmpty) return members;
    return members.where((m) => m.name.toLowerCase().contains(query) || m.phoneNumber.contains(query)).toList();
  });
});
