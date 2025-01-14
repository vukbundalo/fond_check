import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class PrescriptionCard extends StatefulWidget {
  final dynamic item;
  final DateTime selectedDate;

  const PrescriptionCard(
      {required this.item, required this.selectedDate, super.key});

  @override
  State<PrescriptionCard> createState() => _PrescriptionCardState();
}

class _PrescriptionCardState extends State<PrescriptionCard> {
  final GlobalKey _repaintBoundaryKey = GlobalKey(); // Key for RepaintBoundary

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
      String fileExtension = asJson ? "json" : "txt";
      String data = asJson
          ? const JsonEncoder.withIndent('  ').convert(rawJson) // Pretty JSON
          : rawJson.entries
              .map((entry) => '"${entry.key}": ${entry.value}')
              .join('\n'); // Formatted TXT

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

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    "Podaci su uspiješno sačuvani u $fileExtension fajl!")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Greška pri čuvanju podataka: $e")),
        );
      }
    }
  }

  Future<void> saveAsImage() async {
    try {
      // Ensure the widget is completely rendered
      await Future.delayed(
          const Duration(milliseconds: 50)); // Add a small delay

      RenderRepaintBoundary boundary = _repaintBoundaryKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary;

      // Check if the widget still needs painting
      if (boundary.debugNeedsPaint) {
        await Future.delayed(
            const Duration(milliseconds: 50)); // Wait for paint
      }

      // Convert the boundary to an image
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) return;

      // Save the image to a file
      final buffer = byteData.buffer;
      String? filePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Sačuvaj podatke kao sliku',
        fileName:
            'recept_${widget.item["osiguranik_ime_prezime"]}_${widget.selectedDate.day}.${widget.selectedDate.month}.${widget.selectedDate.year}.png',
        type: FileType.custom,
        allowedExtensions: ['png'],
      );

      if (filePath != null) {
        final file = File(filePath);
        await file.writeAsBytes(buffer.asUint8List());

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Podaci su sačuvani kao slika!")),
          );
        }
      }
    } catch (e) {
      // Handle errors gracefully
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Greška pri čuvanju slike: $e")),
        );
      }
    }
  }

  Widget _hoverableText(String text, VoidCallback onTap) {
    bool isHovered = false;

    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return MouseRegion(
          onEnter: (_) {
            setState(() {
              isHovered = true;
            });
          },
          onExit: (_) {
            setState(() {
              isHovered = false;
            });
          },
          child: GestureDetector(
            onTap: onTap,
            child: Text(
              text,
              style: TextStyle(
                color: isHovered
                    ? Colors.blue.shade800.withValues(alpha: 20) // Hover color
                    : Colors.black.withAlpha(200), // Default text color
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: _repaintBoundaryKey, // Assign the RepaintBoundary key
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            height: 310,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left Column
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Pacijent: ${widget.item["osiguranik_ime_prezime"]} (${widget.item["osiguranik_jmb"]})",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.blue.shade900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text("Apoteka: ${widget.item["pj_apoteka"]}"),
                      const SizedBox(
                        height: 7,
                      ),
                      Text(
                          "Datum propisivanja: ${_formatDate(widget.item["recept_datum_izdavanaja"])}"),
                      const SizedBox(
                        height: 7,
                      ),
                      Text(
                          "Datum prodaje: ${_formatDate(widget.item["datum_izdavanaja_lijeka"])}"),
                      const SizedBox(
                        height: 7,
                      ),
                      Text("Fond šifra lijeka: ${widget.item["lijek_oznaka"]}"),
                      const SizedBox(
                        height: 7,
                      ),
                      Text(
                          "Lista lijeka: ${widget.item["lijek_lista_oznaka"]}"),
                      const SizedBox(
                        height: 7,
                      ),
                      Text(
                          "Dijagnoza: ${widget.item["recepet_dijagnoza_oznaka"]}"),
                      const SizedBox(
                        height: 7,
                      ),
                      Text("Fond plaća: ${widget.item["iznos"]}"),
                      const SizedBox(
                        height: 7,
                      ),
                      Text(
                        "Na teret fonda: ${widget.item["na_teret_fonda"] == "Y" ? "Da" : widget.item["na_teret_fonda"] == "N" ? "Ne" : "Nepoznato"}",
                      ),
                      const SizedBox(
                        height: 7,
                      ),
                      Text(
                          "Ljekar: ${widget.item["recept_ljekar_ime_prezima"]} (${widget.item["recept_ljekar_oznaka"]})"),
                      const SizedBox(
                        height: 7,
                      ),
                      Text(
                          "Farmaceut: ${widget.item["ime_i_prezime_farmaceuta"]} (${widget.item["izis_farmaceut_id"]})"),
                    ],
                  ),
                ),
                // Right Column
                // Right Column
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Podaci za ručni unos na kasi',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.blue.shade900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _hoverableText(
                        "Količina: ${widget.item["kolicina"]}",
                        () {
                          Clipboard.setData(ClipboardData(
                              text: "${widget.item["kolicina"]}"));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Količina je kopirana, podatak sada možete zalijepiti na Prokontik kasu.",
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 5),
                      _hoverableText(
                        "Vid osiguranja: ${widget.item["na_teret_fonda"] == "Y" && widget.item["participacija_placa"] == "N" ? "1" : widget.item["na_teret_fonda"] == "Y" && widget.item["participacija_placa"] == "D" ? "6" : widget.item["na_teret_fonda"] == "N" && widget.item["participacija_placa"] == "D" ? "-" : "Nepoznato"}",
                        () {
                          Clipboard.setData(ClipboardData(
                            text: widget.item["na_teret_fonda"] == "Y" &&
                                    widget.item["participacija_placa"] == "N"
                                ? "1"
                                : widget.item["na_teret_fonda"] == "Y" &&
                                        widget.item["participacija_placa"] ==
                                            "D"
                                    ? "6"
                                    : widget.item["na_teret_fonda"] == "N" &&
                                            widget.item[
                                                    "participacija_placa"] ==
                                                "D"
                                        ? "-"
                                        : "Nepoznato",
                          ));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Vid osiguranja je kopiran, podatak sada možete zalijepiti na Prokontik kasu.",
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 5),
                      _hoverableText(
                        "Broj recepta: ${widget.item["ihe_oznaka"]}",
                        () {
                          Clipboard.setData(ClipboardData(
                              text: "${widget.item["ihe_oznaka"]}"));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Broj recepta je kopiran, podatak sada možete zalijepiti na Prokontik kasu.",
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 5),
                      _hoverableText(
                        "EReceptId: ${widget.item["ihe_oznaka"].toString().split('.').last}",
                        () {
                          Clipboard.setData(ClipboardData(
                              text: widget.item["ihe_oznaka"]
                                  .toString()
                                  .split('.')
                                  .last));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "EReceptId je kopiran, podatak sada možete zalijepiti na Prokontik kasu.",
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 5),
                      _hoverableText(
                        "RecDokumentId: ${widget.item["ihe_oznaka_izdavanja"]}",
                        () {
                          Clipboard.setData(ClipboardData(
                              text: "${widget.item["ihe_oznaka_izdavanja"]}"));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "RecDokumentId je kopiran, podatak sada možete zalijepiti na Prokontik kasu.",
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 5),
                      _hoverableText(
                        "Osiguranik: ${widget.item["osiguranik_jmb"]}",
                        () {
                          Clipboard.setData(ClipboardData(
                              text: "${widget.item["osiguranik_jmb"]}"));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Osiguranik je kopiran, podatak sada možete zalijepiti na Prokontik kasu.",
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 5),
                      _hoverableText(
                        "Ime i prezime osiguranika: ${widget.item["osiguranik_ime_prezime"]}",
                        () {
                          Clipboard.setData(ClipboardData(
                              text:
                                  "${widget.item["osiguranik_ime_prezime"]}"));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Ime i prezime osiguranika je kopirano, podatak sada možete zalijepiti na Prokontik kasu.",
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 5),
                      _hoverableText(
                        "Zdravstvena ustanova: ${widget.item["recept_ustanova_sifra"]}",
                        () {
                          Clipboard.setData(ClipboardData(
                              text: "${widget.item["recept_ustanova_sifra"]}"));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Zdravstvena ustanova je kopirana, podatak sada možete zalijepiti na Prokontik kasu.",
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 5),
                      _hoverableText(
                        "Doktor: ${widget.item["recept_ljekar_oznaka"]}",
                        () {
                          Clipboard.setData(ClipboardData(
                              text: "${widget.item["recept_ljekar_oznaka"]}"));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Doktor je kopiran, podatak sada možete zalijepiti na Prokontik kasu.",
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 5),
                      _hoverableText(
                        "Dijagnoza: ${widget.item["recepet_dijagnoza_oznaka"]}",
                        () {
                          Clipboard.setData(ClipboardData(
                              text:
                                  "${widget.item["recepet_dijagnoza_oznaka"]}"));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Dijagnoza je kopirana, podatak sada možete zalijepiti na Prokontik kasu.",
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 5),
                      _hoverableText(
                        "Datum izdavanja recepta: ${_formatDate(widget.item["datum_izdavanaja_lijeka"])}",
                        () {
                          Clipboard.setData(ClipboardData(
                              text: _formatDate(
                                  widget.item["datum_izdavanaja_lijeka"])));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Datum izdavanja recepta je kopiran, podatak sada možete zalijepiti na Prokontik kasu.",
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                // Action Buttons Column
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize
                        .max, // Ensure the column tries to fill the available space
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.image),
                        onPressed: saveAsImage,
                        tooltip: "Sačuvaj recept kao sliku",
                      ),
                      IconButton(
                        icon: const Icon(Icons.text_snippet),
                        onPressed: () =>
                            saveRawJsonToFile(widget.item, asJson: false),
                        tooltip: "Sačuvaj recept kao tekst",
                      ),
                      IconButton(
                        icon: const Icon(Icons.save),
                        onPressed: () =>
                            saveRawJsonToFile(widget.item, asJson: true),
                        tooltip: "Sačuvaj recept kao .JSON",
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
