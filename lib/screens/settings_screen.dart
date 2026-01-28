import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../providers/app_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Settings', style: AppTheme.titleStyle.copyWith(
          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, 
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
          _SectionHeader(title: 'GENERAL'),
          _SettingsTile(
            icon: Icons.dark_mode,
            title: 'Dark Mode',
            trailing: Switch(
              value: state.isDarkMode, 
              onChanged: (val) => state.toggleTheme(val)
            ),
            onTap: () => state.toggleTheme(!state.isDarkMode),
          ),
          _SettingsTile(
            icon: Icons.notifications,
            title: 'Notifications',
            trailing: Switch(
              value: state.areNotificationsEnabled, 
              onChanged: (val) => state.toggleNotifications(val)
            ), 
          ),
          
          _SectionHeader(title: 'CONNECTION'),
          _SettingsTile(
            icon: Icons.cloud,
            title: 'MQTT Broker',
            subtitle: state.mqttBroker,
            onTap: () => _showBrokerDialog(context, state),
          ),
          _SettingsTile(
            icon: Icons.router,
            title: 'Port',
            subtitle: state.mqttPort.toString(),
            onTap: () => _showPortDialog(context, state),
          ),

          _SectionHeader(title: 'ABOUT'),
          _SettingsTile(
            icon: Icons.info,
            title: 'Version',
            subtitle: '1.0.0 (Alpha)',
          ),
          _SettingsTile(
            icon: Icons.code,
            title: 'Developers',
            subtitle: 'Mehmet Efe Sak & Mehmet Kaan Asdemir',
          ),
        ],
      ),
    );
  }

  void _showBrokerDialog(BuildContext context, AppState state) {
    final controller = TextEditingController(text: state.mqttBroker);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('MQTT Broker'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'e.g. test.mosquitto.org'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              state.updateMqttSettings(controller.text, state.mqttPort);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showPortDialog(BuildContext context, AppState state) {
    final controller = TextEditingController(text: state.mqttPort.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('MQTT Port'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'e.g. 1883'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final port = int.tryParse(controller.text) ?? 1883;
              state.updateMqttSettings(state.mqttBroker, port);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey[600],
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : AppTheme.cardColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primaryColor),
        ),
        title: Text(title, style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black87,
        )),
        subtitle: subtitle != null ? Text(subtitle!, style: TextStyle(
          color: isDark ? Colors.white70 : Colors.grey[600],
        )) : null,
        trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
