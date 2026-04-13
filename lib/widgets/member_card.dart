import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gymflow/models/member.dart';

class MemberCard extends StatelessWidget {
  const MemberCard({
    super.key,
    required this.member,
    required this.onTap,
    this.highlight = false,
  });

  final Member member;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final expired = member.isExpired;
    return Material(
      color: Colors.grey.shade900,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: member.profilePhotoUrl.isEmpty
                      ? Container(color: Colors.black26, child: const Icon(Icons.person, size: 48))
                      : CachedNetworkImage(
                          imageUrl: member.profilePhotoUrl,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              const SizedBox(height: 10),
              Text(member.name, maxLines: 1, overflow: TextOverflow.ellipsis),
              if (expired)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.red.shade700, borderRadius: BorderRadius.circular(20)),
                  child: const Text('Expired', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
        ),
      ),
    ).animate(target: highlight ? 1 : 0).shimmer(duration: 600.ms);
  }
}
