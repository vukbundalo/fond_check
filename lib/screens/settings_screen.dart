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
  final TextEditingController _passwordController = TextEditingController();

  bool _isAdmin = false; // To track if the user is authenticated as admin

  // List of pharmacies
  final List<Map<String, String>> pharmacies = [
    {
      "name": "Apoteka Kozara",
      "license": "83657FD3-4680-4532-A4D5-6F82C46C253A",
      "code": "4278"
    },
    {
      "name": "Apoteka Han Pijesak",
      "license": "D42600BB-4642-4CF4-D9F5-23232BB726F6",
      "code": "4171"
    },
    {
      "name": "Apoteka Državna Trebinje",
      "license": "933E3B08-2271-48C5-FE03-8D2EE1EBF102",
      "code": "4367"
    },
    {
      "name": "Apoteka Biljana",
      "license": "ABD0AC30-D343-41E6-8E98-2550CB5A3FAC",
      "code": "3918"
    },
    {
      "name": "Apoteka Tilija Mrkonjić Grad",
      "license": "EA288021-3FFB-43F4-449E-4F4C8DC5F0EA",
      "code": "4238"
    },
    {
      "name": "Apoteka Državna Modriča",
      "license": "4C97E425-1D46-42A9-4132-086620532C5B",
      "code": "4236"
    },
    {
      "name": "Apoteka Stjepanović Bijeljina",
      "license": "E4793C23-6867-4490-C4FA-FC37AE509A42",
      "code": "4038"
    },
    {
      "name": "Apoteka Higija Šipovo",
      "license": "58019919-E5DC-4406-48B7-D991B59792D3",
      "code": "4340"
    },
    {
      "name": "Apoteka Drenovik Nevesinje",
      "license": "E933B473-460B-46AC-D6E6-3E6DF2A11878",
      "code": "4247"
    },
    {
      "name": "Apoteka Petković Šamac",
      "license": "62867DC0-D616-42ED-8A9B-BB03629B504F",
      "code": "4336"
    },
    {
      "name": "Apoteka Vanja Šamac-Slatina",
      "license": "F14A353F-ED0A-4D52-F9FD-E6139E3DC353",
      "code": "4333"
    },
    {
      "name": "Apoteka Galen Trebinje",
      "license": "7E40E43B-D27C-4EF5-6753-59840484CDA0",
      "code": "4375"
    },
    {
      "name": "Apoteka S Farm Bijeljina",
      "license": "2FD4570C-C1A5-44CD-6524-EF6BA363EBE4",
      "code": "11081"
    },
    {
      "name": "Apoteka Povjerenje Lopare",
      "license": "1503182C-71A0-4A8B-9DD8-04169B22980C",
      "code": "10367"
    },
    {
      "name": "Apoteka Eskulap Farm",
      "license": "756E7EFE-C20A-4AAE-DAB4-6E6D25300261",
      "code": "10336"
    },
    {
      "name": "Apoteka E-Pharm Lukavica",
      "license": "5A5B3399-9A9C-415D-BP9C-24174388D954",
      "code": "4356"
    },
    {
      "name": "Apoteka Lijek Trebinje",
      "license": "031C2300-68B9-49AE-9C35-1C1A96854A08",
      "code": "4358"
    },
  ];

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return; // Ensure the widget is still in the tree
    setState(() {
      _licenceController.text = prefs.getString('p_licence') ?? "";
      _orgIdController.text = prefs.getString('p_main_org_id') ?? "";
    });
  }

  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('p_licence', _licenceController.text);
    await prefs.setString('p_main_org_id', _orgIdController.text);

    if (!mounted) return; // Ensure the widget is still in the tree
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Podešavanja sačuvana!")),
    );
    Navigator.pop(context); // Return to the previous screen
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
                if (_passwordController.text == "admin123") {
                  setState(() {
                    _isAdmin = true;
                  });
                  Navigator.pop(context); // Close the dialog
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
            const SizedBox(height: 32),
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
                const SizedBox(height: 32),
                if (!_isAdmin)
                  ElevatedButton(
                    onPressed: authenticateAdmin,
                    child: const Text("Prijavite se kao administrator"),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
