import 'package:flutter/material.dart';
import 'package:FireWatch/My/InputDecoration.dart';
//Todo Logic for the button
class AddEmergencyPage extends StatefulWidget {
  static const String addEmergencyRoute = 'addEmergency';

  @override
  _AddEmergencyPageState createState() => _AddEmergencyPageState();
}

class _AddEmergencyPageState extends State<AddEmergencyPage> {
  final _formKey = GlobalKey<FormState>();
  final _toolCodeController = TextEditingController();
  final _areaCoveredController = TextEditingController();
  final _usageReasonController = TextEditingController();
  final _actionTakenController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Color(0xff00408b),
          title: Center(
            child: Text('إضافة طارئ', style: TextStyle(color: Colors.white)),
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
          
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Center(
                child: Column(
                  children: [
                    buildTextField(
                      controller: _toolCodeController,
                      label: 'رمز أداة السلامة',
                    ),
                    SizedBox(height: 16),
                    buildTextField(
                      controller: _areaCoveredController,
                      label: 'المساحة التي تم تغطيتها',
                    ),
                    SizedBox(height: 16),
                    buildTextField(
                      controller: _usageReasonController,
                      label: 'سبب الاستخدام',
                    ),
                    SizedBox(height: 16),
                    buildTextField(
                      controller: _actionTakenController,
                      label: 'الإجراء المتخذ',
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          // TODO: Add your submission logic
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('تمت الإضافة بنجاح')),
                          );
                        }
                      },
                      child: Text('إضافة', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(400, 50),
                        backgroundColor: Color(0xff00408b),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
  }) {
    return SizedBox(
      width: 400,
      child: TextFormField(
        controller: controller,
        decoration: customInputDecoration.copyWith(
          labelText: label,
          floatingLabelAlignment: FloatingLabelAlignment.start,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'الرجاء إدخال $label';
          }
          return null;
        },
        textAlign: TextAlign.right,
      ),
    );
  }
}
