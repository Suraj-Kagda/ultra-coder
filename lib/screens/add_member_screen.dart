import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymflow/models/member.dart';
import 'package:gymflow/providers/app_providers.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class AddMemberScreen extends ConsumerStatefulWidget {
  const AddMemberScreen({super.key, this.member});

  final Member? member;

  @override
  ConsumerState<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends ConsumerState<AddMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _photo = TextEditingController();
  final _phone = TextEditingController();
  MembershipPlan _plan = MembershipPlan.monthly;
  DateTime _startDate = DateTime.now();
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 30));
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    final member = widget.member;
    if (member != null) {
      _name.text = member.name;
      _photo.text = member.profilePhotoUrl;
      _phone.text = member.phoneNumber;
      _plan = member.plan;
      _startDate = member.startDate;
      _expiryDate = member.expiryDate;
    }
  }

  DateTime _calculateExpiry(DateTime start, MembershipPlan plan) {
    return plan == MembershipPlan.yearly
        ? start.add(const Duration(days: 365))
        : start.add(const Duration(days: 30));
  }

  Future<void> _pickStartDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _startDate = selected;
      _expiryDate = _calculateExpiry(selected, _plan);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final isEditing = widget.member != null;
    final id = widget.member?.id ?? const Uuid().v4();
    final member = Member(
      id: id,
      name: _name.text.trim(),
      profilePhotoUrl: _photo.text.trim(),
      phoneNumber: _phone.text.trim(),
      plan: _plan,
      startDate: _startDate,
      expiryDate: _expiryDate,
      branchId: 'main',
    );

    if (isEditing) {
      await ref.read(memberServiceProvider).updateMember(member);
    } else {
      await ref.read(memberServiceProvider).addMember(member);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.member == null ? 'Add Member' : 'Edit Member')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Name'), validator: _required),
            TextFormField(controller: _photo, decoration: const InputDecoration(labelText: 'Profile Photo URL')),
            TextFormField(controller: _phone, decoration: const InputDecoration(labelText: 'Phone Number'), validator: _required),
            const SizedBox(height: 12),
            DropdownButtonFormField(
              value: _plan,
              items: MembershipPlan.values.map((e) => DropdownMenuItem(value: e, child: Text(e.name))).toList(),
              onChanged: (v) {
                final nextPlan = v ?? MembershipPlan.monthly;
                setState(() {
                  _plan = nextPlan;
                  _expiryDate = _calculateExpiry(_startDate, nextPlan);
                });
              },
              decoration: const InputDecoration(labelText: 'Membership Plan'),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Start Date'),
              subtitle: Text(_dateFormat.format(_startDate)),
              trailing: const Icon(Icons.calendar_month),
              onTap: _pickStartDate,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Expiry Date (Auto-calculated)'),
              subtitle: Text(_dateFormat.format(_expiryDate)),
              trailing: const Icon(Icons.event_available),
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: _submit, child: const Text('Save')),
          ],
        ),
      ),
    );
  }

  String? _required(String? value) => value == null || value.trim().isEmpty ? 'Required' : null;
}
