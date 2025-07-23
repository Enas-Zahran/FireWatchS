import 'package:FireWatch/Start/signup.dart';
import 'package:flutter/material.dart';
import 'package:FireWatch/Start/signin.dart';

class StartPage extends StatelessWidget {
  static const String startpageRoute = 'startPage';
  const StartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),

              child: Column(
                children: [
                  Column(
                    children: [
                      Text(
                        'تطبيق الفحص الدوري لأدوات السلامة',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'شكرًا لحمايتكم أرواحنا، فكل فحص تقومون به يصنع فرقًا',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Color(0xff747878),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          'assets/icon/icon.png',
                          height: 200, // adjust as needed
                          width: 200,
                          fit: BoxFit.cover, // or BoxFit.contain for icons
                        ),
                      ),
                    ],
                  ),

                  Expanded(child: SizedBox()),

                  Column(
                    children: [
                      SizedBox(
                        child: ElevatedButton(
                          
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              SignUpPage.signupRoute,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                          minimumSize: Size(400, 50),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(

                            'إنشاء حساب',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 50.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  SignInPage.signinRoute,
                                );
                              },
                              child: Text(
                                'تسجيل الدخول',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              'لديك حساب؟',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: Color(0xff747878),
                              ),
                            ),
                          ],
                        ),
                      ),

                      Text(
                        'Programmed and designed by Enas Zahran',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Color(0xff747878),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
