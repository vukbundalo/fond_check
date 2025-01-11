import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


class PrescriptionCard extends StatefulWidget {
  final dynamic item;
  
  final DateTime selectedDate;

  const PrescriptionCard({required this.item, required this.selectedDate, super.key});

  @override
  State<PrescriptionCard> createState() => _PrescriptionCardState();
}

class _PrescriptionCardState extends State<PrescriptionCard> {
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
            'recept_${rawJson["osiguranik_ime_prezime"]}_${widget.selectedDate.day}.${widget.selectedDate.month}.${widget.selectedDate.year}.$fileExtension',
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

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.lightBlue.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Pacijent: ${widget.item["osiguranik_ime_prezime"]} (${widget.item["osiguranik_jmb"]})",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.blueGrey,
                  ),
                ),
                Text("Apoteka: ${widget.item["pj_apoteka"]}"),
                Text(
                    "Datum propisivanja recepta: ${_formatDate(widget.item["recept_datum_izdavanaja"])}"),
                Text(
                    "Datum prodaje lijeka: ${_formatDate(widget.item["datum_izdavanaja_lijeka"])}"),
                Text("Fond šifra lijeka: ${widget.item["lijek_oznaka"]}"),
                Text("Lista lijeka: ${widget.item["lijek_lista_oznaka"]}"),
                Text("Dijagnoza: ${widget.item["recepet_dijagnoza_oznaka"]}"),
                Text("Količina: ${widget.item["kolicina"]}"),
                Text("Iznos koji plaća fond: ${widget.item["iznos"]}"),
                Text(
                  "Na teret fonda: ${widget.item["na_teret_fonda"] == "Y" ? "Da" : widget.item["na_teret_fonda"] == "N" ? "Ne" : "Nepoznato"}",
                ),
                Text(
                    "Ljekar: ${widget.item["recept_ljekar_ime_prezima"]} (${widget.item["recept_ljekar_oznaka"]})"),
                Text(
                    "Farmaceut: ${widget.item["ime_i_prezime_farmaceuta"]} (${widget.item["izis_farmaceut_id"]})"),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: () => saveRawJsonToFile(widget.item, asJson: true),
                tooltip: "Save as JSON",
              ),
              IconButton(
                icon: const Icon(Icons.text_snippet),
                onPressed: () => saveRawJsonToFile(widget.item, asJson: false),
                tooltip: "Save as TXT",
              ),
            ],
          ),
        ],
      ),
    );
  }
}
