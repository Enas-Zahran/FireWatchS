import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ToolActionsPage extends StatefulWidget {
  final String toolId;

  const ToolActionsPage({super.key, required this.toolId});

  @override
  State<ToolActionsPage> createState() => _ToolActionsPageState();
}

class _ToolActionsPageState extends State<ToolActionsPage> {
  List<Map<String, dynamic>> actions = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchActions();
  }

  Future<void> _fetchActions() async {
    setState(() => loading = true);
    final data = await Supabase.instance.client
        .from('tool_actions')
        .select()
        .eq('tool_id', widget.toolId)
        .order('performed_at', ascending: false);
    actions = List<Map<String, dynamic>>.from(data);
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الإجراءات على الأداة'),
          backgroundColor: const Color(0xff00408b),
            leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : actions.isEmpty
                ? const Center(child: Text('لا توجد إجراءات'))
                : ListView.builder(
                    itemCount: actions.length,
                    itemBuilder: (context, index) {
                      final action = actions[index];
                      return ListTile(
                        title: Text('الإجراء: ${action['action_type']}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('التاريخ: ${action['performed_at'] ?? 'غير محدد'}'),
                            Text('الفني: ${action['performed_by']}'),
                            if (action['notes'] != null)
                              Text('ملاحظات: ${action['notes']}'),
                          ],
                        ),
                        trailing: Text('${action['cost'] ?? 0} د.أ'),
                      );
                    },
                  ),
      ),
    );
  }
}
