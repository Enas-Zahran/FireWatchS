import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PendingEmergencyRequestsPage extends StatefulWidget {
  static const String routeName = 'pendingEmergencyRequestsPage';

  const PendingEmergencyRequestsPage({super.key});

  @override
  State<PendingEmergencyRequestsPage> createState() => _PendingEmergencyRequestsPageState();
}

class _PendingEmergencyRequestsPageState extends State<PendingEmergencyRequestsPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> requests = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => isLoading = true);
    try {
      // Join user name from users table using created_by field
      final data = await supabase
          .from('emergency_requests')
          .select('*, users:created_by(name)')
          .eq('is_approved', false)
          .neq('created_by_role', 'المدير');

      setState(() {
        requests = List<Map<String, dynamic>>.from(data);
        isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل تحميل الطلبات: $e')),
      );
      setState(() => isLoading = false);
    }
  }

  Future<void> _approveRequest(String id) async {
    await supabase.from('emergency_requests').update({'is_approved': true}).eq('id', id);
    _loadRequests();
  }

  Future<void> _deleteRequest(String id) async {
    await supabase.from('emergency_requests').delete().eq('id', id);
    _loadRequests();
  }

  void _showDeleteDialog(String id) {
    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('تأكيد الرفض'),
            content: const Text('هل أنت متأكد أنك تريد رفض هذا الطلب؟ سيتم حذفه نهائياً.'),
            actions: [
              TextButton(
                child: const Text('إلغاء'),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: const Text('نعم، احذف'),
                onPressed: () {
                  Navigator.pop(context);
                  _deleteRequest(id);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Center(
            child: Text('الطلبات المعلقة', style: TextStyle(color: Colors.white)),
          ),
          backgroundColor: const Color(0xff00408b),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : requests.isEmpty
                  ? const Center(child: Text('لا توجد طلبات حالياً'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: requests.length,
                      itemBuilder: (context, index) {
                        final req = requests[index];
                        final isTaree = req['task_type'] == 'طارئ';
      
                        return Center(
                          child: Container(
                            width: 400,
                            margin: const EdgeInsets.only(bottom: 20),
                            child: Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      req['task_type'] ?? 'غير محدد',
                                      style: TextStyle(
                                        color: req['task_type'] == 'طارئ' ? Colors.red : Colors.orange,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _info('اسم الفني', req['users']?['name']),
                                    _info('اسم الأداة', req['tool_code']),
                                    if (isTaree && req['covered_area'] != '-')
                                      _info('المساحة التي تمت تغطيتها', req['covered_area']),
                                    _info('سبب الاستخدام / الخلل', req['usage_reason']),
                                    _info('الإجراء المتخذ', req['action_taken']),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        ElevatedButton(
                                          onPressed: () => _approveRequest(req['id']),
                                          child: const Text('موافقة'),
                                        ),
                                        OutlinedButton(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.red,
                                          ),
                                          onPressed: () => _showDeleteDialog(req['id']),
                                          child: const Text('رفض'),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ),
    );
  }

  Widget _info(String title, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black),
          children: [
            TextSpan(text: '$title: ', style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value ?? '-'),
          ],
        ),
      ),
    );
  }
}
