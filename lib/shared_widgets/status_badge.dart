import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({Key? key, required this.status}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor = Colors.white;

    switch (status.toLowerCase()) {
      case 'valid':
      case 'final':
        bgColor = Colors.green;
        break;
      case 'revisi':
      case 'banding':
        bgColor = Colors.orange;
        break;
      case 'pending':
      case 'submitted':
        bgColor = Colors.blue;
        break;
      default:
        bgColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}