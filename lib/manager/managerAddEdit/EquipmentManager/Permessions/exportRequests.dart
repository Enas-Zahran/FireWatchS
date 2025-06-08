import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:FireWatch/manager/managerAddEdit/EquipmentManager/Permessions/exportMaterial.dart';

class ExportRequestsPage extends StatefulWidget {
  static const routeName = '/export-requests';

  @override
  State<ExportRequestsPage> createState() => _ExportRequestsPageState();
}

class _ExportRequestsPageState extends State<ExportRequestsPage> {
  List<Map<String, dynamic>> requests = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    setState(() => loading = true);
    final data = await Supabase.instance.client
        .from('export_requests')
        .select()
        .order('created_at', ascending: false);

    setState(() {
      requests = List<Map<String, dynamic>>.from(data);
      loading = false;
    });
  }

  Future<void> _deleteRequest(String id) async {
    await Supabase.instance.client
        .from('export_requests')
        .delete()
        .eq('id', id);
    _fetchRequests();
  }

  void _goToMaterials(String requestId, String technicianName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExportRequestMaterialsPage(
          requestId: requestId,
          technicianName: technicianName,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(String requestId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 50),
                const SizedBox(height: 16),
                const Text(
                  'تأكيد الحذف',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'هل أنت متأكد أنك تريد حذف هذا الطلب؟',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.grey[600],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('إلغاء'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('حذف'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirm == true) {
      await _deleteRequest(requestId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xff00408b),
          title: const Text(
            'طلبات إخراج المواد',
            style: TextStyle(color: Colors.white),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final req = requests[index];
                  return Card(
                    margin: const EdgeInsets.all(12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ExportRequestMaterialsPage(
                              requestId: req['id'],
                              technicianName: req['technician_name'],
                            ),
                          ),
                        );
                      },
                      title: Text(req['technician_name'] ?? ''),
                      subtitle: Text(
                        'تاريخ الطلب: ${req['created_at']?.toString().substring(0, 10)}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () => _goToMaterials(
                              req['id'],
                              req['technician_name'],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _confirmDelete(req['id']),
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
