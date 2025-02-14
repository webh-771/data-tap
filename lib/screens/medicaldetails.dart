import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MedicalRecordsPage extends StatefulWidget {
  final String uid;

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
  bool _isFormVisible = false;

  Future<void> _saveMedicalRecord() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final String recordId = DateTime.now().millisecondsSinceEpoch.toString();
      final recordData = {
        'recordName': _recordNameController.text.trim(),
        'doctorName': _doctorNameController.text.trim(),
        'diagnosis': _diagnosisController.text.trim(),
        'prescription': _prescriptionController.text.trim(),
        'additionalNotes': _notesController.text.trim(),
        'date': _dateController.text.trim(),
        'uploadedAt': FieldValue.serverTimestamp(),
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
      setState(() => _isFormVisible = false);
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('medical_records')
                  .doc(widget.uid)
                  .collection('records')
                  .orderBy('uploadedAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                var records = snapshot.data!.docs;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    var data = records[index].data() as Map<String, dynamic>;
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text(data['recordName'] ?? 'Unknown',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Doctor: ${data['doctorName'] ?? ''}"),
                            Text("Diagnosis: ${data['diagnosis'] ?? ''}"),
                            Text("Date: ${data['date'] ?? ''}"),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => setState(() => _isFormVisible = !_isFormVisible),
              icon: Icon(_isFormVisible ? Icons.close : Icons.add),
              label: Text(_isFormVisible ? 'Cancel' : 'Add New Record'),
            ),
            if (_isFormVisible)
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField(_recordNameController, 'Record Name', Icons.assignment),
                    _buildTextField(_doctorNameController, 'Doctor Name', Icons.local_hospital),
                    _buildTextField(_diagnosisController, 'Diagnosis', Icons.assignment_turned_in),
                    _buildTextField(_prescriptionController, 'Prescription', Icons.medical_services),
                    _buildTextField(_notesController, 'Additional Notes', Icons.notes, maxLines: 3),
                    _buildDateField(),
                    ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _saveMedicalRecord,
                      icon: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Icon(Icons.save),
                      label: const Text('Save Record'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        maxLines: maxLines,
        validator: (value) => value == null || value.isEmpty ? 'This field cannot be empty' : null,
      ),
    );
  }

  Widget _buildDateField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: _dateController,
        decoration: InputDecoration(
          labelText: 'Date',
          prefixIcon: const Icon(Icons.calendar_today),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        readOnly: true,
        onTap: _selectDate,
        validator: (value) => value == null || value.isEmpty ? 'Please select a date' : null,
      ),
    );
  }
}
