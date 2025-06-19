import 'package:flutter/material.dart';
import 'package:FireWatch/manager/missions/add_edit_page.dart';
import 'package:FireWatch/manager/missions/reports_page.dart';
import 'package:FireWatch/manager/missions/tasks_page.dart';
import 'package:FireWatch/My/BuildTile.dart';
class ManagerDashboard extends StatelessWidget {
  static const String managerDashboardRoute = 'managerdashboard';

  const ManagerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xff00408b),
          title: const Center(
            child: Text(
              'لوحة تحكم مدير دائرة السلامة',
              style: TextStyle(color: Colors.white),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return Directionality(
                    textDirection: TextDirection.rtl,
                    child: AlertDialog(
                      title: const Text('تأكيد'),
                      content: const Text(
                        'هل أنت متأكد من الرجوع لصفحة الدخول؟',
                      ),
                      actions: <Widget>[
                        TextButton(
                          child: const Text('نعم'),
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.of(
                              context,
                            ).popUntil((route) => route.isFirst);
                          },
                        ),
                        TextButton(
                          child: const Text('إلغاء'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(30, 70, 30, 50),
          children: [
            BuildTile(
             
              title: 'المهام',
              icon: Icons.task_alt,
              destination: const TasksMainPage(),
            ),
            const SizedBox(height: 12),
            BuildTile(
            
              title: 'إضافة وتعديل',
              icon: Icons.edit,
              destination: const AddEditPage(),
            ),
            const SizedBox(height: 12),
            BuildTile(
             
              title: 'التقارير',
              icon: Icons.insert_chart,
              destination: const ReportsDashboardPage(),
            ),
          ],
        ),
      ),
    );
  }
}


