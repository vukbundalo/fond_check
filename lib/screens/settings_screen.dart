import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _licenceController = TextEditingController();
  final TextEditingController _orgIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _licenceController.text = prefs.getString('p_licence') ?? "";
      _orgIdController.text = prefs.getString('p_main_org_id') ?? "";
    });
  }

  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('p_licence', _licenceController.text);
    await prefs.setString('p_main_org_id', _orgIdController.text);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Settings saved!")),
    );
    Navigator.pop(context); // Return to the previous screen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _licenceController,
              decoration: const InputDecoration(labelText: "Licenca apoteke"),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _orgIdController,
              decoration: const InputDecoration(labelText: "Kod apoteke"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: saveSettings,
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }
}
