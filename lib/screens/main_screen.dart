import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'settings_screen.dart';
import 'package:intl/intl.dart';

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

  Future<void> saveRawJsonToFile(dynamic rawJson,
      {required bool asJson}) async {
    try {
      // Format the JSON data
      String fileExtension = asJson ? "json" : "txt";
      String data = asJson
          ? const JsonEncoder.withIndent('  ').convert(rawJson) // Pretty JSON
          : rawJson.entries
              .map((entry) => '"${entry.key}": ${entry.value}')
              .join('\n'); // Formatted TXT

      // Open file picker for the user to choose the save location
      String? filePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Prescription Data',
        fileName:
            'prescription_${rawJson["osiguranik_ime_prezime"]}_${selectedDate.day}.${selectedDate.month}.${selectedDate.year}.$fileExtension',
        type: FileType.custom,
        allowedExtensions: [fileExtension],
      );

      if (filePath != null) {
        final file = File(filePath);
        await file.writeAsString(data);

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    "Raw data saved successfully as .$fileExtension file!")),
          );
        }
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving data: $e")),
        );
      }
    }
  }

  // Helper method to format the date:
  String _formatDate(String? date) {
    if (date == null || date.isEmpty)
      return "Nepoznato"; // Handle null or empty dates
    try {
      final parsedDate = DateTime.parse(date); // Parse the string to DateTime
      return DateFormat('dd.MM.yyyy').format(parsedDate); // Format the DateTime
    } catch (e) {
      return "Nepoznato"; // Handle invalid date formats
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Colors.blue, Colors.lightBlueAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: const Text(
                "FondCheck1.0",
                style: TextStyle(
                  fontSize: 24, // Larger font size for the title
                  fontWeight: FontWeight.bold, // Bold text for emphasis
                  fontFamily: 'Serif', // Elegant font
                  color: Colors.white, // Gradient applies here
                  letterSpacing: 1.5, // Slight letter spacing for premium feel
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(
                height: 4), // Small spacing between title and subtitle
            const Text(
              "Pregled elektronskih recepata koji su izdati u fond",
              style: TextStyle(
                fontSize: 14, // Smaller font size for subtitle
                fontWeight: FontWeight.w400, // Normal font weight
                color: Colors.white, // White color for subtitle
                letterSpacing: 1.0, // Slight letter spacing for readability
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
          ],
        ),
        centerTitle: true, // Center the title and subtitle
        backgroundColor:
            Colors.blue.shade900, // Dark blue background for pharmacy theme
        actions: [
          IconButton(
            icon: const Icon(
              Icons.settings,
              color: Colors.white,
            ),
            onPressed: () async {
              // Navigate to the Settings Page
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
              child: filteredPrescriptions.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Nema dostupnih recepata za prikaz.",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Izaberite datum i kliknite na dugme \"Preuzmi recepte sa fond servera\".",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Postarajte se da ste unijeli licencu i kod apoteke u podešavanjima programa (Kotačić u gornjem desnom uglu) ako to nikada do sada niste uradili.",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredPrescriptions.length,
                      itemBuilder: (context, index) {
                        final item = filteredPrescriptions[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Pacijent: ${item["osiguranik_ime_prezime"]} (${item["osiguranik_jmb"]})",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    ),
                                    Text("Apoteka: ${item["pj_apoteka"]}"),
                                    Text(
                                      "Datum propisivanja recepta: ${_formatDate(item["recept_datum_izdavanaja"])}",
                                    ),
                                    Text(
                                      "Datum prodaje lijeka: ${_formatDate(item["datum_izdavanaja_lijeka"])}",
                                    ),
                                    Text(
                                        "Fond šifra lijeka: ${item["lijek_oznaka"]}"),
                                    Text(
                                        "Lista lijeka: ${item["lijek_lista_oznaka"]}"),
                                    Text(
                                        "Dijagnoza: ${item["recepet_dijagnoza_oznaka"]}"),
                                    Text("Količina: ${item["kolicina"]}"),
                                    Text(
                                        "Iznos koji plaća fond: ${item["iznos"]}"),
                                    Text(
                                      "Na teret fonda: ${item["na_teret_fonda"] == "Y" ? "Da" : item["na_teret_fonda"] == "N" ? "Ne" : "Nepoznato"}",
                                    ),
                                    Text(
                                        "Ljekar: ${item["recept_ljekar_ime_prezima"]} (${item["recept_ljekar_oznaka"]})"),
                                    Text(
                                        "Farmaceut: ${item["ime_i_prezime_farmaceuta"]} (${item["izis_farmaceut_id"]})"),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.save),
                                    onPressed: () =>
                                        saveRawJsonToFile(item, asJson: true),
                                    tooltip: "Save as JSON",
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.text_snippet),
                                    onPressed: () =>
                                        saveRawJsonToFile(item, asJson: false),
                                    tooltip: "Save as TXT",
                                  ),
                                ],
                              ),
                            ],
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
