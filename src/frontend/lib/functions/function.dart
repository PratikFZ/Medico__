// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';

String getLink() {
  String localhost = 'https://9804-2409-40c2-105d-a9ca-7b47-5fbd-b674-680.ngrok-free.app';
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
