import 'package:flutter/material.dart';
import 'theme/util.dart';
import 'theme/theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';

// Start pages
import 'package:FireWatch/Start/startPage.dart';
import 'package:FireWatch/Start/signin.dart';
import 'package:FireWatch/Start/signup.dart';
import 'package:FireWatch/Start/changepassword.dart';

//technician
import 'package:FireWatch/technician/techniciandashboard.dart';
//manager
import 'package:FireWatch/manager/managerdashboard.dart';

//All
import 'package:FireWatch/All/addemergency.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:FireWatch/global.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar_SA', null);

  await Supabase.initialize(
    url: 'https://xtggednhsfejnozgruhb.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh0Z2dlZG5oc2Zlam5vemdydWhiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDgzMzQ5MjcsImV4cCI6MjA2MzkxMDkyN30.vTeUQssyR4fLW2OH5fgBwI4kkyKw5Tqb_tBpVjMx_xk',
  );

  // ✅ Call the function after defining it
   await initDeepLinks(); // ✅ Use await for the async function


  runApp(const MyApp());
}



Future<void> initDeepLinks() async {
  final appLinks = AppLinks();

  Future<void> handleUri(Uri uri) async {
    if (uri.host == 'reset-password' && uri.fragment.isNotEmpty) {
      final params = Uri.splitQueryString(uri.fragment);

      final accessToken = params['access_token'];
      final refreshToken = params['refresh_token'];

      if (accessToken != null && refreshToken != null) {
await Supabase.instance.client.auth.setSession(refreshToken);

        navigatorKey.currentState?.pushNamed('/newPassword');
      }
    }
  }

  final initialUri = await appLinks.getInitialAppLink();
  if (initialUri != null) await handleUri(initialUri);

  appLinks.uriLinkStream.listen((uri) async {
    if (uri != null) await handleUri(uri);
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = View.of(context).platformDispatcher.platformBrightness;
    final textTheme = createTextTheme(context, "Markazi Text", "Markazi Text");
    final theme = MaterialTheme(textTheme);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'FireWatch',
        theme: brightness == Brightness.light ? theme.light() : theme.dark(),
        initialRoute: StartPage.startpageRoute,
        routes: {
          StartPage.startpageRoute: (context) => const StartPage(),
          SignUpPage.signupRoute: (context) => SignUpPage(),
          SignInPage.signinRoute: (context) => SignInPage(),
          NewPasswordPage.routeName: (context) => NewPasswordPage(),

          TechnicianDashboardPage.routeName:
              (context) => TechnicianDashboardPage(),
          ManagerDashboard.managerDashboardRoute:
              (context) => ManagerDashboard(),

          AddEmergencyPage.addEmergencyRoute: (context) => AddEmergencyPage(),
        },
      ),
    );
  }
}
