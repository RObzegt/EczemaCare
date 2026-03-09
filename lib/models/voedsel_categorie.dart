import 'package:flutter/material.dart';

enum VoedselCategorie {
  drinken,
  ontbijt,
  lunch,
  diner,
  snack;

  String get naam {
    switch (this) {
      case VoedselCategorie.drinken:
        return 'Drinken';
      case VoedselCategorie.ontbijt:
        return 'Ontbijt';
      case VoedselCategorie.lunch:
        return 'Lunch';
      case VoedselCategorie.diner:
        return 'Diner';
      case VoedselCategorie.snack:
        return 'Snack';
    }
  }

  IconData get icoon {
    switch (this) {
      case VoedselCategorie.drinken:
        return Icons.local_drink;
      case VoedselCategorie.ontbijt:
        return Icons.wb_sunny;
      case VoedselCategorie.lunch:
        return Icons.wb_sunny_outlined;
      case VoedselCategorie.diner:
        return Icons.nights_stay;
      case VoedselCategorie.snack:
        return Icons.shopping_cart;
    }
  }

  Color get kleur {
    switch (this) {
      case VoedselCategorie.drinken:
        return Colors.blue;
      case VoedselCategorie.ontbijt:
        return Colors.orange;
      case VoedselCategorie.lunch:
        return Colors.amber;
      case VoedselCategorie.diner:
        return Colors.purple;
      case VoedselCategorie.snack:
        return Colors.green;
    }
  }
}
