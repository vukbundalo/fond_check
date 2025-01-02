import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  String? pLicence;
  String? pMainOrgId;
  DateTime selectedDate = DateTime.now();
  List<dynamic> prescriptions = [];
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return; // Ensure the widget is still in the tree
    setState(() {
      pLicence = prefs.getString('p_licence') ?? "";
      pMainOrgId = prefs.getString('p_main_org_id') ?? "";
    });
  }

  Future<void> fetchPrescriptions() async {
    if (pLicence == null || pMainOrgId == null || pLicence!.isEmpty || pMainOrgId!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please configure settings first!")),
        );
      }
      return;
    }

    final date = "${selectedDate.day}.${selectedDate.month}.${selectedDate.year}";
    final url =
        "http://fabis.eastcode.biz:51111/api/prescriptions?p_main_org_id=$pMainOrgId&p_date_from=$date&p_date_to=$date&p_licence=$pLicence";

    try {
      final response = await http.get(Uri.parse(url));
      if (!mounted) return; // Ensure the widget is still in the tree
      if (response.statusCode == 200) {
        setState(() {
          prescriptions = json.decode(response.body)["items"];
        });
      } else {
        throw Exception("Failed to load data");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  Future<void> selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (!mounted) return; // Ensure the widget is still in the tree
    if (pickedDate != null && pickedDate != selectedDate) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredPrescriptions = prescriptions
        .where((item) =>
            item["osiguranik_ime_prezime"]
                .toString()
                .toLowerCase()
                .contains(searchQuery.toLowerCase()) ||
            item["pj_apoteka"]
                .toString()
                .toLowerCase()
                .contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Prescriptions"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              // Navigate to the Settings Page
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
              if (mounted) {
                loadSettings(); // Reload settings after returning
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                ElevatedButton(
                  onPressed: selectDate,
                  child: const Text("Select Date"),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: fetchPrescriptions,
                  child: const Text("Fetch Data"),
                ),
              ],
            ),
            TextField(
              decoration: const InputDecoration(labelText: "Search"),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
            Expanded(
              child: ListView.builder(
                itemCount: filteredPrescriptions.length,
                itemBuilder: (context, index) {
                  final item = filteredPrescriptions[index];
                  return Card(
                    child: ListTile(
                      title: Text(item["osiguranik_ime_prezime"]),
                      subtitle: Text(
                          "Pharmacy: ${item["pj_apoteka"]}\nDate: ${item["datum_izdavanaja_lijeka"]}"),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
