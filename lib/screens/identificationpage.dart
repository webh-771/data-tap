import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class IdentificationPage extends StatefulWidget {
  final String uid;

  const IdentificationPage({super.key, required this.uid});

  @override
  _IdentificationPageState createState() => _IdentificationPageState();
}

class _IdentificationPageState extends State<IdentificationPage> {
  final TextEditingController _aadhaarController = TextEditingController();
  final TextEditingController _panController = TextEditingController();

  bool _isLoading = false;

  Future<void> _saveIdentification() async {
    String aadhaar = _aadhaarController.text.trim();
    String pan = _panController.text.trim();

    if (aadhaar.isEmpty || pan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter both Aadhaar and PAN numbers")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Save data in `user_identification` collection
      DocumentReference userDoc = FirebaseFirestore.instance
          .collection('user_identification')
          .doc(widget.uid);

      await userDoc.set({
        'aadhaar_number': aadhaar,
        'pan_number': pan,
      });

      // Store PAN card separately in `id_cards` subcollection
      await userDoc.collection('id_cards').doc('PAN_Card').set({
        'type': 'Pan',
        'number': pan,
        'issuedate': DateTime.now(),
        'expirydate': DateTime.now().add(Duration(days: 365 * 10)), // 10 years validity
      });

      // Store Aadhaar card separately in `id_cards` subcollection
      await userDoc.collection('id_cards').doc('Aadhaar_Card').set({
        'type': 'Aadhaar',
        'number': aadhaar,
        'issuedate': DateTime.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Identification data saved successfully!")),
      );

      _aadhaarController.clear();
      _panController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving data: $e")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Enter Identification Details")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _aadhaarController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: "Aadhaar Number"),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _panController,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(labelText: "PAN Number"),
            ),
            SizedBox(height: 24),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _saveIdentification,
              child: Text("Save Details"),
            ),
          ],
        ),
      ),
    );
  }
}
