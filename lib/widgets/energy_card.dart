import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme.dart';

class EnergyCard extends StatelessWidget {
  final double energyToday;

  const EnergyCard({super.key, required this.energyToday});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E), // Dark card for energy
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ENERGY TODAY', style: AppTheme.labelStyle.copyWith(color: Colors.white70)),
              const SizedBox(height: 5),
              Text('$energyToday kWh', 
                style: AppTheme.valueStyle.copyWith(color: Colors.greenAccent)),
            ],
          ),
          const Icon(FontAwesomeIcons.plugCircleBolt, color: Colors.greenAccent, size: 30),
        ],
      ),
    );
  }
}
