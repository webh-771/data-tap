import 'package:flutter/material.dart';
import 'package:learning/screens/profilepage.dart';
import 'package:learning/screens/medicaldetails.dart';
import 'package:learning/screens/identificationpage.dart';
// Import new pages
import 'package:learning/screens/educationpage.dart';
import 'package:learning/screens/employmentpage.dart';
import 'package:learning/screens/financialpage.dart';
import 'package:learning/screens/emergencypage.dart';
import 'package:learning/screens/familypage.dart';

class Detailshome extends StatelessWidget {
  final String uid;

  const Detailshome({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            // Enhanced Header with Animation
            Container(
              height: MediaQuery.of(context).size.height * 0.22,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade800, Colors.indigo.shade900],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Container(
                      height: 100,
                      width: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -30,
                    bottom: -30,
                    child: Container(
                      height: 120,
                      width: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Personal Data Hub",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Complete your profile details",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // Search Bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Search categories...",
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
            ),

            SizedBox(height: 20),

            // Categories Section Label
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    height: 25,
                    width: 5,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade800,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    "Categories",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 15),

            // Expanded Grid Menu with More Options
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 15.0,
                  mainAxisSpacing: 15.0,
                  children: [
                    _buildGridCard(
                      context,
                      icon: Icons.person,
                      title: "Basic Profile",
                      color: Colors.blue,
                      page: ProfilePage(uid: uid),
                    ),
                    _buildGridCard(
                      context,
                      icon: Icons.medical_services,
                      title: "Medical Records",
                      color: Colors.red,
                      page: MedicalRecordsPage(uid: uid),
                    ),
                    _buildGridCard(
                      context,
                      icon: Icons.badge,
                      title: "Identification",
                      color: Colors.teal,
                      page: IdentificationPage(uid: uid),
                    ),

                    _buildGridCard(
                      context,
                      icon: Icons.school,
                      title: "Education",
                      color: Colors.purple,
                      page: EducationPage(uid: uid),
                    ),
                    _buildGridCard(
                      context,
                      icon: Icons.work,
                      title: "Employment",
                      color: Colors.brown,
                      page: EmploymentPage(uid: uid),
                    ),
                    _buildGridCard(
                      context,
                      icon: Icons.attach_money,
                      title: "Financial",
                      color: Colors.green,
                      page: FinancialPage(uid: uid),
                    ),
                    _buildGridCard(
                      context,
                      icon: Icons.emergency,
                      title: "Emergency Contacts",
                      color: Colors.orange,
                      page: EmergencyPage(uid: uid),
                    ),
                    _buildGridCard(
                      context,
                      icon: Icons.family_restroom,
                      title: "Family & Relations",
                      color: Colors.pink,
                      page: FamilyPage(uid: uid),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // Add a floating action button for quick access
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Show a dialog with completion status or quick actions
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text("Profile Completion"),
              content: Text("Your profile is 40% complete. Would you like suggestions on what to fill next?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Later"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Navigate to the least completed section
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => EducationPage(uid: uid)),
                    );
                  },
                  child: Text("Show Me"),
                ),
              ],
            ),
          );
        },
        backgroundColor: Colors.blue.shade800,
        child: Icon(Icons.add_chart),
      ),
    );
  }

  Widget _buildGridCard(BuildContext context,
      {required IconData icon,
        required String title,
        required Color color,
        required Widget page}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 5),
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: color.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}