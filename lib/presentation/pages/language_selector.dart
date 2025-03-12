import 'package:flutter/material.dart';


class LanguageSelectorScreen extends StatefulWidget {
  const LanguageSelectorScreen({super.key});

  @override
  _LanguageSelectorScreenState createState() => _LanguageSelectorScreenState();
}

class _LanguageSelectorScreenState extends State<LanguageSelectorScreen> {
  String? _selectedLanguage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
       // title: Text(AppLocalizations.of(context).title!),
        centerTitle: true,
      ),
      body: Center(
        child: DropdownButton<String>(
          hint: const Text('Select Language'),
          value: _selectedLanguage,
          onChanged: (String? newValue) {
            setState(() {
              _selectedLanguage = newValue;
              // Optionally, change the locale when a language is selected
              // This requires additional logic to change the app's locale
            });
          },
          items: <String>['English', 'Spanish']
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ),
    );
  }
}
