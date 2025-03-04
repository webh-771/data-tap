import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EmploymentPage extends StatefulWidget {
  final String uid;

  const EmploymentPage({Key? key, required this.uid}) : super(key: key);

  @override
  _EmploymentPageState createState() => _EmploymentPageState();
}

class _EmploymentPageState extends State<EmploymentPage> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Form controllers
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _jobTitleController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _jobDescriptionController = TextEditingController();
  final TextEditingController _achievementsController = TextEditingController();

  bool _isCurrentlyWorking = false;
  List<Map<String, dynamic>> _employmentEntries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEmploymentData();
  }

  @override
  void dispose() {
    _companyController.dispose();
    _jobTitleController.dispose();
    _locationController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _jobDescriptionController.dispose();
    _achievementsController.dispose();
    super.dispose();
  }

  Future<void> _loadEmploymentData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final docSnapshot = await _firestore
          .collection('users')
          .doc(widget.uid)
          .collection('employment')
          .get();

      final List<Map<String, dynamic>> entries = [];

      for (var doc in docSnapshot.docs) {
        entries.add({
          'id': doc.id,
          ...doc.data(),
        });
      }

      setState(() {
        _employmentEntries = entries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error loading employment data');
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

  Future<void> _saveEmployment() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final employment = {
        'company': _companyController.text,
        'jobTitle': _jobTitleController.text,
        'location': _locationController.text,
        'startDate': _startDateController.text,
        'endDate': _isCurrentlyWorking ? 'Present' : _endDateController.text,
        'isCurrentlyWorking': _isCurrentlyWorking,
        'jobDescription': _jobDescriptionController.text,
        'achievements': _achievementsController.text,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(widget.uid)
          .collection('employment')
          .add(employment);

      _resetForm();
      _loadEmploymentData();

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Employment entry saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Error saving employment data');
    }
  }

  void _resetForm() {
    _companyController.clear();
    _jobTitleController.clear();
    _locationController.clear();
    _startDateController.clear();
    _endDateController.clear();
    _jobDescriptionController.clear();
    _achievementsController.clear();
    _isCurrentlyWorking = false;
  }

  void _showAddEmploymentDialog() {
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
                  'Add Employment',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _companyController,
                  decoration: InputDecoration(
                    labelText: 'Company',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: Icon(Icons.business),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter company name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 15),
                TextFormField(
                  controller: _jobTitleController,
                  decoration: InputDecoration(
                    labelText: 'Job Title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: Icon(Icons.work),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your job title';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 15),
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: Icon(Icons.location_on),
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
                        enabled: !_isCurrentlyWorking,
                        onTap: () => _selectDate(context, _endDateController),
                        validator: (value) {
                          if (!_isCurrentlyWorking && (value == null || value.isEmpty)) {
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
                      value: _isCurrentlyWorking,
                      onChanged: (value) {
                        setState(() {
                          _isCurrentlyWorking = value ?? false;
                          if (_isCurrentlyWorking) {
                            _endDateController.clear();
                          }
                        });
                      },
                    ),
                    Text('Currently Working Here'),
                  ],
                ),
                SizedBox(height: 15),
                TextFormField(
                  controller: _jobDescriptionController,
                  decoration: InputDecoration(
                    labelText: 'Job Description',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 15),
                TextFormField(
                  controller: _achievementsController,
                  decoration: InputDecoration(
                    labelText: 'Key Achievements',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: Icon(Icons.emoji_events),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saveEmployment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text('Save Employment'),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEmploymentDetails(Map<String, dynamic> employment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${employment['jobTitle']}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow(Icons.business, 'Company', employment['company']),
              _detailRow(Icons.location_on, 'Location', employment['location'] ?? 'Not specified'),
              _detailRow(
                  Icons.date_range,
                  'Duration',
                  '${employment['startDate']} - ${employment['isCurrentlyWorking'] ? 'Present' : employment['endDate']}'
              ),
              if (employment['jobDescription'] != null && employment['jobDescription'].isNotEmpty)
                _detailRow(Icons.description, 'Job Description', employment['jobDescription']),
              if (employment['achievements'] != null && employment['achievements'].isNotEmpty)
                _detailRow(Icons.emoji_events, 'Key Achievements', employment['achievements']),
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
              _deleteEmploymentEntry(employment['id']);
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
          Icon(icon, size: 20, color: Colors.indigo.shade700),
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

  Future<void> _deleteEmploymentEntry(String id) async {
    try {
      await _firestore
          .collection('users')
          .doc(widget.uid)
          .collection('employment')
          .doc(id)
          .delete();

      _loadEmploymentData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Employment entry deleted'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Error deleting employment entry');
    }
  }

  String _calculateTotalExperience() {
    if (_employmentEntries.isEmpty) return "0";

    int totalMonths = 0;
    final now = DateTime.now();

    for (var entry in _employmentEntries) {
      // Parse start date
      final startDateParts = entry['startDate'].split('/');
      final startMonth = int.parse(startDateParts[0]);
      final startYear = int.parse(startDateParts[1]);

      // Calculate end date
      int endMonth, endYear;
      if (entry['isCurrentlyWorking']) {
        endMonth = now.month;
        endYear = now.year;
      } else {
        final endDateParts = entry['endDate'].split('/');
        endMonth = int.parse(endDateParts[0]);
        endYear = int.parse(endDateParts[1]);
      }

      // Calculate months difference
      totalMonths += (endYear - startYear) * 12 + (endMonth - startMonth);
    }

    // Convert to years (rounded)
    final years = (totalMonths / 12).round();
    return years.toString();
  }

  String _calculateLatestTitle() {
    if (_employmentEntries.isEmpty) return "None";

    // Sort by end date (present jobs first, then most recent)
    _employmentEntries.sort((a, b) {
      if (a['isCurrentlyWorking'] && !b['isCurrentlyWorking']) return -1;
      if (!a['isCurrentlyWorking'] && b['isCurrentlyWorking']) return 1;

      // Both current or both past, compare start dates (most recent first)
      final aDateParts = a['startDate'].split('/');
      final bDateParts = b['startDate'].split('/');

      final aYear = int.parse(aDateParts[1]);
      final bYear = int.parse(bDateParts[1]);

      if (aYear != bYear) return bYear.compareTo(aYear);

      final aMonth = int.parse(aDateParts[0]);
      final bMonth = int.parse(bDateParts[0]);
      return bMonth.compareTo(aMonth);
    });

    // Return the job title of the most recent job
    return _employmentEntries.isNotEmpty ? _employmentEntries[0]['jobTitle'] : "None";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        elevation: 0,
        title: Text('Employment'),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('About Employment Data'),
                  content: Text(
                      'Add your work history including companies, job titles, and responsibilities. This information helps build a comprehensive profile of your professional experience.'
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
              color: Colors.indigo,
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
                    Icons.business_center,
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
                        'Your Professional Journey',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Add your work experiences and achievements',
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
                    Icons.business_center_outlined,
                    _employmentEntries.length.toString(),
                    'Jobs',
                    Colors.indigo,
                  ),
                  _buildStatColumn(
                    Icons.calendar_today_outlined,
                    _calculateTotalExperience(),
                    'Years',
                    Colors.blue,
                  ),
                  _buildStatColumn(
                    Icons.workspace_premium_outlined,
                    _calculateLatestTitle().length > 10
                        ? _calculateLatestTitle().substring(0, 10) + '...'
                        : _calculateLatestTitle(),
                    'Latest',
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
                  'Employment History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: _showAddEmploymentDialog,
                  icon: Icon(Icons.add, color: Colors.indigo),
                  label: Text('Add New', style: TextStyle(color: Colors.indigo)),
                ),
              ],
            ),
          ),

          // List of employment entries
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _employmentEntries.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.work_outline,
                    size: 70,
                    color: Colors.grey.shade400,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'No employment records yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _showAddEmploymentDialog,
                    icon: Icon(Icons.add),
                    label: Text('Add Employment'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: _employmentEntries.length,
              padding: EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final employment = _employmentEntries[index];
                return _buildEmploymentCard(employment);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _employmentEntries.isNotEmpty
          ? FloatingActionButton(
        onPressed: _showAddEmploymentDialog,
        backgroundColor: Colors.indigo,
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

  Widget _buildEmploymentCard(Map<String, dynamic> employment) {
    return GestureDetector(
      onTap: () => _showEmploymentDetails(employment),
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
              color: Colors.indigo.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.work, color: Colors.indigo),
          ),
          title: Text(
            employment['jobTitle'],
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 4),
              Text(employment['company']),
              SizedBox(height: 4),
              Text(
                '${employment['startDate']} - ${employment['isCurrentlyWorking'] ? 'Present' : employment['endDate']}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
          trailing: employment['isCurrentlyWorking']
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
}