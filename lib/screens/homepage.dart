import 'package:flutter/material.dart';
import 'profilepage.dart'; // Import your ProfilePage
import 'read_page.dart';  // Import your ReadPage

class HomePage extends StatelessWidget {
  final String uid; // Add a uid parameter to HomePage

  const HomePage({Key? key, required this.uid}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Tap'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Introduction
            const Text(
              'Welcome to Data Tap!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'This app allows you to write and read data using NFC. Get started by exploring the options below!',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Profile Button
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfilePage(uid: uid), // Pass uid here
                  ),
                );
              },
              child: const Text('Profile'),
            ),

            // Read Data Button
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReadPage(uid: uid), // Pass uid to ReadPage
                  ),
                );
              },
              child: const Text('Read Data'),
            ),
          ],
        ),
      ),
    );
  }
}
