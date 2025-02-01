import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  String _selectedGender = 'Male'; // Default selection

  // Function to save profile details in Firestore
  Future<void> _saveProfileDetails() async {
    try {
      final profileData = {
        'Full Name': _nameController.text.trim(),
        'Email': _emailController.text.trim(),
        'Phone': _phoneController.text.trim(),
        'Address': _addressController.text.trim().isEmpty ? null : _addressController.text.trim(), // Nullable
        'DateOfBirth': _dobController.text.trim(),
        'Gender': _selectedGender,
        'Updated At': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('user_profiles')
          .doc(widget.uid) // Use UID as the primary key
          .set(profileData, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile details saved successfully!')),
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
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      _buildTextField(_nameController, 'Full Name', Icons.person),
                      _buildTextField(_emailController, 'Email', Icons.email),
                      _buildTextField(_phoneController, 'Phone', Icons.phone, isNumeric: true),
                      _buildTextField(_addressController, 'Address (Optional)', Icons.home),
                      _buildDateField(),
                      _buildGenderDropdown(),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            _saveProfileDetails();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: TextStyle(fontSize: 18),
                        ),
                        child: Text('Save Profile'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Text field builder
  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isNumeric = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.blueAccent),
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        validator: (value) {
          if (label == 'Email' && value != null && !RegExp(r"^[a-zA-Z0-9+_.-]+@[a-zA-Z0-9.-]+$").hasMatch(value)) {
            return 'Enter a valid email';
          }
          if (label == 'Phone' && value != null && value.length != 10) {
            return 'Enter a valid 10-digit phone number';
          }
          if (label != 'Address (Optional)' && (value == null || value.isEmpty)) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }

  // Date Picker for Date of Birth
  Widget _buildDateField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: _dobController,
        readOnly: true,
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.calendar_today, color: Colors.blueAccent),
          labelText: 'Date of Birth',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        validator: (value) => value == null || value.isEmpty ? 'Please select Date of Birth' : null,
        onTap: () async {
          DateTime? pickedDate = await showDatePicker(
            context: context,
            initialDate: DateTime(2000),
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
          );
          if (pickedDate != null) {
            setState(() {
              _dobController.text = "${pickedDate.toLocal()}".split(' ')[0]; // Store only the date
            });
          }
        },
      ),
    );
  }

  // Gender Dropdown
  Widget _buildGenderDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: DropdownButtonFormField<String>(
        value: _selectedGender,
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.wc, color: Colors.blueAccent),
          labelText: 'Gender',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        items: ['Male', 'Female', 'Other'].map((String gender) {
          return DropdownMenuItem<String>(
            value: gender,
            child: Text(gender),
          );
        }).toList(),
        onChanged: (newValue) {
          setState(() {
            _selectedGender = newValue!;
          });
        },
      ),
    );
  }
}
