import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

class CurtainCard extends StatelessWidget {
  final double position;
  final Function(double) onPositionChanged;

  const CurtainCard({
    super.key,
    required this.position,
    required this.onPositionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('SMART CURTAIN', style: AppTheme.titleStyle.copyWith(
                fontSize: 20,
                color: Theme.of(context).textTheme.bodyLarge?.color
              )),
              Icon(FontAwesomeIcons.windowMaximize, color: Colors.grey[400]),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Closed', style: AppTheme.labelStyle),
              Text('${(position * 100).toInt()}%', 
                style: AppTheme.valueStyle.copyWith(
                  fontSize: 24,
                  color: Theme.of(context).textTheme.bodyLarge?.color
                )),
              Text('Open', style: AppTheme.labelStyle),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppTheme.primaryColor,
              inactiveTrackColor: Colors.grey[200],
              thumbColor: AppTheme.primaryColor,
              overlayColor: AppTheme.primaryColor.withOpacity(0.2),
              trackHeight: 12,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
            ),
            child: Slider(
              value: position,
              onChanged: onPositionChanged,
            ),
          ),
          Center(
            child: Text(
              'Servo Motor Control (PWM)',
              style: GoogleFonts.saira(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
