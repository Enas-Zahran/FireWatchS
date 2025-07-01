import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:FireWatch/technician/Approved.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

class TechnicianApprovedRequestsPage extends StatefulWidget {
  final String technicianId;
  final String technicianName;

  const TechnicianApprovedRequestsPage({
    super.key,
    required this.technicianId,
    required this.technicianName,
  });

  @override
  State<TechnicianApprovedRequestsPage> createState() =>
      _TechnicianApprovedRequestsPageState();
}

class _TechnicianApprovedRequestsPageState
    extends State<TechnicianApprovedRequestsPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> approvedRequests = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchApprovedRequests();
  }

  Future<void> _fetchApprovedRequests() async {
    final response = await supabase
        .from('export_requests')
        .select()
        .eq('created_by', widget.technicianId)
        .eq('is_approved', true)
        .order('created_at', ascending: false);

    setState(() {
      approvedRequests = List<Map<String, dynamic>>.from(response);
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Center(
            child: const Text(
              'تصاريح الإخراج المعتمدة',
              style: TextStyle(color: Colors.white),
            ),
          ),
          backgroundColor: const Color(0xff00408b),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        body:
            loading
                ? const Center(child: CircularProgressIndicator())
                : approvedRequests.isEmpty
                ? const Center(child: Text('لا توجد طلبات معتمدة حالياً'))
                : ListView.builder(
                  itemCount: approvedRequests.length,
                  itemBuilder: (context, index) {
                    final request = approvedRequests[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        title: Text(
                          'رمز الطلب: ${request['id'].toString().substring(0, 8)}...',
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('نوع المواد: ${request['material_type']}'),
                            if (request['approved_at'] != null)
                              Text(
                                'تاريخ الاعتماد: ${DateFormat.yMd().add_Hm().format(DateTime.parse(request['approved_at']))}',
                                style: const TextStyle(color: Colors.green),
                              ),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => FinalExportPreviewPage(
                                    request: {
                                      ...request,
                                      'technician_name':
                                          widget
                                              .technicianName, // أضفنا الاسم هنا
                                    },
                                    technicianName: widget.technicianName,
                                  ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
      ),
    );
  }
}
