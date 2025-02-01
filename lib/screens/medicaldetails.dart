import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MedicalRecordsPage extends StatefulWidget {
  final String uid; // User's UID passed after login

  const MedicalRecordsPage({super.key, required this.uid});

  @override
  _MedicalRecordsPageState createState() => _MedicalRecordsPageState();
}

class _MedicalRecordsPageState extends State<MedicalRecordsPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _recordNameController = TextEditingController();
  final TextEditingController _doctorNameController = TextEditingController();
  final TextEditingController _diagnosisController = TextEditingController();
  final TextEditingController _prescriptionController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  // Function to save record details in structured database format
  Future<void> _saveMedicalRecord() async {
    if (_recordNameController.text.isEmpty ||
        _doctorNameController.text.isEmpty ||
        _diagnosisController.text.isEmpty ||
        _prescriptionController.text.isEmpty ||
        _notesController.text.isEmpty ||
        _dateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    try {
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final recordData = {
        'Record Name': _recordNameController.text.trim(),
        'Doctor Name': _doctorNameController.text.trim(),
        'Diagnosis': _diagnosisController.text.trim(),
        'Prescription': _prescriptionController.text.trim(),
        'Additional Notes': _notesController.text.trim(),
        'Date': _dateController.text.trim(),
        'Uploaded At': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('medical_records')
          .doc(widget.uid) // Use UID as the primary key
          .collection('records') // Collection for user records
          .doc(timestamp) // Unique timestamp for each record
          .set(recordData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medical record saved successfully!')),
      );
      setState(() {
        _recordNameController.clear();
        _doctorNameController.clear();
        _diagnosisController.clear();
        _prescriptionController.clear();
        _notesController.clear();
        _dateController.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving record: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Records'),
        centerTitle: true,
        backgroundColor: Colors.green,
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
                      _buildTextField(_recordNameController, 'Record Name'),
                      _buildTextField(_doctorNameController, 'Doctor Name'),
                      _buildTextField(_diagnosisController, 'Diagnosis'),
                      _buildTextField(_prescriptionController, 'Prescription'),
                      _buildTextField(_notesController, 'Additional Notes', maxLines: 4),
                      _buildTextField(_dateController, 'Date (YYYY-MM-DD)'),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            _saveMedicalRecord();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: const TextStyle(fontSize: 18),
                        ),
                        child: const Text('Save Record'),
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

  Widget _buildTextField(TextEditingController controller, String label, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        validator: (value) => value == null || value.isEmpty ? 'Please enter $label' : null,
      ),
    );
  }
}
