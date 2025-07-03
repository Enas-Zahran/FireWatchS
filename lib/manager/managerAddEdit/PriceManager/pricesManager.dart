import 'package:flutter/material.dart';
import 'package:FireWatch/manager/managerAddEdit/PriceManager/tools/toolPriceList.dart';
import 'package:FireWatch/manager/managerAddEdit/PriceManager/companies/companiesList.dart';
import 'package:FireWatch/manager/managerAddEdit/PriceManager/maintenance/maintenancePriceList.dart';
class PriceDashboardPage extends StatelessWidget {
  static const routeName = '/price-dashboard';

  const PriceDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xff00408b),
          title: const Center(
            child: Text(
              'لوحة تحكم الأسعار',
              style: TextStyle(color: Colors.white),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(30, 30, 30, 30),
          children: [
            _buildTile(
              context,
              title: 'أدوات السلامة',
              icon: Icons.security,
              onTap: () {
              Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => ToolPricesListPage()),
);
              },
            ),
            const SizedBox(height: 12),
            _buildTile(
              context,
              title: 'الإجراء',
              icon: Icons.build,
              onTap: () {
                Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => MaintenancePricesListPage()),
);
     
                //MaintenancePricesListPage
                // TODO: Navigate to Action Prices Page
              },
            ),
            const SizedBox(height: 12),
            _buildTile(
              context,
              title: 'الشركة المنفذة',
              icon: Icons.apartment,
              onTap: () {
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => ExecutingCompanyListPage()),
);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 36,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}
