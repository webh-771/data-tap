import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class MedicalRecordsPage extends StatefulWidget {
  final String uid;

  const MedicalRecordsPage({Key? key, required this.uid}) : super(key: key);

  @override
  _MedicalRecordsPageState createState() => _MedicalRecordsPageState();
}

class _MedicalRecordsPageState extends State<MedicalRecordsPage> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Form controllers
  final TextEditingController _recordTypeController = TextEditingController();
  final TextEditingController _doctorNameController = TextEditingController();
  final TextEditingController _hospitalNameController = TextEditingController();
  final TextEditingController _diagnosisController = TextEditingController();
  final TextEditingController _medicationsController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _followUpDateController = TextEditingController();

  bool _isOngoingTreatment = false;
  List<Map<String, dynamic>> _medicalRecords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMedicalRecords();
  }

  @override
  void dispose() {
    _recordTypeController.dispose();
    _doctorNameController.dispose();
    _hospitalNameController.dispose();
    _diagnosisController.dispose();
    _medicationsController.dispose();
    _notesController.dispose();
    _dateController.dispose();
    _followUpDateController.dispose();
    super.dispose();
  }

  Future<void> _loadMedicalRecords() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final docSnapshot = await _firestore
          .collection('users')
          .doc(widget.uid)
          .collection('medicalRecords')
          .orderBy('date', descending: true)
          .get();

      final List<Map<String, dynamic>> records = [];

      for (var doc in docSnapshot.docs) {
        records.add({
          'id': doc.id,
          ...doc.data(),
        });
      }

      setState(() {
        _medicalRecords = records;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error loading medical records');
    }
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      setState(() {
        controller.text = DateFormat('MM/dd/yyyy').format(picked);
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _saveMedicalRecord() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final record = {
        'recordType': _recordTypeController.text,
        'doctorName': _doctorNameController.text,
        'hospitalName': _hospitalNameController.text,
        'diagnosis': _diagnosisController.text,
        'medications': _medicationsController.text,
        'notes': _notesController.text,
        'date': _dateController.text,
        'followUpDate': _isOngoingTreatment ? _followUpDateController.text : 'None',
        'isOngoingTreatment': _isOngoingTreatment,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(widget.uid)
          .collection('medicalRecords')
          .add(record);

      _resetForm();
      _loadMedicalRecords();

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Medical record saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Error saving medical record');
    }
  }

  void _resetForm() {
    _recordTypeController.clear();
    _doctorNameController.clear();
    _hospitalNameController.clear();
    _diagnosisController.clear();
    _medicationsController.clear();
    _notesController.clear();
    _dateController.clear();
    _followUpDateController.clear();
    _isOngoingTreatment = false;
  }

  void _showAddMedicalRecordDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25.0),
            topRight: Radius.circular(25.0),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Add Medical Record',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _recordTypeController,
                  decoration: InputDecoration(
                    labelText: 'Record Type',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: Icon(Icons.medical_services),
                    hintText: 'e.g., Consultation, Test, Surgery',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter record type';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 15),
                TextFormField(
                  controller: _dateController,
                  decoration: InputDecoration(
                    labelText: 'Date',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () => _selectDate(context, _dateController),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a date';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 15),
                TextFormField(
                  controller: _doctorNameController,
                  decoration: InputDecoration(
                    labelText: 'Doctor\'s Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter doctor\'s name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 15),
                TextFormField(
                  controller: _hospitalNameController,
                  decoration: InputDecoration(
                    labelText: 'Hospital/Clinic',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: Icon(Icons.local_hospital),
                  ),
                ),
                SizedBox(height: 15),
                TextFormField(
                  controller: _diagnosisController,
                  decoration: InputDecoration(
                    labelText: 'Diagnosis/Condition',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: Icon(Icons.assignment),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter diagnosis or condition';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 15),
                TextFormField(
                  controller: _medicationsController,
                  decoration: InputDecoration(
                    labelText: 'Medications/Treatments',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: Icon(Icons.medication),
                  ),
                  maxLines: 2,
                ),
                SizedBox(height: 15),
                Row(
                  children: [
                    Checkbox(
                      value: _isOngoingTreatment,
                      onChanged: (value) {
                        setState(() {
                          _isOngoingTreatment = value ?? false;
                          if (!_isOngoingTreatment) {
                            _followUpDateController.clear();
                          }
                        });
                      },
                    ),
                    Text('Ongoing Treatment / Follow-up Required'),
                  ],
                ),
                if (_isOngoingTreatment) ...[
                  SizedBox(height: 15),
                  TextFormField(
                    controller: _followUpDateController,
                    decoration: InputDecoration(
                      labelText: 'Follow-up Date',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: Icon(Icons.event),
                    ),
                    readOnly: true,
                    onTap: () => _selectDate(context, _followUpDateController),
                    validator: (value) {
                      if (_isOngoingTreatment && (value == null || value.isEmpty)) {
                        return 'Please select a follow-up date';
                      }
                      return null;
                    },
                  ),
                ],
                SizedBox(height: 15),
                TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: 'Notes',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: Icon(Icons.notes),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saveMedicalRecord,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text('Save Medical Record'),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMedicalRecordDetails(Map<String, dynamic> record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${record['recordType']}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow(Icons.calendar_today, 'Date', record['date']),
              _detailRow(Icons.person, 'Doctor', record['doctorName']),
              if (record['hospitalName'] != null && record['hospitalName'].isNotEmpty)
                _detailRow(Icons.local_hospital, 'Hospital/Clinic', record['hospitalName']),
              _detailRow(Icons.assignment, 'Diagnosis', record['diagnosis']),
              if (record['medications'] != null && record['medications'].isNotEmpty)
                _detailRow(Icons.medication, 'Medications', record['medications']),
              if (record['isOngoingTreatment'])
                _detailRow(Icons.event, 'Follow-up Date', record['followUpDate']),
              if (record['notes'] != null && record['notes'].isNotEmpty)
                _detailRow(Icons.notes, 'Notes', record['notes']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteMedicalRecord(record['id']);
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.teal.shade700),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMedicalRecord(String id) async {
    try {
      await _firestore
          .collection('users')
          .doc(widget.uid)
          .collection('medicalRecords')
          .doc(id)
          .delete();

      _loadMedicalRecords();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Medical record deleted'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Error deleting medical record');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        elevation: 0,
        title: Text('Medical Records'),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('About Medical Records'),
                  content: Text(
                      'Store your medical records including doctor visits, diagnoses, treatments, medications, and follow-up appointments. This information is private and secure.'
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Upper curved container with illustration
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.teal,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: 20,
                  bottom: 20,
                  child: Icon(
                    Icons.medical_services,
                    size: 80,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Medical History',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Track consultations, diagnoses, and treatments',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Stats card
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn(
                    Icons.medical_services_outlined,
                    _medicalRecords.length.toString(),
                    'Records',
                    Colors.teal,
                  ),
                  _buildStatColumn(
                    Icons.calendar_today_outlined,
                    _calculateRecentVisits(),
                    'Recent',
                    Colors.blue,
                  ),
                  _buildStatColumn(
                    Icons.notification_important_outlined,
                    _calculateUpcomingFollowUps(),
                    'Follow-ups',
                    Colors.orange,
                  ),
                ],
              ),
            ),
          ),

          // Title for list
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Medical History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: _showAddMedicalRecordDialog,
                  icon: Icon(Icons.add, color: Colors.teal),
                  label: Text('Add New', style: TextStyle(color: Colors.teal)),
                ),
              ],
            ),
          ),

          // List of medical records
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _medicalRecords.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.medical_services_outlined,
                    size: 70,
                    color: Colors.grey.shade400,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'No medical records yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _showAddMedicalRecordDialog,
                    icon: Icon(Icons.add),
                    label: Text('Add Medical Record'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: _medicalRecords.length,
              padding: EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final record = _medicalRecords[index];
                return _buildMedicalRecordCard(record);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _medicalRecords.isNotEmpty
          ? FloatingActionButton(
        onPressed: _showAddMedicalRecordDialog,
        backgroundColor: Colors.teal,
        child: Icon(Icons.add),
      )
          : null,
    );
  }

  Widget _buildStatColumn(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildMedicalRecordCard(Map<String, dynamic> record) {
    // Determine the icon based on record type
    IconData recordIcon = Icons.medical_services;
    if (record['recordType'].toString().toLowerCase().contains('test')) {
      recordIcon = Icons.science;
    } else if (record['recordType'].toString().toLowerCase().contains('surgery')) {
      recordIcon = Icons.medical_information;
    } else if (record['recordType'].toString().toLowerCase().contains('prescription')) {
      recordIcon = Icons.medication;
    }

    return GestureDetector(
      onTap: () => _showMedicalRecordDetails(record),
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(recordIcon, color: Colors.teal),
          ),
          title: Text(
            record['recordType'],
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 4),
              Text(record['diagnosis']),
              SizedBox(height: 4),
              Text(
                'Dr. ${record['doctorName']} • ${record['date']}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
          trailing: record['isOngoingTreatment']
              ? Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Follow-up',
              style: TextStyle(
                color: Colors.amber.shade800,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
              : null,
        ),
      ),
    );
  }

  String _calculateRecentVisits() {
    // Count records in the last 3 months
    if (_medicalRecords.isEmpty) return "0";

    int recentCount = 0;
    final now = DateTime.now();
    final threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);

    for (var record in _medicalRecords) {
      try {
        final recordDate = DateFormat('MM/dd/yyyy').parse(record['date']);
        if (recordDate.isAfter(threeMonthsAgo)) {
          recentCount++;
        }
      } catch (e) {
        // Skip if date parsing fails
      }
    }

    return recentCount.toString();
  }

  String _calculateUpcomingFollowUps() {
    if (_medicalRecords.isEmpty) return "0";

    int upcomingCount = 0;
    final now = DateTime.now();

    for (var record in _medicalRecords) {
      if (record['isOngoingTreatment'] && record['followUpDate'] != 'None') {
        try {
          final followUpDate = DateFormat('MM/dd/yyyy').parse(record['followUpDate']);
          if (followUpDate.isAfter(now)) {
            upcomingCount++;
          }
        } catch (e) {
          // Skip if date parsing fails
        }
      }
    }

    return upcomingCount.toString();
  }
}