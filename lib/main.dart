import 'package:flutter/material.dart';
import 'theme/util.dart';
import 'theme/theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:app_links/app_links.dart';
// Start pages
import 'package:FireWatch/Start/startPage.dart';
import 'package:FireWatch/Start/signin.dart';
import 'package:FireWatch/Start/signup.dart';
// import 'package:FireWatch/Start/resetpassword.dart';
// import 'package:FireWatch/Start/changepassword.dart';
//technician
import 'package:FireWatch/technician/techniciandashboard.dart';
//manager
import 'package:FireWatch/manager/managerdashboard.dart';
//head
import 'package:FireWatch/head/headdashboard.dart';
//All
import 'package:FireWatch/All/addemergency.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://xtggednhsfejnozgruhb.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh0Z2dlZG5oc2Zlam5vemdydWhiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDgzMzQ5MjcsImV4cCI6MjA2MzkxMDkyN30.vTeUQssyR4fLW2OH5fgBwI4kkyKw5Tqb_tBpVjMx_xk',
  );

  // await initDeepLinkListener();

  runApp(const MyApp());
}

//Future<void> initDeepLinkListener() async {
// final appLinks = AppLinks();

// Listen for new incoming links while app is running

// // Handle cold start
// final initialUri = await appLinks.getInitialAppLink();
// if (initialUri != null &&
//     initialUri.scheme == 'firewatch' &&
//     initialUri.host == 'reset-password') {
//   final token = initialUri.queryParameters['token'];
//   if (token != null) {
//     _handleDeepLink(token);
//   }
// }
//}

// void _handleDeepLink(String token) {
//   Supabase.instance.client.auth
//       .verifyOTP(
//         type: OtpType.recovery,
//         token: token,
//       )
//       .then((session) {
//     debugPrint("OTP verified. Navigating to change password page.");

//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       navigatorKey.currentState?.pushNamed(
//         ChangePasswordPage.routeName,
//         arguments: {'token': token},
//       );
//     });
//   }).catchError((error) {
//     debugPrint("Failed to verify OTP: $error");
//   });
// }

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
          //start
          StartPage.startpageRoute: (context) => const StartPage(),
          SignUpPage.signupRoute: (context) => SignUpPage(),
          SignInPage.signinRoute: (context) => SignInPage(),
          // ResetPasswordRequestPage.routeName: (context) => ResetPasswordRequestPage(),
          // ChangePasswordPage.routeName: (context) => ChangePasswordPage(),
          //technician
          TechnicianDashboardPage.routeName:
              (context) => TechnicianDashboardPage(),
          //manager
          ManagerDashboard.managerDashboardRoute: (context) => ManagerDashboard(),
          //head
          Headdashboard.headdashboardRoute: (context) => Headdashboard(),
          //All
          AddEmergencyPage.addEmergencyRoute: (context) => AddEmergencyPage(),
        },
      ),
    );
  }
}
