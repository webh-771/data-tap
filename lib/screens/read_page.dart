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
  bool isLoading = false;

  void _startNfcSession() async {
    bool isAvailable = await NfcManager.instance.isAvailable();
    if (!isAvailable) {
      setState(() {
        errorMessage = 'NFC is not available on this device.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

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
          setState(() {
            isLoading = false;
          });
          NfcManager.instance.stopSession();
        }
      },
    );
  }

  Future<void> _fetchData(String uid) async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      if (selectedMode == 'User Profile') {
        final doc = await FirebaseFirestore.instance.collection('user_profiles').doc(uid).get();
        if (doc.exists) {
          setState(() {
            profileData = doc.data()!;
          });
        } else {
          setState(() {
            errorMessage = "No profile found for this user.";
            profileData = {};
          });
        }
      } else if (selectedMode == 'Medical Records') {
        final recordsSnapshot = await FirebaseFirestore.instance
            .collection('medical_records')
            .doc(uid)
            .collection('records')
            .orderBy('uploadedAt', descending: true)
            .get();

        if (recordsSnapshot.docs.isNotEmpty) {
          setState(() {
            medicalRecords = {for (var doc in recordsSnapshot.docs) doc.id: doc.data()};
            selectedRecordKey = medicalRecords.keys.first;
          });
        } else {
          setState(() {
            errorMessage = "No medical records found.";
            medicalRecords = {};
            selectedRecordKey = null;
          });
        }
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching data: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NFC Medical Records', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Mode:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildDropdown(),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: selectedMode != null ? _startNfcSession : null,
              icon: const Icon(Icons.nfc),
              label: const Text('Scan NFC Tag'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                textStyle: const TextStyle(fontSize: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            if (isLoading)
              const Center(child: CircularProgressIndicator()),
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 16)),
              ),
            if (selectedMode == 'User Profile' && profileData.isNotEmpty) _buildProfileCard(),
            if (selectedMode == 'Medical Records' && medicalRecords.isNotEmpty) _buildMedicalRecordCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedMode,
          isExpanded: true,
          onChanged: (String? newValue) {
            setState(() {
              selectedMode = newValue;
            });
          },
          items: ['User Profile', 'Medical Records'].map((String mode) {
            return DropdownMenuItem<String>(
              value: mode,
              child: Text(mode, style: const TextStyle(fontSize: 18)),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return _buildDataCard(profileData, Colors.blue.shade50);
  }

  Widget _buildMedicalRecordCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Medical Record:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildMedicalRecordsDropdown(),
        const SizedBox(height: 10),
        if (selectedRecordKey != null && medicalRecords[selectedRecordKey] != null)
          _buildDataCard(medicalRecords[selectedRecordKey], Colors.green.shade50),
      ],
    );
  }

  Widget _buildMedicalRecordsDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedRecordKey,
          isExpanded: true,
          onChanged: (String? newValue) {
            setState(() {
              selectedRecordKey = newValue;
            });
          },
          items: medicalRecords.keys.map((String key) {
            return DropdownMenuItem<String>(
              value: key,
              child: Text(key, style: const TextStyle(fontSize: 18)),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDataCard(Map<String, dynamic> data, Color color) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: data.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text('${entry.key}: ${entry.value}', style: const TextStyle(fontSize: 16)),
            );
          }).toList(),
        ),
      ),
    );
  }
}
