// --- صفحة قائمة الشركات المنفذة مع تعديل، حذف، وإضافة ---

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:FireWatch/My/InputDecoration.dart';
import 'package:FireWatch/manager/managerAddEdit/PriceManager/companies/addCompany.dart';
import 'package:FireWatch/manager/managerAddEdit/PriceManager/companies/editCompany.dart';
import 'dart:ui'as ui;

class ExecutingCompanyListPage extends StatefulWidget {
  const ExecutingCompanyListPage({super.key});

  @override
  State<ExecutingCompanyListPage> createState() => _ExecutingCompanyListPageState();
}

class _ExecutingCompanyListPageState extends State<ExecutingCompanyListPage> {
  List<Map<String, dynamic>> _companies = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchCompanies();
  }

  Future<void> _fetchCompanies() async {
    final data = await Supabase.instance.client
        .from('contract_companies')
        .select()
        .order('contract_start_date', ascending: false);

    setState(() {
      _companies = List<Map<String, dynamic>>.from(data);
      _loading = false;
    });
  }

  String formatDate(String? dateStr) {
    if (dateStr == null) return 'غير محدد';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('yyyy-MM-dd').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  Future<void> _confirmDelete(BuildContext context, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: const Text('هل أنت متأكد من حذف هذه الشركة؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حذف', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      await Supabase.instance.client.from('contract_companies').delete().eq('id', id);
      _fetchCompanies();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Center(child: Text('الشركات المنفذة', style: TextStyle(color: Colors.white))),
          backgroundColor: const Color(0xff00408b),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddExecutingCompanyPage()),
                );
                _fetchCompanies();
              },
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: _companies.length,
                itemBuilder: (context, index) {
                  final company = _companies[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Text(company['company_name'] ?? ''),
                      subtitle: Text(
                        'من: ${formatDate(company['contract_start_date'])}  إلى: ${formatDate(company['contract_end_date'])}',
                        style: const TextStyle(fontSize: 13),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EditExecutingCompanyPage(company: company),
                                ),
                              );
                              _fetchCompanies();
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _confirmDelete(context, company['id']),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
