import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'write_page.dart';

class ProfilePage extends StatefulWidget {
  final String uid; // User's UID passed after login

  const ProfilePage({super.key, required this.uid});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  // Function to save profile details in Firestore
  Future<void> _saveProfileDetails() async {
    try {
      final profileData = {
        'Full Name': _nameController.text.trim(),
        'Email': _emailController.text.trim(),
        'Phone': _phoneController.text.trim(),
        'Age': _ageController.text.trim(),
        'Updated At': FieldValue.serverTimestamp(), // Timestamp for tracking updates
      };

      // Save profile data to Firestore
      await FirebaseFirestore.instance
          .collection('user_profiles') // Collection name: user_profiles
          .doc(widget.uid) // Use UID as the document ID
          .set(profileData, SetOptions(merge: true)); // Merge to allow updates

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile details saved successfully!')),
      );

      // Navigate to the WritePage and pass the profile data
      Navigator.push(
        context,
          MaterialPageRoute(
            builder: (context) => WritePage(
              profileData: {
                'UID' : widget.uid,
              },
            )

      ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving profile: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile Page'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Full Name'),
                maxLength: 30,
                validator: (value) =>
                value == null || value.isEmpty ? 'Please enter your full name' : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                maxLength: 40,
                validator: (value) =>
                value == null || value.isEmpty ? 'Please enter your email' : null,
              ),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(labelText: 'Phone'),
                maxLength: 15,
                validator: (value) =>
                value == null || value.isEmpty ? 'Please enter your phone number' : null,
              ),
              TextFormField(
                controller: _ageController,
                decoration: InputDecoration(labelText: 'Age'),
                maxLength: 3,
                validator: (value) =>
                value == null || value.isEmpty ? 'Please enter your age' : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _saveProfileDetails();
                  }
                },
                child: Text('Submit & Write NFC'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
