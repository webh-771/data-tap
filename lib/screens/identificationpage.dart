import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class IdentificationPage extends StatefulWidget {
  final String uid;

  const IdentificationPage({Key? key, required this.uid}) : super(key: key);

  @override
  _IdentificationPageState createState() => _IdentificationPageState();
}

class _IdentificationPageState extends State<IdentificationPage> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Form controllers
  final TextEditingController _cardNameController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _issueDateController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _issuingAuthorityController = TextEditingController();
  final TextEditingController _additionalInfoController = TextEditingController();

  bool _hasNoExpiry = false;
  List<Map<String, dynamic>> _identificationEntries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadIdentificationData();
  }

  @override
  void dispose() {
    _cardNameController.dispose();
    _cardNumberController.dispose();
    _issueDateController.dispose();
    _expiryDateController.dispose();
    _issuingAuthorityController.dispose();
    _additionalInfoController.dispose();
    super.dispose();
  }

  Future<void> _loadIdentificationData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final docSnapshot = await _firestore
          .collection('users')
          .doc(widget.uid)
          .collection('identification')
          .get();

      final List<Map<String, dynamic>> entries = [];

      for (var doc in docSnapshot.docs) {
        entries.add({
          'id': doc.id,
          ...doc.data(),
        });
      }

      setState(() {
        _identificationEntries = entries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error loading identification data');
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
        controller.text = DateFormat('dd/MM/yyyy').format(picked);
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

  Future<void> _saveIdentification() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final identification = {
        'cardName': _cardNameController.text,
        'cardNumber': _cardNumberController.text,
        'issueDate': _issueDateController.text,
        'expiryDate': _hasNoExpiry ? 'No Expiry' : _expiryDateController.text,
        'hasNoExpiry': _hasNoExpiry,
        'issuingAuthority': _issuingAuthorityController.text,
        'additionalInfo': _additionalInfoController.text,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(widget.uid)
          .collection('identification')
          .add(identification);

      _resetForm();
      _loadIdentificationData();

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Identification card saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Error saving identification data');
    }
  }

  void _resetForm() {
    _cardNameController.clear();
    _cardNumberController.clear();
    _issueDateController.clear();
    _expiryDateController.clear();
    _issuingAuthorityController.clear();
    _additionalInfoController.clear();
    _hasNoExpiry = false;
  }

  void _showAddIdentificationDialog() {
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
                  'Add Identification Card',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _cardNameController,
                  decoration: InputDecoration(
                    labelText: 'Card Type',
                    hintText: 'Aadhar Card, PAN Card, etc.',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: Icon(Icons.badge),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter card type';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 15),
                TextFormField(
                  controller: _cardNumberController,
                  decoration: InputDecoration(
                    labelText: 'Card Number',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: Icon(Icons.numbers),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter card number';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 15),
                TextFormField(
                  controller: _issuingAuthorityController,
                  decoration: InputDecoration(
                    labelText: 'Issuing Authority',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: Icon(Icons.account_balance),
                  ),
                ),
                SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _issueDateController,
                        decoration: InputDecoration(
                          labelText: 'Issue Date',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        readOnly: true,
                        onTap: () => _selectDate(context, _issueDateController),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _expiryDateController,
                        decoration: InputDecoration(
                          labelText: 'Expiry Date',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        readOnly: true,
                        enabled: !_hasNoExpiry,
                        onTap: () => _selectDate(context, _expiryDateController),
                        validator: (value) {
                          if (!_hasNoExpiry && (value == null || value.isEmpty)) {
                            return 'Please select expiry date';
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
                      value: _hasNoExpiry,
                      onChanged: (value) {
                        setState(() {
                          _hasNoExpiry = value ?? false;
                          if (_hasNoExpiry) {
                            _expiryDateController.clear();
                          }
                        });
                      },
                    ),
                    Text('No Expiry Date'),
                  ],
                ),
                SizedBox(height: 15),
                TextFormField(
                  controller: _additionalInfoController,
                  decoration: InputDecoration(
                    labelText: 'Additional Information',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: Icon(Icons.info_outline),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saveIdentification,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text('Save Identification Card'),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showIdentificationDetails(Map<String, dynamic> identification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${identification['cardName']}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow(Icons.numbers, 'Card Number', identification['cardNumber']),
              _detailRow(Icons.account_balance, 'Issuing Authority',
                  identification['issuingAuthority'] ?? 'Not specified'),
              _detailRow(Icons.calendar_today, 'Issue Date',
                  identification['issueDate'] ?? 'Not specified'),
              _detailRow(Icons.event_busy, 'Expiry Date',
                  identification['hasNoExpiry'] ? 'No Expiry' : identification['expiryDate']),
              if (identification['additionalInfo'] != null && identification['additionalInfo'].isNotEmpty)
                _detailRow(Icons.info_outline, 'Additional Info', identification['additionalInfo']),
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
              _deleteIdentificationEntry(identification['id']);
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

  Future<void> _deleteIdentificationEntry(String id) async {
    try {
      await _firestore
          .collection('users')
          .doc(widget.uid)
          .collection('identification')
          .doc(id)
          .delete();

      _loadIdentificationData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Identification card deleted'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Error deleting identification card');
    }
  }

  String _getCardTypeIcon(String cardName) {
    final cardNameLower = cardName.toLowerCase();
    if (cardNameLower.contains('aadhar')) return '🆔';
    if (cardNameLower.contains('pan')) return '💳';
    if (cardNameLower.contains('passport')) return '🛂';
    if (cardNameLower.contains('license') || cardNameLower.contains('driving')) return '🚗';
    if (cardNameLower.contains('voter')) return '🗳️';
    return '📄';
  }

  String _getValidityStatus(Map<String, dynamic> card) {
    if (card['hasNoExpiry']) return 'Valid';

    try {
      final expiry = card['expiryDate'].toString();
      if (expiry == 'No Expiry') return 'Valid';

      final parts = expiry.split('/');
      if (parts.length < 3) return 'Unknown';

      final expiryDate = DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0])
      );

      return DateTime.now().isAfter(expiryDate) ? 'Expired' : 'Valid';
    } catch (e) {
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        elevation: 0,
        title: Text('Identification Cards'),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('About Identification Cards'),
                  content: Text(
                      'Store your identification cards such as Aadhar Card, PAN Card, Passport, Driving License, etc. This helps you keep track of your important documents and their expiry dates.'
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
                    Icons.badge,
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
                        'Your Identification Cards',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Keep track of your important documents',
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
                    Icons.badge_outlined,
                    _identificationEntries.length.toString(),
                    'Cards',
                    Colors.teal,
                  ),
                  _buildStatColumn(
                    Icons.warning_amber_outlined,
                    _calculateExpiringCards(),
                    'Expiring',
                    Colors.orange,
                  ),
                  _buildStatColumn(
                    Icons.verified_outlined,
                    _calculateValidCards(),
                    'Valid',
                    Colors.green,
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
                  'Your Documents',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: _showAddIdentificationDialog,
                  icon: Icon(Icons.add, color: Colors.teal),
                  label: Text('Add New', style: TextStyle(color: Colors.teal)),
                ),
              ],
            ),
          ),

          // List of identification entries
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _identificationEntries.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.badge_outlined,
                    size: 70,
                    color: Colors.grey.shade400,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'No identification cards added yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _showAddIdentificationDialog,
                    icon: Icon(Icons.add),
                    label: Text('Add ID Card'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: _identificationEntries.length,
              padding: EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final identification = _identificationEntries[index];
                return _buildIdentificationCard(identification);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _identificationEntries.isNotEmpty
          ? FloatingActionButton(
        onPressed: _showAddIdentificationDialog,
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

  Widget _buildIdentificationCard(Map<String, dynamic> identification) {
    final validityStatus = _getValidityStatus(identification);
    final isExpired = validityStatus == 'Expired';

    return GestureDetector(
      onTap: () => _showIdentificationDetails(identification),
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
            child: Text(
              _getCardTypeIcon(identification['cardName']),
              style: TextStyle(fontSize: 24),
            ),
          ),
          title: Text(
            identification['cardName'],
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 4),
              Text(
                'Card No: ${_maskCardNumber(identification['cardNumber'])}',
                style: TextStyle(fontFamily: 'monospace'),
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.event,
                    size: 12,
                    color: Colors.grey.shade600,
                  ),
                  SizedBox(width: 4),
                  Text(
                    identification['hasNoExpiry']
                        ? 'No Expiry'
                        : 'Expires: ${identification['expiryDate']}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isExpired
                  ? Colors.red.withOpacity(0.1)
                  : Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              validityStatus,
              style: TextStyle(
                color: isExpired ? Colors.red : Colors.green,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _maskCardNumber(String cardNumber) {
    if (cardNumber.length <= 4) return cardNumber;
    final visible = cardNumber.substring(cardNumber.length - 4);
    return 'XXXX-XXXX-${visible}';
  }

  String _calculateExpiringCards() {
    // Count cards expiring in next 3 months
    if (_identificationEntries.isEmpty) return "0";

    int count = 0;
    final now = DateTime.now();
    final threeMonthsLater = DateTime(now.year, now.month + 3, now.day);

    for (var card in _identificationEntries) {
      if (card['hasNoExpiry']) continue;

      try {
        final expiry = card['expiryDate'].toString();
        if (expiry == 'No Expiry') continue;

        final parts = expiry.split('/');
        if (parts.length < 3) continue;

        final expiryDate = DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0])
        );

        if (expiryDate.isAfter(now) && expiryDate.isBefore(threeMonthsLater)) {
          count++;
        }
      } catch (e) {
        continue;
      }
    }

    return count.toString();
  }

  String _calculateValidCards() {
    if (_identificationEntries.isEmpty) return "0";

    int count = 0;
    final now = DateTime.now();

    for (var card in _identificationEntries) {
      if (card['hasNoExpiry']) {
        count++;
        continue;
      }

      try {
        final expiry = card['expiryDate'].toString();
        if (expiry == 'No Expiry') {
          count++;
          continue;
        }

        final parts = expiry.split('/');
        if (parts.length < 3) continue;

        final expiryDate = DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0])
        );

        if (expiryDate.isAfter(now)) {
          count++;
        }
      } catch (e) {
        continue;
      }
    }

    return count.toString();
  }
}