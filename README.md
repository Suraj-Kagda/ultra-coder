# GymFlow – Smart Gym Attendance System

GymFlow is a **tablet-first Flutter + Firebase application** for gym owners/admins to manage members, run quick daily check-ins, and track attendance analytics.

## Features

### 1) Admin Authentication
- Firebase Authentication email/password login for admin-only access.

### 2) Member Management
- Add, edit, delete members.
- Member fields:
  - Name
  - Profile photo URL
  - Phone number
  - Membership plan (monthly/yearly)
  - Start date
  - Expiry date
- Built with Firestore queries and indexes to scale to large lists (5,000+ members).

### 3) Tablet Check-in Dashboard
- Large touch-friendly card grid (photo + name).
- Real-time search by name or phone.
- Case-insensitive name lookup uses normalized `name_lower`.
- Tap member card to check in instantly.
- Check-in success animated overlay.

### 4) Attendance Tracking
- Saves attendance logs with:
  - `date` (`dayKey`)
  - `time` (`checkedInAt`)
  - `memberId`
- Duplicate check-ins prevented per member/day using deterministic log IDs: `attendance_logs/{memberId_YYYYMMDD}`.

### 5) Analytics
- Daily attendance count.
- 30-day trend chart.
- Most active members.
- Inactive members (no attendance in last X days).

### 6) Membership Validity
- Expired memberships are labeled with an `Expired` badge.
- Check-in is blocked for expired members.

### 7) Notifications (FCM-ready)
- Firebase Cloud Messaging permission + topic initialization for admin alerts.
- Can be connected to Cloud Functions for:
  - Expiring membership reminders
  - Inactive member reminders

### 8) Bulk Member Import
- CSV file picker import.
- Row validation before Firestore batch write.

### 9) Performance
- Indexed Firestore queries.
- Search + limited query windows.
- Grid UI optimized for tablets.

### Firestore Search Pattern (Case-Insensitive Prefix)

Each member stores a normalized field:

```json
{
  "name": "Suraj",
  "name_lower": "suraj"
}
```

Search query pattern:

```dart
.where('name_lower', isGreaterThanOrEqualTo: query.toLowerCase())
.where('name_lower', isLessThanOrEqualTo: '${query.toLowerCase()}\\uf8ff')
```

This is the standard Firestore workaround for case-insensitive prefix search.

### 10) Optional Future Scope
- QR code check-in.
- Face recognition check-in.
- Multi-branch support (`branchId` field already included).

---

## Folder Structure

```txt
lib/
  models/
    member.dart
    attendance.dart
    membership.dart
  providers/
    app_providers.dart
  services/
    auth_service.dart
    member_service.dart
    attendance_service.dart
    analytics_service.dart
    notification_service.dart
    firebase_options.dart
  screens/
    login_screen.dart
    dashboard_screen.dart
    add_member_screen.dart
    analytics_screen.dart
  widgets/
    member_card.dart
    checkin_success_overlay.dart
  main.dart
```

---

## Firestore Data Structure

Collections:
- `users/`
- `members/`
- `attendance_logs/`
- `memberships/`

### Example `members/{memberId}`
```json
{
  "name": "John Doe",
  "name_lower": "john doe",
  "profilePhotoUrl": "https://...",
  "phoneNumber": "+1...",
  "plan": "monthly",
  "startDate": "timestamp",
  "expiryDate": "timestamp",
  "branchId": "main",
  "lastCheckInAt": "timestamp"
}
```

### Example `attendance_logs/{memberId_YYYYMMDD}`
```json
{
  "memberId": "member_123",
  "memberName": "John Doe",
  "branchId": "main",
  "checkedInAt": "timestamp",
  "dayKey": "2026-04-13"
}
```

---

## Firebase Setup Guide

1. Create a Firebase project.
2. Enable **Authentication → Email/Password**.
3. Create Firestore database.
4. Deploy Firestore rules:
   ```bash
   firebase deploy --only firestore:rules
   ```
5. Deploy indexes:
   ```bash
   firebase deploy --only firestore:indexes
   ```
6. Enable Firebase Cloud Messaging.
7. Replace placeholders in `lib/services/firebase_options.dart`.
8. Create one admin user in Firebase Auth.

---

## Local Setup

```bash
flutter pub get
flutter run -d <tablet-device-id>
```

Recommended tablet target width: 900px+.

---

## CSV Import Format

Header:
```csv
name,profilePhotoUrl,phoneNumber,plan,startDate,expiryDate
```

Example row:
```csv
Jane Doe,https://example.com/jane.jpg,+15550001234,yearly,2026-01-01,2027-01-01
```

- Date format expected: `YYYY-MM-DD`
- Invalid/incomplete rows are skipped.

---

## Notes

- Firestore and Firebase dependencies are included in `pubspec.yaml`.
- This codebase is modular and Riverpod-driven.
- For production, add storage upload flow for profile photos and Cloud Functions for scheduled notification jobs.
