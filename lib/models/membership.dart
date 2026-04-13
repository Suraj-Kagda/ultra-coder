class MembershipSummary {
  const MembershipSummary({
    required this.totalMembers,
    required this.activeMembers,
    required this.expiringSoon,
    required this.expired,
  });

  final int totalMembers;
  final int activeMembers;
  final int expiringSoon;
  final int expired;
}
