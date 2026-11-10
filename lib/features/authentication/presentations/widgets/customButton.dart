import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// may it once for all app
/// GLOBAL Widget
///

class Custombutton extends StatelessWidget{
  final String txtbutton;
  final VoidCallback onPressed;

  const Custombutton({super.key, required this.txtbutton, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(onPressed: onPressed, child: Text(txtbutton));
  }
}