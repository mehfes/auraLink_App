import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../providers/app_state.dart';

enum AlertType { fire, earthquake }

class RedScreen extends StatelessWidget {
  final AlertType type;

  const RedScreen({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context, listen: false);
    
    String title = type == AlertType.fire ? 'FIRE DETECTED' : 'EARTHQUAKE DETECTED';
    String sub = type == AlertType.fire 
        ? 'Smoke detected in Living Room. Evacuate immediately.' 
        : 'Seismic vibration detected. Drop, Cover, and Hold On.';
    IconData icon = type == AlertType.fire ? FontAwesomeIcons.fire : FontAwesomeIcons.houseCrack;

    return Scaffold(
      backgroundColor: AppTheme.alarmColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Pulsing Icon Animation would go here
                Icon(icon, size: 100, color: Colors.white),
                const SizedBox(height: 40),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.saira(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  sub,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.saira(
                    fontSize: 24,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 60),
                Text(
                  'SYSTEM HAS ACTIVATED EMERGENCY PROTOCOLS',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.saira(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.7),
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () => state.dismissAlarm(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.alarmColor,
                    ),
                    child: const Text('DISMISS ALARM (FALSE POSITIVE)', 
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
