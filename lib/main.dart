import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymflow/providers/app_providers.dart';
import 'package:gymflow/screens/dashboard_screen.dart';
import 'package:gymflow/screens/login_screen.dart';
import 'package:gymflow/services/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: GymFlowApp()));
}

class GymFlowApp extends ConsumerStatefulWidget {
  const GymFlowApp({super.key});

  @override
  ConsumerState<GymFlowApp> createState() => _GymFlowAppState();
}

class _GymFlowAppState extends ConsumerState<GymFlowApp> {
  @override
  void initState() {
    super.initState();
    ref.read(notificationServiceProvider).initialize();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'GymFlow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F1117),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orangeAccent, brightness: Brightness.dark),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
      ),
      home: auth.when(
        data: (user) => user == null ? const LoginScreen() : const DashboardScreen(),
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, _) => Scaffold(body: Center(child: Text('Auth error: $e'))),
      ),
    );
  }
}
