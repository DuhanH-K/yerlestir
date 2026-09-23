import 'dart:math';

import 'package:flutter/material.dart';

Future<bool> parentalGate(BuildContext context, {bool english = false}) async {
  final random = Random.secure();
  final a = 11 + random.nextInt(9), b = 5 + random.nextInt(9);
  final input = TextEditingController();
  final passed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(english ? 'For grown-ups' : 'Ebeveyn Kontrolü'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            english
                ? 'Please solve to continue.'
                : 'Devam etmek için işlemi çözün.',
          ),
          const SizedBox(height: 15),
          Text(
            '$a × $b = ?',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          TextField(
            controller: input,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: english ? 'Answer' : 'Yanıt',
            ),
            onSubmitted: (value) =>
                Navigator.pop(context, int.tryParse(value) == a * b),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(english ? 'Cancel' : 'Vazgeç'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.pop(context, int.tryParse(input.text) == a * b),
          child: Text(english ? 'Continue' : 'Devam Et'),
        ),
      ],
    ),
  );
  // Dialog closing animation still references the controller briefly.
  Future<void>.delayed(const Duration(milliseconds: 400), input.dispose);
  return passed ?? false;
}
