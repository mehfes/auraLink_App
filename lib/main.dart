import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

// ---------------------------------------------------------------------------
// AURALINK OS - MAIN ENTRY POINT
// ---------------------------------------------------------------------------
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
      ],
      child: const AuraLinkApp(),
    ),
  );
}

// ---------------------------------------------------------------------------
// THEME & CONSTANTS
// ---------------------------------------------------------------------------
class AppTheme {
  static const Color primaryColor = Color(0xFF1F48FF); // Electric Indigo
  static const Color backgroundColor = Color(0xFFF5F5F7);
  static const Color alarmColor = Color(0xFFB00020);
  static const Color cardColor = Colors.white;
  static const Color textColor = Color(0xFF1D1D1F);

  static TextStyle get titleStyle => GoogleFonts.saira(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textColor,
      );

  static TextStyle get valueStyle => GoogleFonts.saira(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        color: primaryColor,
      );

  static TextStyle get labelStyle => GoogleFonts.saira(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Colors.grey[600],
      );
}

class AuraLinkApp extends StatelessWidget {
  const AuraLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AuraLink OS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppTheme.primaryColor,
        scaffoldBackgroundColor: AppTheme.backgroundColor,
        textTheme: GoogleFonts.sairaTextTheme(),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: AppTheme.primaryColor,
          secondary: AppTheme.primaryColor,
        ),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

// ---------------------------------------------------------------------------
// APP STATE (VIEW MODEL + LOGIC)
// ---------------------------------------------------------------------------
class AppState extends ChangeNotifier {
  // MQTT Client
  MqttServerClient? client;
  bool isConnected = false;
  String connectionStatus = 'Disconnected';

  // Sensor Data (DHT22)
  // TR: ESP32'den gelen sıcaklık ve nem verileri
  double temperature = 24.0;
  double humidity = 45.0;

  // Actuator State (Servo)
  // TR: Perde kontrolü için servo pozisyonu (0-100%)
  double curtainPosition = 0.0; // 0.0 (Closed) - 1.0 (Open)

  // Energy
  double energyToday = 1.2; // kWh (Dummy/Calculated)

  // System Status
  // TR: Kırmızı Ekran (Red Screen) tetikleyicileri
  bool isFireAlarm = false;
  bool isEarthquakeAlarm = false;

  AppState() {
    _connectMqtt();
  }

  // MQTT Connection Logic
  Future<void> _connectMqtt() async {
    // TR: Halka açık test broker kullanıyoruz. Gerçekte cihaz IP'si olabilir.
    client = MqttServerClient('test.mosquitto.org', 'auralink_app_${Random().nextInt(1000)}');
    client!.port = 1883;
    client!.logging(on: false);
    client!.keepAlivePeriod = 20;
    client!.onDisconnected = _onDisconnected;
    client!.onConnected = _onConnected;
    client!.onSubscribed = _onSubscribed;

    final connMess = MqttConnectMessage()
        .withClientIdentifier('auralink_app_${Random().nextInt(1000)}')
        .withWillTopic('willtopic')
        .withWillMessage('My Will message')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    client!.connectionMessage = connMess;

    try {
      connectionStatus = 'Connecting...';
      notifyListeners();
      await client!.connect();
    } on Exception catch (e) {
      connectionStatus = 'Failed: $e';
      _disconnect();
    }

    if (client!.connectionStatus!.state == MqttConnectionState.connected) {
      isConnected = true;
      connectionStatus = 'Connected';
      notifyListeners();
      _subscribeToTopics();
    } else {
      _disconnect();
    }
  }

  void _disconnect() {
    client?.disconnect();
    isConnected = false;
    connectionStatus = 'Disconnected';
    notifyListeners();
  }

  void _onConnected() {
    print('MQTT Connected');
  }

  void _onDisconnected() {
    print('MQTT Disconnected');
    isConnected = false;
    connectionStatus = 'Disconnected';
    notifyListeners();
  }

  void _onSubscribed(String topic) {
    print('Subscribed to $topic');
  }

