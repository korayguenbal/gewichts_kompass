import 'package:flutter/material.dart';
import 'package:gewichts_kompass/Gewichtseintrag.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UserEingabe extends StatefulWidget {
  const UserEingabe({super.key});

  @override
  State<UserEingabe> createState() => _UserEingabeState();
}

class _UserEingabeState extends State<UserEingabe> {
  final _textController = TextEditingController();

  List<Gewichtseintrag> gewichtseintraege = [];
  double? anzeigeErgebnis;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _eintragBearbeiten(int index) {
    final editController = TextEditingController();

    editController.text = gewichtseintraege[index].gewicht.toString();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Eintrag bearbeiten"),
          content: TextField(
            controller: editController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
          ),
          actions: [
            TextButton(
              child: Text("Abbrechen"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),

            TextButton(
              child: Text("Speichern"),
              onPressed: () {
                final neuesGewicht = double.tryParse(editController.text);
                if (neuesGewicht != null) {
                  setState(() {
                    final bearbeiteterEintrag = Gewichtseintrag(
                      gewicht: neuesGewicht,
                      datum: gewichtseintraege[index].datum,
                    );

                    gewichtseintraege[index] = bearbeiteterEintrag;
                    _berechneVeraenderung();
                  });
                  _saveData();
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonText = prefs.getString('gewichts_daten');

    if (jsonText != null) {
      final listeAlsMaps = jsonDecode(jsonText) as List;
      final geladeneListe = listeAlsMaps
          .map((map) => Gewichtseintrag.fromJson(map))
          .toList();

      setState(() {
        gewichtseintraege = geladeneListe;
        _berechneVeraenderung();
      });
      print("Daten geladen!");
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final listeAlsMaps = gewichtseintraege.map((e) => e.toJson()).toList();
    final jsonText = jsonEncode(listeAlsMaps);
    await prefs.setString("gewichts_daten", jsonText);
    print("Daten gespeichert!");
  }

  void _berechneVeraenderung() {
    if (gewichtseintraege.length < 2) {
      setState(() {
        anzeigeErgebnis = null;
      });
      return;
    }

    final letzterEintrag = gewichtseintraege.last.gewicht;
    final anzahlTage = 7;
    final startpunkt = (gewichtseintraege.length > anzahlTage)
        ? (gewichtseintraege.length - anzahlTage)
        : 0;
    final letzteEintraege = gewichtseintraege.sublist(startpunkt);

    double summe = 0;
    for (var gewicht in letzteEintraege) {
      summe += gewicht.gewicht;
    }
    final durchschnitt = summe / letzteEintraege.length;
    final veraenderungInProzent =
        ((letzterEintrag - durchschnitt) / durchschnitt * 100);

    setState(() {
      anzeigeErgebnis = veraenderungInProzent;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _textController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: "Aktuelles Gewicht in kg",
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              final gewicht = double.tryParse(_textController.text);
              if (gewicht != null) {
                final neuerEintrag = Gewichtseintrag(
                  gewicht: gewicht,
                  datum: DateTime.now(),
                );
                setState(() {
                  gewichtseintraege.add(neuerEintrag);
                  _berechneVeraenderung();
                });
                _saveData();
                _textController.clear();
              }
            },
            child: Text("Speichern"),
          ),
          SizedBox(height: 24),
          Text(
            anzeigeErgebnis == null
                ? "Gib min. 2 Werte ein, um zu starten."
                : "Veränderung zum 7-Tage-Schnitt: ${anzeigeErgebnis!.toStringAsFixed(2)}%",
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: gewichtseintraege.length,
              itemBuilder: (context, index) {
                final reversedIndex = gewichtseintraege.length - 1 - index;
                final eintrag = gewichtseintraege[reversedIndex];

                return Dismissible(
                  key: ValueKey(eintrag.datum),

                  onDismissed: (direction) {
                    setState(() {
                      gewichtseintraege.removeAt(reversedIndex);
                      _berechneVeraenderung();
                    });
                    _saveData();

                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text("Eintrag gelöscht")));
                  },

                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Icon(Icons.delete, color: Colors.white),
                  ),

                  child: Card(
                    margin: EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      title: Text("${eintrag.gewicht} kg"),
                      subtitle: Text(
                        "${eintrag.datum.day}.${eintrag.datum.month}.${eintrag.datum.year}",
                      ),
                      onTap: () {
                        _eintragBearbeiten(reversedIndex);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
