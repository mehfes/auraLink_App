import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../theme.dart';
import '../providers/app_state.dart';
import 'red_screen.dart';
import 'settings_screen.dart';

import '../services/logger_service.dart';

// Widgets
import '../widgets/stat_card.dart';
import '../widgets/thermostat_card.dart';
import '../widgets/curtain_card.dart';
import '../widgets/energy_card.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);

    // Alert Checks
    if (state.isFireAlarm) {
      return const RedScreen(type: AlertType.fire);
    }
    if (state.isEarthquakeAlarm) {
      return const RedScreen(type: AlertType.earthquake);
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildConnectionStatus(state),
                    const SizedBox(height: 20),
                    _buildQuickStats(state),
                    const SizedBox(height: 20),
                    // Curtain Control
                    CurtainCard(
                      position: state.curtainPosition,
                      onPositionChanged: (val) => state.setCurtainPosition(val),
                    ),
                    const SizedBox(height: 20),
                    // Energy
                    EnergyCard(energyToday: state.energyToday),
                    const SizedBox(height: 40),
                    _buildSimulationControls(context, state),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(FontAwesomeIcons.bolt, color: AppTheme.primaryColor),
              const SizedBox(width: 10),
              Text('AuraLink OS', style: AppTheme.titleStyle),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              LoggerService.log('User navigated to Settings');
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus(AppState state) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: state.isConnected ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            state.isConnected ? Icons.wifi : Icons.wifi_off,
            size: 16,
            color: state.isConnected ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Text(
            state.isConnected ? 'SYSTEM ONLINE' : 'OFFLINE',
            style: GoogleFonts.saira(
              fontWeight: FontWeight.bold,
              color: state.isConnected ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(AppState state) {
    return Row(
      children: [
        Expanded(
          child: ThermostatCard(
            currentTemp: state.temperature,
            targetTemp: state.targetTemperature,
            onTargetChanged: state.setTargetTemperature,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: StatCard(
            label: 'HUMIDITY',
            value: '${state.humidity.toStringAsFixed(0)}%',
            icon: FontAwesomeIcons.droplet,
            color: Colors.blueAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildSimulationControls(BuildContext context, AppState state) {
    return Column(
      children: [
        const Divider(),
        Text('SIMULATION MODE (DEMO)', style: AppTheme.labelStyle),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.local_fire_department, color: Colors.white),
              label: const Text('TEST FIRE'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              onPressed: () => state.triggerFireAlarm(),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.vibration, color: Colors.white),
              label: const Text('TEST QUAKE'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown,
                foregroundColor: Colors.white,
              ),
              onPressed: () => state.triggerEarthquakeAlarm(),
            ),
          ],
        ),
      ],
    );
  }
}
