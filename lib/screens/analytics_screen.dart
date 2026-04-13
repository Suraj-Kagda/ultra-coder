import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymflow/providers/app_providers.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.read(analyticsServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Attendance Analytics')),
      body: FutureBuilder(
        future: Future.wait([
          analytics.dailyCounts(days: 30),
          analytics.mostActiveMembers(top: 10),
          analytics.inactiveMembers(inactiveDays: 14),
        ]),
        builder: (_, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final daily = snapshot.data![0] as Map<String, int>;
          final active = snapshot.data![1] as List<MapEntry<dynamic, int>>;
          final inactive = snapshot.data![2] as List<dynamic>;

          final spots = daily.entries
              .toList()
              .asMap()
              .entries
              .map((e) => FlSpot(e.key.toDouble(), e.value.value.toDouble()))
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('30-day trend', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              SizedBox(
                height: 220,
                child: LineChart(
                  LineChartData(
                    lineBarsData: [LineChartBarData(spots: spots, isCurved: true, barWidth: 4)],
                    titlesData: const FlTitlesData(show: false),
                    gridData: const FlGridData(show: false),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Most active members', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ...active.map((entry) => ListTile(title: Text(entry.key.name as String), trailing: Text('${entry.value} visits'))),
              const SizedBox(height: 20),
              Text('Inactive members (14+ days): ${inactive.length}', style: const TextStyle(fontSize: 18)),
            ],
          );
        },
      ),
    );
  }
}
