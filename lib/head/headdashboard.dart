import 'package:flutter/material.dart';
import 'package:FireWatch/head/HeadPeriodicLocation.dart';
import 'package:FireWatch/head/HeadCorrectiveLocation.dart';
import 'package:FireWatch/head/HeadEmergencyLocation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:FireWatch/head/HeadNotifications.dart';
import 'package:FireWatch/My/BuildTile.dart';

class Headdashboard extends StatelessWidget {
  static const String routeName = 'headTasksMainPage';

  const Headdashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xff00408b),
          title: const Center(
            child: Text(
              'لوحة رئيس الشعبة',
              style: TextStyle(color: Colors.white),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications, color: Colors.white),
              tooltip: 'الإشعارات',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HeadNotificationsPage(),
                  ),
                );
              },
            ),
          ],
          leading: IconButton(
            icona: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              showDialog(
                context: context,
                builder:
                    (context) => Directionality(
                      textDirection: TextDirection.rtl,
                      child: AlertDialog(
                        title: const Text('تأكيد تسجيل الخروج'),
                        content: const Text(
                          'سيتم تسجيل خروجك من الحساب. هل أنت متأكد؟',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () async {
                              await Supabase.instance.client.auth.signOut();
                              if (context.mounted) {
                                Navigator.pop(context); // close dialog
                                Navigator.pop(context); // go back to login
                              }
                            },
                            child: const Text('نعم'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('لا'),
                          ),
                        ],
                      ),
                    ),
              );
            },
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(30, 50, 30, 30),
          children: [
            BuildTile(
              
              title: 'دوري',
              icon: Icons.access_time,
              destination: const HeadPeriodicLocationsPage(),
            ),
            const SizedBox(height: 12),
            BuildTile(
              
              title: 'علاجي',
              icon: Icons.healing,
              destination: const HeadCorrectiveLocationsPage(),
            ),
            const SizedBox(height: 12),
            BuildTile(
           
              title: 'طارئ',
              icon: Icons.report,
              destination: const HeadEmergencyLocationsPage(),
            ),
          ],
        ),
      ),
    );
  }
}
