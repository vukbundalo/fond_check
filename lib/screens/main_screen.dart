import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'settings_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/prescription_card.dart';

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
  bool isLoading = false;
  String errorMessage = "";
  String searchQueryCode = "";
  String searchQueryRecept = "";

  String? selectedPharmacy = "Sve apoteke"; // Default option
  List<String> pharmacyList = ["Sve apoteke"]; // Includes "Sve apoteke"

  @override
  void initState() {
    super.initState();
    loadSettings();
    checkForUpdates();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    loadSettings();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      pLicence = prefs.getString('p_licence') ?? "";
      pMainOrgId = prefs.getString('p_main_org_id') ?? "";

      // Reset pharmacy list and selected pharmacy
      prescriptions = [];
      pharmacyList = ["Sve apoteke"];
      selectedPharmacy = "Sve apoteke";
    });
  }

  Future<void> checkForUpdates() async {
    const String versionCheckUrl =
        "https://raw.githubusercontent.com/vukbundalo/fond_check/refs/heads/main/latest_version.json";

    try {
      final response = await http.get(Uri.parse(versionCheckUrl));
      if (response.statusCode == 200) {
        final Map<String, dynamic> latestVersionData =
            json.decode(response.body);
        final String latestVersion = latestVersionData["version"];
        final String downloadUrl = latestVersionData["url"];
        if (latestVersion != "1.0.0") {
          showUpdateDialog(latestVersion, downloadUrl);
        }
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
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Nova verzija dostupna"),
          content: Text(
            "Dostupna je nova verzija aplikacije ($latestVersion). Želite li preuzeti novu verziju?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (Navigator.of(dialogContext).canPop()) {
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text("Kasnije"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (Navigator.of(dialogContext).canPop()) {
                  Navigator.pop(dialogContext);
                }
                final Uri uri = Uri.parse(downloadUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text("Ne mogu otvoriti URL: $downloadUrl")),
                    );
                  }
                }
              },
              child: const Text("Preuzmi"),
            ),
          ],
        );
      },
    );
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
      isLoading = true;
      errorMessage = "";
    });

    final date =
        "${selectedDate.day}.${selectedDate.month}.${selectedDate.year}";
    final url =
        "http://fabis.eastcode.biz:51111/api/prescriptions?p_main_org_id=$pMainOrgId&p_date_from=$date&p_date_to=$date&p_licence=$pLicence";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body)["items"];
        setState(() {
          prescriptions = data;
          pharmacyList = ["Sve apoteke"] +
              prescriptions
                  .map((item) => item["pj_apoteka"] as String)
                  .toSet()
                  .toList();
          isLoading = false;
        });
      } else {
        throw Exception("Učitavanje podataka nije uspijelo.");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = "Konekcija sa serverom nije uspijela.";
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
    if (!mounted) return;
    if (pickedDate != null && pickedDate != selectedDate) {
      setState(() {
        selectedDate = pickedDate;
      });
      // Automatically fetch prescriptions after changing the date
      fetchPrescriptions();
    }
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
      final iheMatch = item["ihe_oznaka"] != null
          ? item["ihe_oznaka"]
              .toString()
              .split('.')
              .last
              .contains(searchQueryRecept)
          : false;
      final pharmacyMatch = selectedPharmacy == "Sve apoteke" ||
          item["pj_apoteka"] == selectedPharmacy;
      return nameMatch && codeMatch && iheMatch && pharmacyMatch;
    }).toList();

    final double ukupanIznosRecepta = filteredPrescriptions
        .where((item) => item["na_teret_fonda"] == "Y")
        .fold<double>(0.0, (sum, item) {
      final double iznos = double.tryParse(item["iznos"].toString()) ?? 0.0;
      return sum + iznos + 1.43;
    });

    final int brojUslugaIzdavanja = filteredPrescriptions
        .where((item) => item["na_teret_fonda"] == "Y")
        .length;

    const int brojUslugaOtapanja = 0;

    return Scaffold(
      // appBar: AppBar(
      //   actions: [
      //     IconButton(
      //       icon: const Icon(Icons.settings),
      //       onPressed: () async {
      //         await Navigator.push(
      //           context,
      //           MaterialPageRoute(builder: (context) => const SettingsScreen()),
      //         );
      //         await loadSettings();
      //       },
      //     ),
      //   ],
      // ),
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
                "FondCheck",
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
            const SizedBox(height: 16),
            Card(
              margin: const EdgeInsets.only(bottom: 16.0),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      "${selectedDate.day}.${selectedDate.month}.${selectedDate.year}",
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    prescriptions.isNotEmpty && pharmacyList.length == 2
                        ? // Only one pharmacy (plus "Sve apoteke")
                        Text(
                            pharmacyList.last,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          )
                        : DropdownButton<String>(
                            value: selectedPharmacy,
                            items: pharmacyList
                                .map((pharmacy) => DropdownMenuItem(
                                      value: pharmacy,
                                      child: Text(pharmacy),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedPharmacy = value;
                              });
                            },
                          ),
                    Text(
                      "Fond plaća: ${ukupanIznosRecepta.toStringAsFixed(2)} KM",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Izdavanja: $brojUslugaIzdavanja",
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Otapanja: $brojUslugaOtapanja",
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                        labelText: "Ime ili prezime pacijenta"),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: TextField(
                    decoration:
                        const InputDecoration(labelText: "Fond šifra lijeka"),
                    onChanged: (value) {
                      setState(() {
                        searchQueryCode = value;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: TextField(
                    decoration:
                        const InputDecoration(labelText: "Broj recepta"),
                    onChanged: (value) {
                      setState(() {
                        searchQueryRecept = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : errorMessage.isNotEmpty
                      ? Center(
                          child: Text(
                            errorMessage,
                            style: const TextStyle(color: Colors.red),
                          ),
                        )
                      : filteredPrescriptions.isEmpty
                          ? const Center(
                              child: Text("Nema dostupnih recepata."))
                          : ListView.builder(
                              itemCount: filteredPrescriptions.length,
                              itemBuilder: (context, index) {
                                final item = filteredPrescriptions[index];
                                return PrescriptionCard(
                                  item: item,
                                  selectedDate: selectedDate,
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FloatingActionButton(
            onPressed: fetchPrescriptions,
            tooltip: "Preuzmi recepte",
            child: const Icon(Icons.download),
          ),
          FloatingActionButton(
            onPressed: selectDate,
            tooltip: "Promjeni datum",
            child: const Icon(Icons.calendar_today),
          ),
        ],
      ),
    );
  }
}
