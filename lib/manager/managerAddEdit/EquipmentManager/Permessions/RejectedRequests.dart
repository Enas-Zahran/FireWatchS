import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:ui' as ui;
import 'package:FireWatch/manager/managerAddEdit/EquipmentManager/Permessions/exportRequests.dart';

class RejectedExportRequestsPage extends StatefulWidget {
  const RejectedExportRequestsPage({super.key});

  @override
  State<RejectedExportRequestsPage> createState() =>
      _RejectedExportRequestsPageState();
}

class _RejectedExportRequestsPageState
    extends State<RejectedExportRequestsPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> requests = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchApprovedRequests();
  }

  Future<void> _fetchApprovedRequests() async {
    final response = await supabase
        .from('export_requests')
        .select('id, created_by_name, created_at')
        .eq('is_submitted', true)
        .eq('is_approved', false)
        .order('created_at', ascending: false);

    setState(() {
      requests = List<Map<String, dynamic>>.from(response);
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xff00408b),
          title: const Center(
            child: Text(
              'التصاريح المرفوضة',
              style: TextStyle(color: Colors.white),
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body:
            loading
                ? const Center(child: CircularProgressIndicator())
                : requests.isEmpty
                ? const Center(child: Text('لا يوجد تصاريح مرفوضة حالياً'))
                : ListView.builder(
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final req = requests[index];
                    final technicianName =
                        req['created_by_name'] ?? 'غير معروف';
                    final createdAt =
                        req['created_at']?.toString().split('T').first ?? '';

                    return ListTile(
                      leading: const Icon(
                        Icons.check_circle,
                        color: Colors.red,
                      ),
                      title: Text('طلب من: $technicianName'),
                      subtitle: Text('تاريخ الطلب: $createdAt'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => ExportRequestMaterialsPage(
                                  requestId: req['id'],
                                  technicianName: technicianName,
                                  isReadonly: true, // ✅ عرض فقط
                                ),
                          ),
                        );
                      },
                    );
                  },
                ),
      ),
    );
  }
}
