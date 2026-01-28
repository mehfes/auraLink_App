import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;
  final bool isAlert;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color,
    this.isAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isAlert ? Colors.red.withOpacity(0.1) : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: isAlert ? Border.all(color: Colors.red) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: isAlert ? Colors.red : (color ?? AppTheme.primaryColor)),
          const SizedBox(height: 15),
          Text(value, style: AppTheme.valueStyle.copyWith(
            color: isAlert ? Colors.red : Theme.of(context).textTheme.bodyLarge?.color
          )),
          Text(label, style: AppTheme.labelStyle),
        ],
      ),
    );
  }
}
