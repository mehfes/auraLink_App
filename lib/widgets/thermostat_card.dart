import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme.dart';

class ThermostatCard extends StatelessWidget {

  final double currentTemp;
  final double targetTemp;
  final Function(double) onTargetChanged;

  const ThermostatCard({
    super.key,
    required this.currentTemp,
    required this.targetTemp,
    required this.onTargetChanged,
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
              const Icon(FontAwesomeIcons.temperatureHalf, color: AppTheme.primaryColor),
              Text('THERMOSTAT', style: AppTheme.labelStyle),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${currentTemp.toStringAsFixed(1)}°', 
                    style: AppTheme.valueStyle.copyWith(fontSize: 32, color: Theme.of(context).textTheme.bodyLarge?.color)),
                  Text('Current', style: AppTheme.labelStyle.copyWith(fontSize: 12)),
                ],
               ),
               Column(
                children: [
                  Text('${targetTemp.toStringAsFixed(1)}°', 
                    style: AppTheme.valueStyle.copyWith(
                      color: Colors.orange,
                      fontSize: 32
                    )),
                   Text('Target', style: AppTheme.labelStyle.copyWith(fontSize: 12)),
                ],
               )
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ControlBtn(icon: Icons.remove, onTap: () => onTargetChanged(targetTemp - 0.5)),
              _ControlBtn(icon: Icons.add, onTap: () => onTargetChanged(targetTemp + 0.5)),
            ],
          )
        ],
      ),
    );
  }
}

class _ControlBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ControlBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Theme.of(context).textTheme.bodyLarge?.color),
      ),
    );
  }
}
