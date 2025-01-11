import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _licenceController = TextEditingController();
  final TextEditingController _orgIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isAdmin = false; // Track admin authentication

  // List of pharmacies
  final List<Map<String, String>> pharmacies = kPharmacies;
  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _licenceController.text = prefs.getString('p_licence') ?? "";
      _orgIdController.text = prefs.getString('p_main_org_id') ?? "";
    });
  }

  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('p_licence', _licenceController.text);
    await prefs.setString('p_main_org_id', _orgIdController.text);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Podešavanja sačuvana!")),
    );
    Navigator.pop(context);
  }

  Future<void> clearSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('p_licence');
    await prefs.remove('p_main_org_id');
    setState(() {
      _licenceController.text = "";
      _orgIdController.text = "";
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Licenca i kod apoteke su očišćeni!")),
    );
  }

  Future<void> authenticateAdmin() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Administrator Login"),
          content: TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: "Unesite šifru"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (_passwordController.text == "Kiklop357") {
                  setState(() {
                    _isAdmin = true;
                  });
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Pogrešna šifra!")),
                  );
                }
              },
              child: const Text("Potvrdi"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Podešavanja"),
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
            const SizedBox(height: 16),
            if (_isAdmin)
              DropdownButtonFormField<Map<String, String>>(
                decoration:
                    const InputDecoration(labelText: "Izaberite apoteku"),
                items: pharmacies.map((pharmacy) {
                  return DropdownMenuItem(
                    value: pharmacy,
                    child: Text(pharmacy["name"]!),
                  );
                }).toList(),
                onChanged: (selectedPharmacy) {
                  setState(() {
                    _licenceController.text = selectedPharmacy!["license"]!;
                    _orgIdController.text = selectedPharmacy["code"]!;
                  });
                },
              ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: saveSettings,
                  child: const Text("Sačuvaj"),
                ),
                ElevatedButton(
                  onPressed: clearSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: const Text(
                    "Obriši podatke",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            if (!_isAdmin)
              ElevatedButton(
                onPressed: authenticateAdmin,
                child: const Text("Prijavite se kao administrator"),
              ),
          ],
        ),
      ),
    );
  }
}
