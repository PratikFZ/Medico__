// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';

void showError(String message, BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Error'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context, true);
          },
          child: Text('OK'),
        )
      ],
    ),
  );
  }
