import 'package:flutter/material.dart';
import '../widgets/app_header.dart';
import '../widgets/app_drawer.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF2FA7A4);
    const Color bgColor = Color(0xFFF6F7F9);
    const Color textColor = Color(0xFF2C3E50);
    const Color secondaryTextColor = Color(0xFF8A97A5);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: const AppHeader(title: 'SETTINGS'),
      drawer: const AppDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSettingItem(Icons.person_outline, 'Profile Settings', 'Manage your account'),
          _buildSettingItem(Icons.store_outlined, 'Store Information', 'Customize your shop details'),
          _buildSettingItem(Icons.print_outlined, 'Printer Settings', 'Configure receipt printers'),
          _buildSettingItem(Icons.language_outlined, 'Language', 'Change app language'),
          _buildSettingItem(Icons.help_outline, 'Help & Support', 'Get assistance'),
          const SizedBox(height: 32),
          Center(
            child: TextButton(
              onPressed: () {},
              child: const Text(
                'LOGOUT', 
                style: TextStyle(
                  color: Colors.red, 
                  fontWeight: FontWeight.w700, 
                  letterSpacing: 1.5,
                  fontSize: 14,
                )
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(IconData icon, String title, String subtitle) {
    const Color textColor = Color(0xFF2C3E50);
    const Color secondaryTextColor = Color(0xFF8A97A5);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: textColor, size: 24),
        ),
        title: Text(
          title, 
          style: const TextStyle(fontWeight: FontWeight.w600, color: textColor, fontSize: 15)
        ),
        subtitle: Text(
          subtitle, 
          style: const TextStyle(color: secondaryTextColor, fontSize: 12)
        ),
        trailing: const Icon(Icons.chevron_right, size: 20, color: secondaryTextColor),
        onTap: () {},
      ),
    );
  }
}
