import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'settings_screen.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  final String currentAppVersion = "1.0.0"; // Replace with your app's version

  String? pLicence;
  String? pMainOrgId;
  DateTime selectedDate = DateTime.now();
  List<dynamic> prescriptions = [];
  String searchQuery = "";
  bool isLoading = false; // Track loading state
  String errorMessage = ""; // Track error message
  String searchQueryCode = ""; // For searching by "Fond šifra lijeka"
  String searchQueryRecept = ""; // For searching by "broj recepta"

  // Add the pharmacy list to map licenses to their names
  final List<Map<String, String>> pharmacies = [
    {
      "name": "Apoteka Kozara",
      "license": "83657FD3-4680-4532-A4D5-6F82C46C253A"
    },
    {
      "name": "Apoteka Han Pijesak",
      "license": "D42600BB-4642-4CF4-D9F5-23232BB726F6"
    },
    {
      "name": "Apoteka Državna Trebinje",
      "license": "933E3B08-2271-48C5-FE03-8D2EE1EBF102"
    },
    {
      "name": "Apoteka Biljana",
      "license": "ABD0AC30-D343-41E6-8E98-2550CB5A3FAC"
    },
    {
      "name": "Apoteka Tilija Mrkonjić Grad",
      "license": "EA288021-3FFB-43F4-449E-4F4C8DC5F0EA"
    },
    {
      "name": "Apoteka Državna Modriča",
      "license": "4C97E425-1D46-42A9-4132-086620532C5B"
    },
    {
      "name": "Apoteka Stjepanović Bijeljina",
      "license": "E4793C23-6867-4490-C4FA-FC37AE509A42"
    },
    {
      "name": "Apoteka Higija Šipovo",
      "license": "58019919-E5DC-4406-48B7-D991B59792D3"
    },
    {
      "name": "Apoteka Drenovik Nevesinje",
      "license": "E933B473-460B-46AC-D6E6-3E6DF2A11878"
    },
    {
      "name": "Apoteka Petković Šamac",
      "license": "62867DC0-D616-42ED-8A9B-BB03629B504F"
    },
    {
      "name": "Apoteka Vanja Šamac-Slatina",
      "license": "F14A353F-ED0A-4D52-F9FD-E6139E3DC353"
    },
    {
      "name": "Apoteka Galen Trebinje",
      "license": "7E40E43B-D27C-4EF5-6753-59840484CDA0"
    },
    {
      "name": "Apoteka S Farm Bijeljina",
      "license": "2FD4570C-C1A5-44CD-6524-EF6BA363EBE4"
    },
    {
      "name": "Apoteka Povjerenje Lopare",
      "license": "1503182C-71A0-4A8B-9DD8-04169B22980C"
    },
    {
      "name": "Apoteka Eskulap Farm",
      "license": "756E7EFE-C20A-4AAE-DAB4-6E6D25300261"
    },
    {
      "name": "Apoteka E-Pharm Lukavica",
      "license": "5A5B3399-9A9C-415D-BP9C-24174388D954"
    },
    {
      "name": "Apoteka Lijek Trebinje",
      "license": "031C2300-68B9-49AE-9C35-1C1A96854A08"
    },
  ];

  @override
  void initState() {
    super.initState();
    loadSettings();
    checkForUpdates(); // Automatically check for updates on startup
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    loadSettings(); // Reload settings whenever the screen is rebuilt
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return; // Ensure the widget is still in the tree
    setState(() {
      pLicence = prefs.getString('p_licence') ?? "";
      pMainOrgId = prefs.getString('p_main_org_id') ?? "";
    });
  }

  Future<void> checkForUpdates() async {
    const String versionCheckUrl =
        "https://raw.githubusercontent.com/vukbundalo/fond_check/refs/heads/main/latest_version.json";

    try {
      // Fetch the latest version information
      final response = await http.get(Uri.parse(versionCheckUrl));
      if (response.statusCode == 200) {
        final Map<String, dynamic> latestVersionData =
            json.decode(response.body);

        // Parse version and download URL
        final String latestVersion = latestVersionData["version"];
        final String downloadUrl = latestVersionData["url"];

        // Compare versions
        if (latestVersion != currentAppVersion) {
          // Show dialog to notify the user about the update
          if (!mounted) return;
          showUpdateDialog(latestVersion, downloadUrl);
        }
      } else {
        throw Exception("Failed to fetch version data");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Provjera verzije nije uspijela: $e")),
        );
      }
    }
  }

  void showUpdateDialog(String latestVersion, String downloadUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Nova verzija dostupna"),
          content: Text(
            "Dostupna je nova verzija aplikacije ($latestVersion). "
            "Želite li preuzeti novu verziju?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: const Text("Kasnije"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                openUrl(
                    "https://github.com/vukbundalo/fond_check/releases/download/v1.0.0/fondCheck.zip");
              },
              child: const Text("Preuzmi"),
            ),
          ],
        );
      },
    );
  }

  Future<void> openUrl(String url) async {
    final Uri uri = Uri.parse(url); // Parse the URL into a Uri object
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication, // Specify launch mode
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ne mogu otvoriti URL: $url")),
      );
    }
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
                Text("Molimo prvo podesite licencu i kod u podešavanjima!"),
          ),
        );
      }
      return;
    }

    setState(() {
      isLoading = true; // Show loading indicator
      errorMessage = ""; // Reset error message
    });

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
          isLoading = false; // Hide loading indicator
        });
      } else {
        throw Exception("Učitavanje podataka nije uspijelo.");
      }
    } catch (e) {
      setState(() {
        isLoading = false; // Hide loading indicator
        errorMessage =
            "Konekcija sa serverom nije uspijela. Provjerite internet konekciju i pokušajte ponovo.";
      });
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
        dialogTitle: 'Sačuvaj podatke o receptu',
        fileName:
            'recept_${rawJson["osiguranik_ime_prezime"]}_${selectedDate.day}.${selectedDate.month}.${selectedDate.year}.$fileExtension',
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
                content:
                    Text("Podaci su uspiješno sačuvani .$fileExtension file!")),
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
    if (date == null || date.isEmpty) {
      return "Nepoznato"; // Handle null or empty dates
    }
    try {
      final parsedDate = DateTime.parse(date); // Parse the string to DateTime
      return DateFormat('dd.MM.yyyy').format(parsedDate); // Format the DateTime
    } catch (e) {
      return "Nepoznato"; // Handle invalid date formats
    }
  }

  // Helper function to get pharmacy name by license
  String? getPharmacyNameByLicense(String? license) {
    if (license == null || license.isEmpty) return null;
    for (final pharmacy in pharmacies) {
      if (pharmacy["license"] == license) {
        return pharmacy["name"];
      }
    }
    return "Nepoznata apoteka"; // Default if license doesn't match
  }

  @override
  Widget build(BuildContext context) {
    final filteredPrescriptions = prescriptions.where((item) {
      final nameMatch = item["osiguranik_ime_prezime"]
          .toString()
          .toLowerCase()
          .contains(searchQuery.toLowerCase());
      final codeMatch = item["lijek_oznaka"]
          .toString()
          .toLowerCase()
          .contains(searchQueryCode.toLowerCase());

      // Extract the number after the last dot in "ihe_oznaka"
      final iheMatch = item["ihe_oznaka"] != null
          ? item["ihe_oznaka"]
              .toString()
              .split('.')
              .last
              .contains(searchQueryRecept)
          : false;

      return nameMatch && codeMatch && iheMatch; // All conditions must be true
    }).toList();
    final pharmacyName =
        getPharmacyNameByLicense(pLicence); // Get pharmacy name
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
          ],
        ),
        centerTitle: true, // Center the title and subtitle
        backgroundColor:
            Colors.blue.shade900, // Dark blue background for pharmacy theme
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () async {
              // Navigate to the Settings Page
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
              // Reload settings after returning
              if (mounted) {
                await loadSettings();
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Recepti za datum: ${selectedDate.day}.${selectedDate.month}.${selectedDate.year}",
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (pLicence != null && pLicence!.isNotEmpty)
                  Text(
                    "$pharmacyName",
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
              ],
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
              decoration:
                  const InputDecoration(labelText: "Ime ili prezime pacijenta"),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(labelText: "Fond šifra lijeka"),
              onChanged: (value) {
                setState(() {
                  searchQueryCode = value;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(labelText: "Broj recepta"),
              onChanged: (value) {
                setState(() {
                  searchQueryRecept =
                      value; // Update search query for "broj recepta"
                });
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.blue))
                  : errorMessage.isNotEmpty
                      ? Center(
                          child: Text(
                            errorMessage,
                            style: const TextStyle(
                                fontSize: 18, color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : filteredPrescriptions.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Nema dostupnih recepata za prikaz.",
                                    style: TextStyle(
                                        fontSize: 18, color: Colors.grey),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    "Izaberite datum i kliknite na dugme \"Preuzmi recepte sa fond servera\".",
                                    style: TextStyle(
                                        fontSize: 18, color: Colors.grey),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    "Postarajte se da ste unijeli licencu i kod apoteke u podešavanjima programa (Kotačić u gornjem desnom uglu) ako to nikada do sada niste uradili.",
                                    style: TextStyle(
                                        fontSize: 18, color: Colors.grey),
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
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  color: Colors.lightBlue.shade50,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Pacijent: ${item["osiguranik_ime_prezime"]} (${item["osiguranik_jmb"]})",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: Colors.blueGrey,
                                              ),
                                            ),
                                            Text(
                                                "Apoteka: ${item["pj_apoteka"]}"),
                                            Text(
                                                "Datum propisivanja recepta: ${_formatDate(item["recept_datum_izdavanaja"])}"),
                                            Text(
                                                "Datum prodaje lijeka: ${_formatDate(item["datum_izdavanaja_lijeka"])}"),
                                            Text(
                                                "Fond šifra lijeka: ${item["lijek_oznaka"]}"),
                                            Text(
                                                "Lista lijeka: ${item["lijek_lista_oznaka"]}"),
                                            Text(
                                                "Dijagnoza: ${item["recepet_dijagnoza_oznaka"]}"),
                                            Text(
                                                "Količina: ${item["kolicina"]}"),
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.save),
                                            onPressed: () => saveRawJsonToFile(
                                                item,
                                                asJson: true),
                                            tooltip: "Save as JSON",
                                          ),
                                          IconButton(
                                            icon:
                                                const Icon(Icons.text_snippet),
                                            onPressed: () => saveRawJsonToFile(
                                                item,
                                                asJson: false),
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
