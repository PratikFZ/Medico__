// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';

String getLink() {
  String localhost = 'http://192.168.1.109:5000';
  return localhost;
}

void showError(String message, BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Error'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('OK'),
        )
      ],
    ),
  );
}
