import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:FireWatch/My/InputDecoration.dart';

/// Text field with custom style used across the app
Widget buildCustomField({
  required String label,
  required TextEditingController controller,
}) {
  return Align(
    alignment: Alignment.center,
    child: Container(
      width: 400,
      child: TextField(
        controller: controller,
        decoration: customInputDecoration.copyWith(
          labelText: label,
          hintText: 'أدخل $label',
        ),
        textDirection: TextDirection.rtl,
      ),
    ),
  );
}

/// TypeAhead field for safety tool names
Widget buildToolSearchField({
  required List<String> toolNames,
  required TextEditingController controller,
  required void Function(String) onSelected,
}) {
  return Align(
    alignment: Alignment.center,
    child: Container(
      width: 400,
      child: TypeAheadField<String>(
        suggestionsCallback: (pattern) {
          return toolNames
              .where((name) =>
                  name.toLowerCase().contains(pattern.toLowerCase()))
              .toList();
        },
        textFieldConfiguration: TextFieldConfiguration(
          controller: controller,
          textDirection: TextDirection.rtl,
          decoration: customInputDecoration.copyWith(
            labelText: 'رمز أداة السلامة',
            hintText: 'أدخل رمز الأداة',
          ),
        ),
        itemBuilder: (context, String suggestion) {
          return ListTile(
            title: Text(suggestion, textDirection: TextDirection.rtl),
          );
        },
        onSuggestionSelected: (String suggestion) {
          controller.text = suggestion;
          onSelected(suggestion);
        },
        noItemsFoundBuilder: (context) =>
            const ListTile(title: Text('لم يتم العثور على نتائج')),
      ),
    ),
  );
}