  void _subscribeToTopics() {
    if (client == null) return;

    // TR: Sensör verilerini dinle (Sıcaklık/Nem)
    client!.subscribe('auralink/sensor/dht22', MqttQos.atMostOnce);
    
    // TR: Alarm durumlarını dinle (Yangın/Deprem interrupts)
    client!.subscribe('auralink/alert', MqttQos.atLeastOnce);

    client!.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
      final MqttPublishMessage recMess = c![0].payload as MqttPublishMessage;
      final String pt =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      final String topic = c[0].topic;

      _handleMessage(topic, pt);
    });
  }

  void _handleMessage(String topic, String payload) {
    print('Received: $topic -> $payload');
    
    if (topic == 'auralink/sensor/dht22') {
      // Expected Format: {"temp": 24.5, "humidity": 60}
      try {
        final data = jsonDecode(payload);
        temperature = (data['temp'] as num).toDouble();
        humidity = (data['humidity'] as num).toDouble();
        notifyListeners();
      } catch (e) {
        print('Error parsing generic sensor data');
      }
    } else if (topic == 'auralink/alert') {
      // Critical Alerts
      if (payload.contains('FIRE_DETECTED')) {
        triggerFireAlarm();
      } else if (payload.contains('EARTHQUAKE_DETECTED')) {
        triggerEarthquakeAlarm();
      }
    }
  }

  // TR: Perde kontrolü için mesaj gönder
  void setCurtainPosition(double val) {
    // Connection Guard
    if (!isConnected) {
      notifyListeners(); // Force UI rebuild to snap back slider if driven by user gesture
      return; 
    }

    curtainPosition = val;
    notifyListeners();
    
    // MQTT Publish
    if (client != null) {
      final builder = MqttClientPayloadBuilder();
      // Simple protocol: SET:50 for 50%
      String command = 'SET:${(val * 100).toInt()}';
      if (val == 0) command = 'CLOSE';
      if (val == 1) command = 'OPEN';
      
      builder.addString(command);
      client!.publishMessage('auralink/control/servo', MqttQos.atMostOnce, builder.payload!);
    }
  }

  // Simulation / Testing Methods
  void triggerFireAlarm() {
    isFireAlarm = true;
    notifyListeners();
  }

  void triggerEarthquakeAlarm() {
    isEarthquakeAlarm = true;
    notifyListeners();
  }

  void dismissAlarm() {
    isFireAlarm = false;
    isEarthquakeAlarm = false;
    notifyListeners();
  }
}

// ---------------------------------------------------------------------------
// UI: MAIN SCREEN CONTROLLER
// ---------------------------------------------------------------------------
class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);

    // TR: Alarm durumu kontrolü - Red Screen önceliği
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
                    _buildCurtainControl(context, state),
                    const SizedBox(height: 20),
                    _buildEnergyCard(state),
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
            onPressed: () {},
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
          child: _StatCard(
            label: 'INDOOR TEMP',
            value: '${state.temperature.toStringAsFixed(1)}°C',
            icon: FontAwesomeIcons.temperatureHalf,
            isAlert: state.temperature > 30, // Example logic
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _StatCard(
            label: 'HUMIDITY',
            value: '${state.humidity.toStringAsFixed(0)}%',
            icon: FontAwesomeIcons.droplet,
            color: Colors.blueAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildCurtainControl(BuildContext context, AppState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
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
              Text('SMART CURTAIN', style: AppTheme.titleStyle.copyWith(fontSize: 20)),
              Icon(FontAwesomeIcons.windowMaximize, color: Colors.grey[400]),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Closed', style: AppTheme.labelStyle),
              Text('${(state.curtainPosition * 100).toInt()}%', 
                style: AppTheme.valueStyle.copyWith(fontSize: 24)),
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
              value: state.curtainPosition,
              onChanged: (val) => state.setCurtainPosition(val),
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

  Widget _buildEnergyCard(AppState state) {
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
              Text('${state.energyToday} kWh', 
                style: AppTheme.valueStyle.copyWith(color: Colors.greenAccent)),
            ],
          ),
          const Icon(FontAwesomeIcons.plugCircleBolt, color: Colors.greenAccent, size: 30),
        ],
      ),
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

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;
  final bool isAlert;

  const _StatCard({
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
        color: isAlert ? Colors.red.withOpacity(0.1) : AppTheme.cardColor,
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
            color: isAlert ? Colors.red : null
          )),
          Text(label, style: AppTheme.labelStyle),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// UI: RED SCREEN (EMERGENCY)
// ---------------------------------------------------------------------------
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
