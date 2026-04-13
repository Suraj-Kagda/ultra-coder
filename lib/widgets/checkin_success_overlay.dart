import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CheckInSuccessOverlay extends StatelessWidget {
  const CheckInSuccessOverlay({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.green.shade700, borderRadius: BorderRadius.circular(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, size: 64, color: Colors.white),
              const SizedBox(height: 12),
              Text('$name checked in!', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
        ).animate().scale(duration: 300.ms).fadeIn(),
      ),
    );
  }
}
