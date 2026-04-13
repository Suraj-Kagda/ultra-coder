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

class MembersState {
  const MembersState({
    this.members = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.query = '',
    this.error,
  });

  final List<Member> members;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String query;
  final Object? error;

  MembersState copyWith({
    List<Member>? members,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? query,
    Object? error = _sentinel,
  }) {
    return MembersState(
      members: members ?? this.members,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      query: query ?? this.query,
      error: identical(error, _sentinel) ? this.error : error,
    );
  }
}

const _sentinel = Object();

class MembersNotifier extends StateNotifier<MembersState> {
  MembersNotifier(this._service) : super(const MembersState());

  final MemberService _service;
  DocumentSnapshot<Map<String, dynamic>>? _lastDoc;
  static const _pageSize = 50;

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, members: [], hasMore: true, error: null);
    _lastDoc = null;
    try {
      if (state.query.trim().isNotEmpty) {
        final results = await _service.searchMembers(state.query);
        state = state.copyWith(
          members: results,
          isLoading: false,
          isLoadingMore: false,
          hasMore: false,
        );
        return;
      }

      final page = await _service.fetchMembersPage(limit: _pageSize);
      _lastDoc = page.lastDoc;
      state = state.copyWith(
        members: page.members,
        isLoading: false,
        isLoadingMore: false,
        hasMore: page.hasMore,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, isLoadingMore: false, error: e);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore || state.query.isNotEmpty) return;
    state = state.copyWith(isLoadingMore: true, error: null);
    try {
      final page = await _service.fetchMembersPage(limit: _pageSize, startAfter: _lastDoc);
      _lastDoc = page.lastDoc ?? _lastDoc;
      state = state.copyWith(
        members: [...state.members, ...page.members],
        isLoadingMore: false,
        hasMore: page.hasMore,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e);
    }
  }

  Future<void> setQuery(String value) async {
    final trimmed = value.trim();
    if (trimmed == state.query) return;
    state = state.copyWith(query: trimmed);
    await loadInitial();
  }
}

final membersProvider = StateNotifierProvider<MembersNotifier, MembersState>((ref) {
  return MembersNotifier(ref.read(memberServiceProvider));
});
