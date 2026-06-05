import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dpad/dpad.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_selection_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set fullscreen mode and prevent screen from sleeping
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  WakelockPlus.enable();
  
  await Supabase.initialize(
    url: 'https://bmpfpvxprhazwuhogkcf.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJtcGZwdnhwcmhhend1aG9na2NmIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2OTgyMDc1MCwiZXhwIjoyMDg1Mzk2NzUwfQ.VgFeGNGL51R3WyC1jrvMU86YaqxEp_voyKOoIY-psLg',
  );
  
  runApp(const GoPremiumApp());
}

class GoPremiumApp extends StatelessWidget {
  const GoPremiumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DpadNavigator(
      enabled: true,
      child: MaterialApp(
        title: 'GO PREMIUM',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        scrollBehavior: const MaterialScrollBehavior().copyWith(
          dragDevices: {
            PointerDeviceKind.mouse,
            PointerDeviceKind.touch,
            PointerDeviceKind.trackpad,
          },
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkLoginStatus(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            ),
          );
        }
        
        if (snapshot.data == true) {
          return const ProfileSelectionScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }

  Future<bool> _checkLoginStatus() async {
    final session = Supabase.instance.client.auth.currentSession;
    return session != null;
  }
}
