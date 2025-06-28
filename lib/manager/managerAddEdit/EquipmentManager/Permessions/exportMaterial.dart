// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:FireWatch/manager/managerAddEdit/EquipmentManager/Permessions/exportDetails.dart';

// class ExportRequestMaterialsPage extends StatefulWidget {
//   final String requestId;
//   final String technicianName;

//   const ExportRequestMaterialsPage({
//     Key? key,
//     required this.requestId,
//     required this.technicianName,
//   }) : super(key: key);

//   @override
//   State<ExportRequestMaterialsPage> createState() => _ExportRequestMaterialsPageState();
// }

// class _ExportRequestMaterialsPageState extends State<ExportRequestMaterialsPage> {
//   List<Map<String, dynamic>> items = [];
//   bool loading = true;

//   @override
//   void initState() {
//     super.initState();
//     _fetchItems();
//   }

//   Future<void> _fetchItems() async {
//     setState(() => loading = true);

//     final data = await Supabase.instance.client
//         .from('export_request_items')
//         .select()
//         .eq('request_id', widget.requestId);

//     setState(() {
//       items = List<Map<String, dynamic>>.from(data);
//       loading = false;
//     });
//   }

//   void _goToDetails() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => ExportRequestDetailsPage(requestId: widget.requestId),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Directionality(
//       textDirection: TextDirection.rtl,
//       child: Scaffold(
//         appBar: AppBar(
//           backgroundColor: const Color(0xff00408b),
//           title: Text('مواد ${widget.technicianName}', style: const TextStyle(color: Colors.white)),
//           iconTheme: const IconThemeData(color: Colors.white),
//         ),
//         body: loading
//             ? const Center(child: CircularProgressIndicator())
//             : Column(
//                 children: [
//                   const SizedBox(height: 16),
//                   const Text('المواد المطلوبة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//                   const SizedBox(height: 12),
//                   Expanded(
//                     child: ListView.builder(
//                       itemCount: items.length,
//                       itemBuilder: (context, index) {
//                         final item = items[index];
//                         return ListTile(
//                           leading: const Icon(Icons.construction),
//                           title: Text(item['material_name'] ?? ''),
//                           subtitle: Text('الإجراء: ${item['action_done'] ?? ''}'),
//                           onTap: _goToDetails,
//                         );
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//       ),
//     );
//   }
// }
