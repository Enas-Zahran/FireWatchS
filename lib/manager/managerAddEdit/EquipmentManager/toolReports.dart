import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ToolReportsPage extends StatefulWidget {
  final String toolId;

  const ToolReportsPage({super.key, required this.toolId});

  @override
  State<ToolReportsPage> createState() => _ToolReportsPageState();
}

class _ToolReportsPageState extends State<ToolReportsPage> {
  List<Map<String, dynamic>> reports = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    setState(() => loading = true);
    final data = await Supabase.instance.client
        .from('tool_reports')
        .select()
        .eq('tool_id', widget.toolId)
        .order('submitted_at', ascending: false);
    reports = List<Map<String, dynamic>>.from(data);
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تقارير الأداة'),
          backgroundColor: const Color(0xff00408b),
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : reports.isEmpty
                ? const Center(child: Text('لا توجد تقارير'))
                : ListView.builder(
                    itemCount: reports.length,
                    itemBuilder: (context, index) {
                      final report = reports[index];
                      return ListTile(
                        title: Text('الفني: ${report['submitted_by']}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('التاريخ: ${report['submitted_at'] ?? 'غير محدد'}'),
                            Text('التقرير: ${report['report_text']}'),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
