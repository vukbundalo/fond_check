import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
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
          title: const Text("Prijava Administratora"),
          content: TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: "Unesite šifru"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (_passwordController.text == "1234abcD") {
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
          crossAxisAlignment: CrossAxisAlignment.start,
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.blue.shade900, // Button background color
                  ),
                  child: const Text(
                    "Sačuvaj",
                    style: TextStyle(color: Colors.white), // Text color
                  ),
                ),
                ElevatedButton(
                  onPressed: clearSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.red, // Red background for the delete button
                  ),
                  child: const Text(
                    "Obriši podatke",
                    style: TextStyle(color: Colors.white), // Text color
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            if (!_isAdmin)
              Center(
                child: ElevatedButton(
                  onPressed: authenticateAdmin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.blue.shade900, // Button background color
                  ),
                  child: const Text(
                    "Prijavite se kao administrator",
                    style: TextStyle(color: Colors.white), // Text color
                  ),
                ),
              ),
            const Spacer(),
            const Divider(),
            Center(
              child: InkWell(
                onTap: () async {
                  const url =
                      'https://github.com/vukbundalo'; // Replace with your GitHub link
                  if (await canLaunchUrl(Uri.parse(url))) {
                    await launchUrl(Uri.parse(url),
                        mode: LaunchMode.externalApplication);
                  } else {
                    throw 'Could not launch $url';
                  }
                },
                child: Text(
                  'Developed by Vuk Bundalo',
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.blue.shade900, // Blue for link appearance
                    decoration:
                        TextDecoration.none, // No underline for emphasis
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
