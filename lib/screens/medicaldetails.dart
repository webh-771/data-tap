import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MedicalRecordsPage extends StatefulWidget {
  final String uid; // User's UID

  const MedicalRecordsPage({super.key, required this.uid});

  @override
  State<MedicalRecordsPage> createState() => _MedicalRecordsPageState();
}

class _MedicalRecordsPageState extends State<MedicalRecordsPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _recordNameController = TextEditingController();
  final TextEditingController _doctorNameController = TextEditingController();
  final TextEditingController _diagnosisController = TextEditingController();
  final TextEditingController _prescriptionController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _saveMedicalRecord() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final String recordId = DateTime.now().millisecondsSinceEpoch.toString();
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
          .doc(widget.uid)
          .collection('records')
          .doc(recordId)
          .set(recordData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Record saved successfully!')),
      );

      _clearFields();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠ Error saving record: $e')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _clearFields() {
    _recordNameController.clear();
    _doctorNameController.clear();
    _diagnosisController.clear();
    _prescriptionController.clear();
    _notesController.clear();
    _dateController.clear();
  }

  Future<void> _selectDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      setState(() {
        _dateController.text = "${pickedDate.toLocal()}".split(' ')[0];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Records'),
        centerTitle: true,
        backgroundColor: Colors.green.shade700,
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Display Existing Records
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('medical_records')
                  .doc(widget.uid)
                  .collection('records')
                  .orderBy('Uploaded At', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var records = snapshot.data!.docs;

                return Column(
                  children: records.map((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: ListTile(
                        title: Text(
                          data['Record Name'] ?? 'Unknown',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Doctor: ${data['Doctor Name'] ?? ''}"),
                            Text("Diagnosis: ${data['Diagnosis'] ?? ''}"),
                            Text("Date: ${data['Date'] ?? ''}"),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios),
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 20),

            // Form for adding records
            Form(
              key: _formKey,
              child: Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      _buildTextField(_recordNameController, 'Record Name', Icons.assignment),
                      _buildTextField(_doctorNameController, 'Doctor Name', Icons.local_hospital),
                      _buildTextField(_diagnosisController, 'Diagnosis', Icons.assignment_turned_in),
                      _buildTextField(_prescriptionController, 'Prescription', Icons.medical_services),
                      _buildTextField(_notesController, 'Additional Notes', Icons.notes, maxLines: 3),
                      _buildDateField(),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _saveMedicalRecord,
                        icon: _isSubmitting
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Icon(Icons.save),
                        label: const Text('Save Record'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.green.shade700),
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        validator: (value) => value == null || value.isEmpty ? 'Please enter $label' : null,
      ),
    );
  }

  Widget _buildDateField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: _dateController,
        readOnly: true,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.calendar_today, color: Colors.green),
          labelText: 'Date of Visit',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        validator: (value) => value == null || value.isEmpty ? 'Please select a date' : null,
        onTap: _selectDate,
      ),
    );
  }
}
