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
    if (pLicence == null ||
        pMainOrgId == null ||
        pLicence!.isEmpty ||
        pMainOrgId!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text("Molimo prvo podesite licencu i kod u podešavanjima!")),
        );
      }
      return;
    }

    final date =
        "${selectedDate.day}.${selectedDate.month}.${selectedDate.year}";
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
        throw Exception("Učitavanje podataka nije uspijelo.");
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
        title: const Text("Recepti izdati u fond"),
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
            // Show the selected date
            Text(
              "Recepti za datum: ${selectedDate.day}.${selectedDate.month}.${selectedDate.year}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: selectDate,
                  child: const Text("Promjeni datum"),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: fetchPrescriptions,
                  child: const Text("Preuzmi recepte sa fond servera"),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                  labelText: "Pretraži po imenu i prezimenu pacijenta"),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: filteredPrescriptions.length,
                itemBuilder: (context, index) {
                  final item = filteredPrescriptions[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Pacijent: ${item["osiguranik_ime_prezime"]} (${item["osiguranik_jmb"]})",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                              "Apoteka u kojoj je recept izdat: ${item["pj_apoteka"]}"),
                          Text(
                              "Datum propisivanja recepta: ${item["recept_datum_izdavanaja"]}"),
                          Text("Fond šifra lijeka: ${item["lijek_oznaka"]}"),
                          Text(
                              "Fond lista lijeka: ${item["lijek_lista_oznaka"]}"),
                          Text(
                              "Dijagnoza: ${item["recepet_dijagnoza_oznaka"]}"),
                          Text("Količina: ${item["kolicina"]}"),
                          Text("Iznos: ${item["iznos"]}"),
                          Text(
                              "Da li je na teret fonda?: ${item["na_teret_fonda"]}"),
                          Text(
                              "Ljekar koji je propisao recept: ${item["recept_ljekar_ime_prezima"]}"),
                          Text(
                              "Farmaceut: ${item["ime_i_prezime_farmaceuta"]} (${item["izis_farmaceut_id"]})"),
                        ],
                      ),
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
