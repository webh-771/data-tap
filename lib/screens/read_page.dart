import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nfc_manager/nfc_manager.dart';

class ReadPage extends StatefulWidget {
  const ReadPage({super.key});

  @override
  _ReadPageState createState() => _ReadPageState();
}

class _ReadPageState extends State<ReadPage> {
  Map<String, dynamic> profileData = {};
  Map<String, dynamic> medicalRecords = {};
  String? errorMessage;
  String? selectedRecordKey;
  String? selectedMode;

  void _startNfcSession() async {
    bool isAvailable = await NfcManager.instance.isAvailable();
    if (!isAvailable) {
      setState(() {
        errorMessage = 'NFC is not available on this device.';
      });
      return;
    }

    NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        try {
          final ndef = Ndef.from(tag);
          if (ndef != null) {
            final message = await ndef.read();
            if (message.records.isNotEmpty) {
              String uid = String.fromCharCodes(message.records.first.payload);
              if (uid.startsWith('\u0002en')) {
                uid = uid.substring(3);
              }
              await _fetchData(uid);
            } else {
              setState(() {
                errorMessage = 'No NDEF records found on the tag.';
              });
            }
          } else {
            setState(() {
              errorMessage = 'Tag is not NDEF formatted.';
            });
          }
        } catch (e) {
          setState(() {
            errorMessage = 'Error reading NFC tag: $e';
          });
        } finally {
          NfcManager.instance.stopSession();
        }
      },
    );
  }

  Future<void> _fetchData(String uid) async {
    try {
      if (selectedMode == 'User Profile') {
        final doc = await FirebaseFirestore.instance.collection('user_profiles').doc(uid).get();
        if (doc.exists) {
          setState(() {
            profileData = doc.data()!;
            errorMessage = null;
          });
        }
      } else if (selectedMode == 'Medical Records') {
        try {
          final recordsSnapshot = await FirebaseFirestore.instance
              .collection('medical_records')
              .doc(uid)
              .collection('records')
              .orderBy('uploadedAt', descending: true)
              .get();

          if (recordsSnapshot.docs.isNotEmpty) {
            setState(() {
              medicalRecords = {
                for (var doc in recordsSnapshot.docs) doc.id: doc.data()
              };
              selectedRecordKey = medicalRecords.keys.first; // Ensure it's a String
              errorMessage = null;
            });
          } else {
            setState(() {
              medicalRecords = {}; // Handle empty state
              selectedRecordKey = null;
              errorMessage = "No medical records found.";
            });
          }
        } catch (e) {
          setState(() {
            errorMessage = "Error fetching medical records: $e";
          });
        }
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching data: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('NFC Medical Records')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Mode:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              value: selectedMode,
              onChanged: (String? newValue) {
                setState(() {
                  selectedMode = newValue;
                });
              },
              items: ['User Profile', 'Medical Records'].map<DropdownMenuItem<String>>((String mode) {
                return DropdownMenuItem<String>(
                  value: mode,
                  child: Text(mode, style: TextStyle(fontSize: 18)),
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: selectedMode != null ? _startNfcSession : null,
              child: Text('Scan NFC Tag'),
            ),
            SizedBox(height: 20),
            errorMessage != null
                ? Text(errorMessage!, style: TextStyle(color: Colors.red, fontSize: 16))
                : selectedMode == 'User Profile' && profileData.isNotEmpty
                ? _buildProfileCard()
                : selectedMode == 'Medical Records' && medicalRecords.isNotEmpty
                ? _buildMedicalRecordCard()
                : Container(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: profileData.entries
              .map<Widget>((entry) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text('${entry.key}: ${entry.value}', style: TextStyle(fontSize: 16)),
          ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildMedicalRecordCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Medical Record:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        DropdownButton<String>(
          value: selectedRecordKey,
          onChanged: (String? newValue) {
            setState(() {
              selectedRecordKey = newValue;
            });
          },
          items: medicalRecords.keys.map<DropdownMenuItem<String>>((String key) {
            return DropdownMenuItem<String>(
              value: key,
              child: Text(key, style: TextStyle(fontSize: 18)),
            );
          }).toList(),
        ),
        SizedBox(height: 10),
        if (selectedRecordKey != null && medicalRecords[selectedRecordKey] != null)
          Card(
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: (medicalRecords[selectedRecordKey] as Map<String, dynamic>)
                    .entries
                    .map<Widget>((entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text('${entry.key}: ${entry.value}', style: TextStyle(fontSize: 16)),
                ))
                    .toList(),
              ),
            ),
          ),
      ],
    );
  }
}
