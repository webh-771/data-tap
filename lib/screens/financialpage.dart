import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class FinancialPage extends StatefulWidget {
  final String uid;

  const FinancialPage({Key? key, required this.uid}) : super(key: key);

  @override
  _FinancialPageState createState() => _FinancialPageState();
}

class _FinancialPageState extends State<FinancialPage> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Form controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _paymentMethodController = TextEditingController();

  String _transactionType = 'Expense'; // Default transaction type
  List<Map<String, dynamic>> _financialEntries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFinancialData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _categoryController.dispose();
    _dateController.dispose();
    _descriptionController.dispose();
    _paymentMethodController.dispose();
    super.dispose();
  }

  Future<void> _loadFinancialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final docSnapshot = await _firestore
          .collection('users')
          .doc(widget.uid)
          .collection('finances')
          .orderBy('date', descending: true)
          .get();

      final List<Map<String, dynamic>> entries = [];

      for (var doc in docSnapshot.docs) {
        entries.add({
          'id': doc.id,
          ...doc.data(),
        });
      }

      setState(() {
        _financialEntries = entries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error loading financial data');
    }
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2010),
      lastDate: DateTime.now(),
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

  Future<void> _saveFinancialEntry() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      double amount = double.parse(_amountController.text);

      // For expenses, store the amount as negative
      if (_transactionType == 'Expense') {
        amount = -amount.abs();
      } else {
        amount = amount.abs();
      }

      final financial = {
        'title': _titleController.text,
        'amount': amount,
        'category': _categoryController.text,
        'date': _dateController.text,
        'description': _descriptionController.text,
        'paymentMethod': _paymentMethodController.text,
        'transactionType': _transactionType,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(widget.uid)
          .collection('finances')
          .add(financial);

      _resetForm();
      _loadFinancialData();

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Financial entry saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Error saving financial data');
    }
  }

  void _resetForm() {
    _titleController.clear();
    _amountController.clear();
    _categoryController.clear();
    _dateController.clear();
    _descriptionController.clear();
    _paymentMethodController.clear();
    _transactionType = 'Expense';
  }

  void _showAddFinancialDialog() {
    // Reset form before showing
    _resetForm();
    _dateController.text = DateFormat('MM/dd/yyyy').format(DateTime.now());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
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
                    'Add Financial Transaction',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),

                  // Transaction Type Toggle
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _transactionType == 'Expense' ? Colors.red : Colors.grey.shade300,
                            foregroundColor: _transactionType == 'Expense' ? Colors.white : Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            setModalState(() {
                              _transactionType = 'Expense';
                            });
                            setState(() {
                              _transactionType = 'Expense';
                            });
                          },
                          child: Text('Expense'),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _transactionType == 'Income' ? Colors.green : Colors.grey.shade300,
                            foregroundColor: _transactionType == 'Income' ? Colors.white : Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            setModalState(() {
                              _transactionType = 'Income';
                            });
                            setState(() {
                              _transactionType = 'Income';
                            });
                          },
                          child: Text('Income'),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 15),
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 15),
                  TextFormField(
                    controller: _amountController,
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: Icon(Icons.currency_rupee),
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an amount';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 15),
                  TextFormField(
                    controller: _categoryController,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: Icon(Icons.category),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a category';
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
                    controller: _paymentMethodController,
                    decoration: InputDecoration(
                      labelText: 'Payment Method',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: Icon(Icons.payment),
                    ),
                  ),
                  SizedBox(height: 15),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 3,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _saveFinancialEntry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _transactionType == 'Expense' ? Colors.red : Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text('Save Transaction'),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showFinancialDetails(Map<String, dynamic> transaction) {
    final bool isExpense = transaction['transactionType'] == 'Expense';
    final Color transactionColor = isExpense ? Colors.red : Colors.green;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '${transaction['title']}',
          style: TextStyle(
            color: transactionColor,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow(
                isExpense ? Icons.arrow_downward : Icons.arrow_upward,
                'Type',
                transaction['transactionType'],
                transactionColor,
              ),
              _detailRow(
                Icons.attach_money,
                'Amount',
                '\$${transaction['amount'].abs().toStringAsFixed(2)}',
                transactionColor,
              ),
              _detailRow(
                Icons.category,
                'Category',
                transaction['category'],
                transactionColor,
              ),
              _detailRow(
                Icons.calendar_today,
                'Date',
                transaction['date'],
                transactionColor,
              ),
              if (transaction['paymentMethod'] != null && transaction['paymentMethod'].isNotEmpty)
                _detailRow(
                  Icons.payment,
                  'Payment Method',
                  transaction['paymentMethod'],
                  transactionColor,
                ),
              if (transaction['description'] != null && transaction['description'].isNotEmpty)
                _detailRow(
                  Icons.description,
                  'Description',
                  transaction['description'],
                  transactionColor,
                ),
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
              _deleteFinancialEntry(transaction['id']);
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String title, String value, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: iconColor),
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

  Future<void> _deleteFinancialEntry(String id) async {
    try {
      await _firestore
          .collection('users')
          .doc(widget.uid)
          .collection('finances')
          .doc(id)
          .delete();

      _loadFinancialData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Financial entry deleted'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Error deleting financial entry');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate financial summary
    double totalIncome = 0;
    double totalExpenses = 0;

    for (var entry in _financialEntries) {
      double amount = entry['amount'] is int ? entry['amount'].toDouble() : entry['amount'];
      if (amount > 0) {
        totalIncome += amount;
      } else {
        totalExpenses += amount.abs();
      }
    }

    double balance = totalIncome - totalExpenses;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        title: Text('Finances'),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('About Financial Data'),
                  content: Text(
                      'Track your income and expenses. Add transactions with details such as amount, category, date, and payment method to monitor your financial health.'
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
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.blue,
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
                    Icons.account_balance_wallet,
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
                        'Financial Overview',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Track your income and expenses',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildFinancialSummaryItem(
                            'Balance',
                            '\₹${balance.toStringAsFixed(2)}',
                            balance >= 0 ? Colors.white : Colors.red.shade100,
                          ),
                          _buildFinancialSummaryItem(
                            'Income',
                            '\₹${totalIncome.toStringAsFixed(2)}',
                            Colors.green.shade100,
                          ),
                          _buildFinancialSummaryItem(
                            'Expenses',
                            '\₹${totalExpenses.toStringAsFixed(2)}',
                            Colors.red.shade100,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Title for list
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Transactions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: _showAddFinancialDialog,
                  icon: Icon(Icons.add, color: Colors.blue),
                  label: Text('Add New', style: TextStyle(color: Colors.blue)),
                ),
              ],
            ),
          ),

          // List of financial entries
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _financialEntries.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 70,
                    color: Colors.grey.shade400,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'No financial records yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _showAddFinancialDialog,
                    icon: Icon(Icons.add),
                    label: Text('Add Transaction'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: _financialEntries.length,
              padding: EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final transaction = _financialEntries[index];
                return _buildTransactionCard(transaction);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _financialEntries.isNotEmpty
          ? FloatingActionButton(
        onPressed: _showAddFinancialDialog,
        backgroundColor: Colors.blue,
        child: Icon(Icons.add),
      )
          : null,
    );
  }

  Widget _buildFinancialSummaryItem(String title, String value, Color textColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    final bool isExpense = transaction['transactionType'] == 'Expense';
    final Color transactionColor = isExpense ? Colors.red : Colors.green;
    final double amount = transaction['amount'] is int
        ? transaction['amount'].toDouble()
        : transaction['amount'];

    return GestureDetector(
      onTap: () => _showFinancialDetails(transaction),
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
              color: transactionColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isExpense ? Icons.arrow_downward : Icons.arrow_upward,
              color: transactionColor,
            ),
          ),
          title: Text(
            transaction['title'],
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 4),
              Text(transaction['category']),
              SizedBox(height: 4),
              Text(
                transaction['date'],
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
          trailing: Text(
            '\₹${amount.abs().toStringAsFixed(2)}',
            style: TextStyle(
              color: transactionColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}