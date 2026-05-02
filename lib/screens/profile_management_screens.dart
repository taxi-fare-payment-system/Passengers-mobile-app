import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ProfileSetupScreen extends StatelessWidget {
  const ProfileSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete Your Profile', style: TextStyle(color: Colors.black)), backgroundColor: Colors.white, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const CircleAvatar(radius: 50, backgroundColor: AppTheme.surfaceColor, child: Icon(Icons.add_a_photo_rounded, size: 40, color: AppTheme.primaryColor)),
            const SizedBox(height: 8),
            const Text('Upload Profile Photo', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            const TextField(decoration: InputDecoration(labelText: 'Full Name', hintText: 'Enter your full name')),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'Email Address', hintText: 'Enter your email')),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Default Payment Method'),
              items: ['Wallet', 'Telebirr', 'Card'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (v) {},
            ),
            const SizedBox(height: 48),
            ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Save & Continue')),
          ],
        ),
      ),
    );
  }
}

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile', style: TextStyle(color: Colors.black)), backgroundColor: Colors.white, elevation: 0, leading: const BackButton(color: Colors.black)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const CircleAvatar(radius: 50, backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=samuel')),
            const SizedBox(height: 8),
            TextButton(onPressed: () {}, child: const Text('Change Photo')),
            const SizedBox(height: 32),
            const TextField(decoration: InputDecoration(labelText: 'Full Name'), controller: TextEditingController(text: 'Samuel Abera')),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'Email'), controller: TextEditingController(text: 'samuel.a@example.com')),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'Phone Number', prefixText: '+251 '), controller: TextEditingController(text: '912345678'), readOnly: true),
            const SizedBox(height: 48),
            ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Save Changes')),
          ],
        ),
      ),
    );
  }
}
