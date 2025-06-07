import 'package:flutter/material.dart';
import 'package:FireWatch/technician/placesDawry/Engineering.dart';
import 'package:FireWatch/technician/placesDawry/Medical.dart';
import 'package:FireWatch/technician/placesDawry/Outside.dart';
import 'package:FireWatch/technician/placesDawry/Services.dart';

class TechnicianDawriPage extends StatelessWidget {
  static const String technicianDawryRoute = 'technicianDawri';
  //Todo:if the Manager add a new place will added here
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Color(0xff00408b),
          title: Center(
            child: Text('دوري', style: TextStyle(color: Colors.white)),
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(30, 50, 30, 30),
          children: [
            buildTile(
              'هندسية',
              Icons.engineering,
              DawryEngineeringTech(),
              context,
            ),
            SizedBox(),
            buildTile(
              'طبية',
              Icons.local_hospital,
              DawryMedicalTech(),
              context,
            ),
            buildTile(
              'خدمات',
              Icons.room_service,
              DawryServicesTech(),
              context,
            ),
            buildTile(
              'مباني خارجية',
              Icons.location_city,
              DawryOutsideTech(),
              context,
            ),
            // buildTile('أخرى', Icons.more_horiz),
          ],
        ),
      ),
    );
  }

  Widget buildTile(
    String title,
    IconData icon,
    Widget destination,
    BuildContext context,
  ) {
    return ListTile(
      leading: Icon(icon, color: Color(0xff00408b)),
      title: Center(child: Text(title, style: TextStyle(fontSize: 20))),
      trailing: Icon(Icons.arrow_forward_ios, size: 18),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => destination),
        );
      },
    );
  }
}
