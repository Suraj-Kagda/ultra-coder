import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymflow/models/member.dart';
import 'package:gymflow/providers/app_providers.dart';
import 'package:gymflow/screens/add_member_screen.dart';
import 'package:gymflow/screens/analytics_screen.dart';
import 'package:gymflow/widgets/checkin_success_overlay.dart';
import 'package:gymflow/widgets/member_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String? successName;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    Future.microtask(() => ref.read(membersProvider.notifier).loadInitial());
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter < 500) {
      ref.read(membersProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  Future<void> _checkIn(Member member) async {
    final ok = await ref.read(attendanceServiceProvider).checkIn(member);
    if (!mounted) return;
    if (ok) {
      setState(() => successName = member.name);
      Timer(const Duration(milliseconds: 900), () {
        if (mounted) setState(() => successName = null);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(member.isExpired ? 'Membership expired.' : 'Already checked-in today.')),
      );
    }
  }

  Future<void> _importCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;
    final count = await ref.read(memberServiceProvider).importFromCsvBytes(result.files.single.bytes!);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Imported $count members')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final membersState = ref.watch(membersProvider);
    final dailyCount = ref.watch(attendanceServiceProvider).watchDailyCount();

    return Scaffold(
      appBar: AppBar(
        title: const Text('GymFlow Check-in Dashboard'),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalyticsScreen())),
            icon: const Icon(Icons.bar_chart),
          ),
          IconButton(onPressed: _importCsv, icon: const Icon(Icons.upload_file)),
          IconButton(onPressed: () => ref.read(authServiceProvider).signOut(), icon: const Icon(Icons.logout)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddMemberScreen())),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Member'),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              StreamBuilder<int>(
                stream: dailyCount,
                builder: (_, snapshot) {
                  return ListTile(
                    title: const Text('Today\'s attendance'),
                    trailing: Text('${snapshot.data ?? 0}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  onChanged: (value) => ref.read(membersProvider.notifier).setQuery(value),
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search name or phone'),
                ),
              ),
              Expanded(
                child: membersState.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : membersState.error != null
                    ? Center(child: Text('Failed: ${membersState.error}'))
                    : GridView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(12),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.8,
                        ),
                        itemCount: membersState.members.length + (membersState.isLoadingMore ? 1 : 0),
                        itemBuilder: (_, i) {
                          if (i >= membersState.members.length) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          final member = membersState.members[i];
                          return MemberCard(member: member, onTap: () => _checkIn(member));
                        },
                      ),
              ),
            ],
          ),
          if (successName != null) CheckInSuccessOverlay(name: successName!),
        ],
      ),
    );
  }
}
