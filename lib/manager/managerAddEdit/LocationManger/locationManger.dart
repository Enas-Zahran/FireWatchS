import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:FireWatch/manager/managerAddEdit/LocationManger/addLocation.dart';
import 'package:FireWatch/manager/managerAddEdit/LocationManger/editLocation.dart';
class LocationsPage extends StatefulWidget {
  const LocationsPage({super.key});

  @override
  State<LocationsPage> createState() => _LocationsPageState();
}

class _LocationsPageState extends State<LocationsPage> {
  List<Map<String, dynamic>> _locations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchLocations();
  }

  Future<void> _fetchLocations() async {
    final data = await Supabase.instance.client
        .from('locations')
        .select()
        .order('created_at');

    setState(() {
      _locations = List<Map<String, dynamic>>.from(data);
      _loading = false;
    });
  }

  Future<void> _deleteLocation(String id) async {
    final confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا المكان؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف')),
        ],
      ),
    );

    if (confirm == true) {
      await Supabase.instance.client.from('locations').delete().eq('id', id);
      _fetchLocations();
    }
  }

  void _goToAddLocation() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddLocationPage()),
    ).then((_) => _fetchLocations());
  }

  void _goToEditLocation(Map<String, dynamic> location) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditLocationPage(location: location)),
    ).then((_) => _fetchLocations());
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('لوحة تحكم الاماكن', style: TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xff00408b),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(onPressed: _goToAddLocation, icon: const Icon(Icons.add))
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: _locations.length,
                itemBuilder: (context, index) {
                  final location = _locations[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Text(location['name']),
                      subtitle: Text('الرمز: ${location['code']}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _goToEditLocation(location),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteLocation(location['id']),
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