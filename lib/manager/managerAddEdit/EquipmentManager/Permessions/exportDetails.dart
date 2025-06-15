import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class ExportRequestDetailsPage extends StatefulWidget {
  final String requestId;

  const ExportRequestDetailsPage({Key? key, required this.requestId}) : super(key: key);

  @override
  State<ExportRequestDetailsPage> createState() => _ExportRequestDetailsPageState();
}

class _ExportRequestDetailsPageState extends State<ExportRequestDetailsPage> {
  Map<String, dynamic>? request;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchRequest();
  }

  Future<void> _fetchRequest() async {
    final data = await Supabase.instance.client
        .from('export_requests')
        .select()
        .eq('id', widget.requestId)
        .maybeSingle();

    setState(() {
      request = data;
      loading = false;
    });
  }

  Future<void> _approveRequest() async {
    await Supabase.instance.client
        .from('export_requests')
        .update({'is_approved': true})
        .eq('id', widget.requestId);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم اعتماد الطلب')));
    Navigator.pop(context, true);
  }

  String formatDate(String? date) {
    if (date == null) return 'غير محدد';
    try {
      return DateFormat('yyyy-MM-dd').format(DateTime.parse(date));
    } catch (_) {
      return date;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xff00408b),
          title: const Text('عرض التفاصيل', style: TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : request == null
                ? const Center(child: Text('لم يتم العثور على الطلب'))
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: ListView(
                      children: [
                        buildTile('تاريخ الطلب', formatDate(request!['created_at'])),
                        buildTile('اسم السيد ورقم المركبة ونوعها',
                            '${request!['vehicle_owner']} - ${request!['vehicle_number']} - ${request!['vehicle_type']}'),
                        buildTile('المواد والإجراءات عليها', request!['materials_details']),
                        buildTile('الأسباب', request!['reason']),
                        buildTile('نوع المواد', request!['material_type']),
                        buildTile('تاريخ إعادة المواد', formatDate(request!['return_date'])),
                        buildTile('اسم الفني', request!['technician_name']),
                        buildTile('توقيع الفني', request!['technician_signature'] ?? 'غير موقع'),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: request!['is_approved'] == true ? null : _approveRequest,
                          child: const Text('اعتماد مدير الدائرة', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(400, 50),
                            backgroundColor: const Color(0xff00408b),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget buildTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
          Flexible(child: Text(value, textAlign: TextAlign.left)),
        ],
      ),
    );
  }
}
