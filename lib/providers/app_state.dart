import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import '../services/logger_service.dart';

// ---------------------------------------------------------------------------
// APP STATE (VIEW MODEL + LOGIC)
// ---------------------------------------------------------------------------
class AppState extends ChangeNotifier {
  // MQTT Client
  MqttServerClient? client;
  bool isConnected = false;
  String connectionStatus = 'Disconnected';

  // Sensor Data (DHT22)
  double temperature = 24.0;
  double humidity = 45.0;

  // Actuator State (Servo)
  double curtainPosition = 0.0; // 0.0 (Closed) - 1.0 (Open)

  // Energy
  double energyToday = 1.2; // kWh (Dummy/Calculated)

  // System Status
  bool isFireAlarm = false;
  bool isEarthquakeAlarm = false;

  // Thermostat
  double targetTemperature = 22.0;

  // Settings
  bool isDarkMode = false;
  bool areNotificationsEnabled = true;
  String mqttBroker = 'test.mosquitto.org';
  int mqttPort = 1883;

  AppState({bool testMode = false}) {
    if (!testMode) {
      _connectMqtt();
    }
  }

  void toggleTheme(bool val) {
    LoggerService.log('User toggled theme. Dark Mode: $val');
    isDarkMode = val;
    notifyListeners();
  }

  void toggleNotifications(bool val) {
    LoggerService.log('User toggled notifications. Enabled: $val');
    areNotificationsEnabled = val;
    notifyListeners();
  }

  Future<void> updateMqttSettings(String newBroker, int newPort) async {
    LoggerService.log('User updated MQTT settings. Broker: $newBroker, Port: $newPort');
    mqttBroker = newBroker;
    mqttPort = newPort;
    notifyListeners();
    
    // Reconnect with new settings
    _disconnect();
    await _connectMqtt();
  }

  void setTargetTemperature(double val) {
    targetTemperature = val;
    // Clamp between reasonable limits
    if (targetTemperature < 16) targetTemperature = 16;
    if (targetTemperature > 30) targetTemperature = 30;
    LoggerService.log('User set target temperature to $targetTemperature');
    notifyListeners();
  }

  // MQTT Connection Logic
  Future<void> _connectMqtt() async {
    // Public test broker
    client = MqttServerClient(mqttBroker, 'auralink_app_${Random().nextInt(1000)}');
    client!.port = mqttPort;
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
    LoggerService.log('MQTT Connected');
  }

  void _onDisconnected() {
    LoggerService.log('MQTT Disconnected');
    isConnected = false;
    connectionStatus = 'Disconnected';
    notifyListeners();
  }

  void _onSubscribed(String topic) {
    LoggerService.log('Subscribed to $topic');
  }

  void _subscribeToTopics() {
    if (client == null) return;

    // Sensor Data
    client!.subscribe('auralink/sensor/dht22', MqttQos.atMostOnce);
    
    // Alarms
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
    LoggerService.log('Received Signal: $topic -> $payload');
    
    if (topic == 'auralink/sensor/dht22') {
      try {
        final data = jsonDecode(payload);
        temperature = (data['temp'] as num).toDouble();
        humidity = (data['humidity'] as num).toDouble();
        notifyListeners();
      } catch (e) {
        LoggerService.log('Error parsing generic sensor data');
      }
    } else if (topic == 'auralink/alert') {
      if (payload.contains('FIRE_DETECTED')) {
        triggerFireAlarm();
      } else if (payload.contains('EARTHQUAKE_DETECTED')) {
        triggerEarthquakeAlarm();
      }
    }
  }

  void setCurtainPosition(double val) {
    LoggerService.log('User set curtain position to $val');
    // Optimistic UI update - always update local state immediately
    curtainPosition = val;
    notifyListeners();
    
    // Only attempt MQTT if connected
    if (client != null && isConnected) {
      final builder = MqttClientPayloadBuilder();
      String command = 'SET:${(val * 100).toInt()}';
      if (val == 0) command = 'CLOSE';
      if (val == 1) command = 'OPEN';
      
      builder.addString(command);
      client!.publishMessage('auralink/control/servo', MqttQos.atMostOnce, builder.payload!);
    }
  }

  void triggerFireAlarm() {
    LoggerService.log('User triggered SIMULATED FIRE ALARM');
    isFireAlarm = true;
    notifyListeners();
  }

  void triggerEarthquakeAlarm() {
    LoggerService.log('User triggered SIMULATED EARTHQUAKE ALARM');
    isEarthquakeAlarm = true;
    notifyListeners();
  }

  void dismissAlarm() {
    LoggerService.log('User dismissed alarm');
    isFireAlarm = false;
    isEarthquakeAlarm = false;
    notifyListeners();
  }
}
