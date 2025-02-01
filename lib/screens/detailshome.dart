import 'package:flutter/material.dart';
import 'package:learning/screens/profilepage.dart';
import 'package:learning/screens/medicaldetails.dart';


class Detailshome extends StatelessWidget {
  final String uid; // User's unique ID

  const Detailshome({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home - Enter Details')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2, // 2 columns
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
          children: [
            _buildGridButton(context, 'User Profile', ProfilePage(uid: uid)),
            _buildGridButton(context, 'Medical Records', MedicalRecordsPage(uid: uid))
          ],
        ),
      ),
    );
  }

  Widget _buildGridButton(BuildContext context, String title, Widget page) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.all(16.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
      },
      child: Text(title, textAlign: TextAlign.center),
    );
  }
}
