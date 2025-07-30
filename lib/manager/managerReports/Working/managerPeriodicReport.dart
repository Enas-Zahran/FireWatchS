import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import 'package:FireWatch/manager/managerReports/Working/fianlApprovedReports.dart';

class ManagerPeriodicReports extends StatefulWidget {
  const ManagerPeriodicReports({super.key});

  @override
  State<ManagerPeriodicReports> createState() => _ManagerPeriodicReportsState();
}

class _ManagerPeriodicReportsState extends State<ManagerPeriodicReports> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> allReports = [];
  List<Map<String, dynamic>> filteredReports = [];
  Map<String, String> toolLocations = {}; // tool_name => location_name
  Map<String, String> toolMaterialTypes = {}; // tool_name => material_type
  Map<String, String> toolCapacities = {}; // tool_name => capacity

  List<String> selectedToolTypes = [];
  List<String> selectedMaterials = [];
  List<String> selectedCapacities = [];
  List<String> selectedLocations = [];
  List<String> selectedTechnicians = [];
  List<String> selectedHeadNames = [];
  List<String> selectedProcedures = [];
  List<String> selectedDateRange = [];
  List<String> selectedValidityStatus = [];
  List<String> selectedCompanyReps = [];
  DateTime now = DateTime.now();

  final toolTypes = ['fire extinguisher', 'hose reel', 'fire hydrant'];

  List<String> locationNames = [];

  bool loading = true;

  @override
  void initState() {
    print('👀 initState triggered');
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    try {
      print('🚀 Starting _loadReports');

      final extinguisherReports = await supabase
          .from('fire_extinguisher_reports')
          .select()
          .eq('head_approved', true);

      print('✅ extinguisherReports: ${extinguisherReports.length}');

      final hydrantReports = await supabase
          .from('fire_hydrant_reports')
          .select()
          .eq('task_type', 'دوري')
          .eq('head_approved', true);

      print('✅ hydrantReports: ${hydrantReports.length}');

      final hoseReelReports = await supabase
          .from('hose_reel_reports')
          .select()
          .eq('task_type', 'دوري')
          .eq('head_approved', true);

      print('✅ hoseReelReports: ${hoseReelReports.length}');

      final tools = await supabase
          .from('safety_tools')
          .select('name, location_id, material_type, capacity');

      print('✅ tools: ${tools.length}');

      final locations = await supabase.from('locations').select('id, name');

      print('✅ locations: ${locations.length}');

      final locationMap = {for (var loc in locations) loc['id']: loc['name']};

      for (var tool in tools) {
        final name = tool['name'];
        final locationId = tool['location_id'];
        final material = tool['material_type'];

        if (name != null && locationId != null) {
          toolLocations[name] = locationMap[locationId] ?? 'غير معروف';
        }
        if (name != null && material != null) {
          toolMaterialTypes[name] = material;
        }
      }

      final combined = [
        ...extinguisherReports.map(
          (e) => {...e, 'tool_type': 'fire extinguisher'},
        ),
        ...hydrantReports.map((e) => {...e, 'tool_type': 'fire hydrant'}),
        ...hoseReelReports.map((e) => {...e, 'tool_type': 'hose reel'}),
      ];

      locationNames =
          toolLocations.values
              .toSet()
              .where((e) => e.trim().isNotEmpty)
              .toList();

      setState(() {
        allReports = combined.cast<Map<String, dynamic>>();
        filteredReports = List.from(allReports);
        loading = false;
      });

      print('✅ _loadReports completed successfully');
    } catch (e, stack) {
      print('❌ ERROR in _loadReports: $e');
      print('📌 STACK: $stack');
      setState(() => loading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      filteredReports =
          allReports.where((report) {
            final toolName = report['tool_name'] ?? '';
            final rawToolType = report['tool_type'];
            final toolType =
                rawToolType == 'fire extinguisher'
                    ? 'fire extinguisher'
                    : rawToolType == 'hose reel'
                    ? 'hose reel'
                    : rawToolType == 'fire hydrant'
                    ? 'fire hydrant'
                    : rawToolType;
            final material = (toolMaterialTypes[toolName] ?? '').trim();
            final location = toolLocations[toolName] ?? 'غير معروف';
            final technician = (report['technician_name'] ?? '').trim();
            final headName = (report['head_name'] ?? '').trim();

            final nextDate =
                DateTime.tryParse(report['next_inspection_date'] ?? '') ??
                DateTime(1900);
            final companyRep = (report['company_rep'] ?? '').trim();

            if (selectedToolTypes.isNotEmpty &&
                !selectedToolTypes.contains(toolType))
              return false;
            if (selectedMaterials.isNotEmpty &&
                !selectedMaterials.contains(material))
              return false;

            if (selectedLocations.isNotEmpty &&
                !selectedLocations.contains(location))
              return false;
            if (selectedTechnicians.isNotEmpty &&
                !selectedTechnicians.contains(technician))
              return false;
            if (selectedHeadNames.isNotEmpty &&
                !selectedHeadNames.contains(headName))
              return false;

            if (selectedCompanyReps.isNotEmpty &&
                !selectedCompanyReps.contains(companyRep))
              return false;

            return true;
          }).toList();
    });
  }

  Widget _buildCheckboxFilter({
    required String label,
    required List<String> options,
    required List<String> selectedValues,
    required void Function(bool?, String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ...options.map(
          (value) => CheckboxListTile(
            value: selectedValues.contains(value),
            onChanged: (checked) => onChanged(checked, value),
            title: Text(value),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Center(
            child: const Text(
              'تقارير الفحص الدوري المعتمدة',
              style: TextStyle(color: Colors.white),
            ),
          ),
          backgroundColor: const Color(0xff00408b),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            Builder(
              builder:
                  (context) => IconButton(
                    icon: const Icon(Icons.filter_list),
                    onPressed: () => Scaffold.of(context).openEndDrawer(),
                  ),
            ),
          ],
        ),
        endDrawer: Drawer(
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'الفلاتر',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                _buildCheckboxFilter(
                  label: 'نوع أداة السلامة',
                  options: toolTypes,
                  selectedValues: selectedToolTypes,
                  onChanged:
                      (c, v) => setState(
                        () =>
                            c!
                                ? selectedToolTypes.add(v)
                                : selectedToolTypes.remove(v),
                      ),
                ),

                _buildCheckboxFilter(
                  label: 'مكان العمل',
                  options: locationNames,
                  selectedValues: selectedLocations,
                  onChanged:
                      (c, v) => setState(
                        () =>
                            c!
                                ? selectedLocations.add(v)
                                : selectedLocations.remove(v),
                      ),
                ),
                _buildCheckboxFilter(
                  label: 'الفني',
                  options:
                      allReports
                          .map((e) => e['technician_name'] ?? '')
                          .toSet()
                          .where((e) => e.isNotEmpty)
                          .cast<String>()
                          .toList(),
                  selectedValues: selectedTechnicians,
                  onChanged:
                      (c, v) => setState(
                        () =>
                            c!
                                ? selectedTechnicians.add(v)
                                : selectedTechnicians.remove(v),
                      ),
                ),
                _buildCheckboxFilter(
                  label: 'رئيس الشعبة',
                  options:
                      allReports
                          .map((e) => e['head_name'] ?? '')
                          .toSet()
                          .where((e) => e.isNotEmpty)
                          .cast<String>()
                          .toList(),
                  selectedValues: selectedHeadNames,
                  onChanged:
                      (c, v) => setState(
                        () =>
                            c!
                                ? selectedHeadNames.add(v)
                                : selectedHeadNames.remove(v),
                      ),
                ),
                _buildCheckboxFilter(
                  label: 'مندوب الشركة',
                  options:
                      allReports
                          .map((e) => e['company_rep'] ?? '')
                          .toSet()
                          .where((e) => e.isNotEmpty)
                          .cast<String>()
                          .toList(),
                  selectedValues: selectedCompanyReps,
                  onChanged:
                      (c, v) => setState(
                        () =>
                            c!
                                ? selectedCompanyReps.add(v)
                                : selectedCompanyReps.remove(v),
                      ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    _applyFilters();
                    Navigator.pop(context);
                  },
                  child: const Text('تطبيق الفلاتر'),
                ),
                TextButton(
                  onPressed:
                      () => setState(() {
                        selectedToolTypes.clear();
                        selectedMaterials.clear();
                        selectedCapacities.clear();
                        selectedLocations.clear();
                        selectedTechnicians.clear();
                        selectedHeadNames.clear();
                        selectedProcedures.clear();
                        selectedCompanyReps.clear();
                        selectedDateRange.clear();
                        selectedValidityStatus.clear();
                        _applyFilters();
                      }),
                  child: const Text('إعادة تعيين'),
                ),
              ],
            ),
          ),
        ),
        body:
            loading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                  padding: const EdgeInsets.all(16),
                  child:
                      filteredReports.isEmpty
                          ? const Center(child: Text('لا يوجد تقارير'))
                          : ListView.builder(
                            itemCount: filteredReports.length,
                            itemBuilder: (context, index) {
                              final report = filteredReports[index];
                              final date =
                                  report['inspection_date'] != null
                                      ? DateFormat.yMMMd().format(
                                        DateTime.parse(
                                          report['inspection_date'],
                                        ),
                                      )
                                      : 'غير معروف';
                              final location =
                                  toolLocations[report['tool_name']] ??
                                  'غير معروف';
                              return Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: ListTile(
                                  title: Text(
                                    'الفني: ${report['technician_name'] ?? '---'}',
                                  ),
                                  subtitle: Text(
                                    '''رئيس الشعبة: ${report['head_name'] ?? '---'}
اسم الأداة: ${report['tool_name'] ?? '---'}
مكان العمل: $location
مندوب الشركة: ${report['company_rep'] ?? '---'}
تاريخ الفحص: $date''',
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => FinalApprovedReportPage(
                                              report: report,
                                            ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                ),
      ),
    );
  }
}
