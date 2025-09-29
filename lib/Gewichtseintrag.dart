import 'package:flutter/material.dart';
import 'dart:convert';

class Gewichtseintrag {
  final double gewicht;
  final DateTime datum;

  Gewichtseintrag({required this.gewicht, required this.datum});

  Map<String, dynamic> toJson() => {
    "gewicht": gewicht,
    "datum": datum.toIso8601String(),
  };

  factory Gewichtseintrag.fromJson(Map<String, dynamic> json) {
    return Gewichtseintrag(
      gewicht: json["gewicht"],
      datum: DateTime.parse(json["datum"]),
    );
  }
}
