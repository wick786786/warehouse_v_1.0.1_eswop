import 'package:flutter/material.dart';

class LanguageDropdown extends StatefulWidget {
  final Function(Locale) onLanguageChange;

  const LanguageDropdown({super.key, required this.onLanguageChange});

  @override
  _LanguageDropdownState createState() => _LanguageDropdownState();
}

class _LanguageDropdownState extends State<LanguageDropdown> {
  String? _selectedLanguage;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: _selectedLanguage,
      hint: Text(
        'English',
        style: Theme.of(context).textTheme.bodySmall, // Use theme styling
      ),
      onChanged: (String? newValue) {
        setState(() {
          _selectedLanguage = newValue;
        });

        if (newValue == 'English') {
          widget.onLanguageChange(const Locale('en', 'US'));
        } else if (newValue == 'Spanish') {
          widget.onLanguageChange(const Locale('es', 'ES'));
        }
      },
      items: <String>['English', 'Spanish']
          .map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall, // Use theme styling
          ),
        );
      }).toList(),
      underline: Container(
        height: 2,
        color: Theme.of(context).colorScheme.primary, // Match theme color
      ),
      icon: Icon(
        Icons.language,
        color: Theme.of(context).colorScheme.primary, // Match theme color
      ),
    );
  }
}
