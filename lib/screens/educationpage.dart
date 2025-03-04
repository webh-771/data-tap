import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EducationPage extends StatefulWidget {
  final String uid;

  const EducationPage({Key? key, required this.uid}) : super(key: key);

  @override
  _EducationPageState createState() => _EducationPageState();
}

class _EducationPageState extends State<EducationPage> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Form controllers
  final TextEditingController _institutionController = TextEditingController();
  final TextEditingController _degreeController = TextEditingController();
  final TextEditingController _fieldOfStudyController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _gradeController = TextEditingController();
  final TextEditingController _achievementsController = TextEditingController();

  bool _isCurrentlyStudying = false;
  List<Map<String, dynamic>> _educationEntries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEducationData();
  }

  @override
  void dispose() {
    _institutionController.dispose();
    _degreeController.dispose();
    _fieldOfStudyController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _gradeController.dispose();
    _achievementsController.dispose();
    super.dispose();
  }

  Future<void> _loadEducationData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final docSnapshot = await _firestore
          .collection('users')
          .doc(widget.uid)
          .collection('education')
          .get();

      final List<Map<String, dynamic>> entries = [];

      for (var doc in docSnapshot.docs) {
        entries.add({
          'id': doc.id,
          ...doc.data(),
        });
      }

      setState(() {
        _educationEntries = entries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error loading education data');
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
        controller.text = DateFormat('MM/yyyy').format(picked);
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

  Future<void> _saveEducation() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final education = {
        'institution': _institutionController.text,
        'degree': _degreeController.text,
        'fieldOfStudy': _fieldOfStudyController.text,
        'startDate': _startDateController.text,
        'endDate': _isCurrentlyStudying ? 'Present' : _endDateController.text,
        'isCurrentlyStudying': _isCurrentlyStudying,
        'grade': _gradeController.text,
        'achievements': _achievementsController.text,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(widget.uid)
          .collection('education')
          .add(education);

      _resetForm();
      _loadEducationData();

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Education entry saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Error saving education data');
    }
  }

  void _resetForm() {
    _institutionController.clear();
    _degreeController.clear();
    _fieldOfStudyController.clear();
    _startDateController.clear();
    _endDateController.clear();
    _gradeController.clear();
    _achievementsController.clear();
    _isCurrentlyStudying = false;
  }

  void _showAddEducationDialog() {
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
                  'Add Education',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _institutionController,
                  decoration: InputDecoration(
                    labelText: 'Institution',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: Icon(Icons.school),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter institution name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 15),
                TextFormField(
                  controller: _degreeController,
                  decoration: InputDecoration(
                    labelText: 'Degree/Certificate',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: Icon(Icons.card_membership),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your degree or certificate';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 15),
                TextFormField(
                  controller: _fieldOfStudyController,
                  decoration: InputDecoration(
                    labelText: 'Field of Study',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: Icon(Icons.subject),
                  ),
                ),
                SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _startDateController,
                        decoration: InputDecoration(
                          labelText: 'Start Date',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        readOnly: true,
                        onTap: () => _selectDate(context, _startDateController),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a start date';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _endDateController,
                        decoration: InputDecoration(
                          labelText: 'End Date',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        readOnly: true,
                        enabled: !_isCurrentlyStudying,
                        onTap: () => _selectDate(context, _endDateController),
                        validator: (value) {
                          if (!_isCurrentlyStudying && (value == null || value.isEmpty)) {
                            return 'Please select an end date';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Checkbox(
                      value: _isCurrentlyStudying,
                      onChanged: (value) {
                        setState(() {
                          _isCurrentlyStudying = value ?? false;
                          if (_isCurrentlyStudying) {
                            _endDateController.clear();
                          }
                        });
                      },
                    ),
                    Text('Currently Studying'),
                  ],
                ),
                SizedBox(height: 15),
                TextFormField(
                  controller: _gradeController,
                  decoration: InputDecoration(
                    labelText: 'Grade/GPA',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: Icon(Icons.grade),
                  ),
                ),
                SizedBox(height: 15),
                TextFormField(
                  controller: _achievementsController,
                  decoration: InputDecoration(
                    labelText: 'Achievements/Activities',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: Icon(Icons.emoji_events),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saveEducation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text('Save Education'),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEducationDetails(Map<String, dynamic> education) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${education['degree']}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow(Icons.school, 'Institution', education['institution']),
              _detailRow(Icons.subject, 'Field of Study', education['fieldOfStudy'] ?? 'Not specified'),
              _detailRow(
                  Icons.date_range,
                  'Duration',
                  '${education['startDate']} - ${education['isCurrentlyStudying'] ? 'Present' : education['endDate']}'
              ),
              _detailRow(Icons.grade, 'Grade/GPA', education['grade'] ?? 'Not specified'),
              if (education['achievements'] != null && education['achievements'].isNotEmpty)
                _detailRow(Icons.emoji_events, 'Achievements', education['achievements']),
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
              _deleteEducationEntry(education['id']);
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
          Icon(icon, size: 20, color: Colors.purple.shade700),
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

  Future<void> _deleteEducationEntry(String id) async {
    try {
      await _firestore
          .collection('users')
          .doc(widget.uid)
          .collection('education')
          .doc(id)
          .delete();

      _loadEducationData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Education entry deleted'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Error deleting education entry');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.purple,
        elevation: 0,
        title: Text('Education'),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('About Education Data'),
                  content: Text(
                      'Add your educational history including schools, colleges, universities, and other educational institutions you have attended. You can also add certifications, courses, and other qualifications.'
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
              color: Colors.purple,
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
                    Icons.school,
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
                        'Your Educational Journey',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Add your degrees, certifications, and courses',
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
                    Icons.school_outlined,
                    _educationEntries.length.toString(),
                    'Entries',
                    Colors.purple,
                  ),
                  _buildStatColumn(
                    Icons.calendar_today_outlined,
                    _calculateYearsOfEducation(),
                    'Years',
                    Colors.blue,
                  ),
                  _buildStatColumn(
                    Icons.star_outline,
                    _calculateHighestDegree(),
                    'Highest',
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
                  'Education History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: _showAddEducationDialog,
                  icon: Icon(Icons.add, color: Colors.purple),
                  label: Text('Add New', style: TextStyle(color: Colors.purple)),
                ),
              ],
            ),
          ),

          // List of education entries
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _educationEntries.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.school_outlined,
                    size: 70,
                    color: Colors.grey.shade400,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'No education records yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _showAddEducationDialog,
                    icon: Icon(Icons.add),
                    label: Text('Add Education'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: _educationEntries.length,
              padding: EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final education = _educationEntries[index];
                return _buildEducationCard(education);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _educationEntries.isNotEmpty
          ? FloatingActionButton(
        onPressed: _showAddEducationDialog,
        backgroundColor: Colors.purple,
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

  Widget _buildEducationCard(Map<String, dynamic> education) {
    return GestureDetector(
      onTap: () => _showEducationDetails(education),
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
              color: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.school, color: Colors.purple),
          ),
          title: Text(
            education['degree'],
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 4),
              Text(education['institution']),
              SizedBox(height: 4),
              Text(
                '${education['startDate']} - ${education['isCurrentlyStudying'] ? 'Present' : education['endDate']}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
          trailing: education['isCurrentlyStudying']
              ? Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Current',
              style: TextStyle(
                color: Colors.green,
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

  String _calculateYearsOfEducation() {
    // Simple calculation - can be enhanced for more accuracy
    return _educationEntries.isNotEmpty ? "${_educationEntries.length * 2}+" : "0";
  }

  String _calculateHighestDegree() {
    if (_educationEntries.isEmpty) return "None";

    // Simple logic to determine highest degree
    // This can be enhanced with more sophisticated logic
    final degrees = _educationEntries.map((e) => e['degree'] as String).toList();

    if (degrees.any((d) => d.toLowerCase().contains('phd') || d.toLowerCase().contains('doctorate'))) {
      return "PhD";
    } else if (degrees.any((d) => d.toLowerCase().contains('master'))) {
      return "Masters";
    } else if (degrees.any((d) => d.toLowerCase().contains('bachelor'))) {
      return "Bachelor";
    } else {
      return "Other";
    }
  }
}