import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nfc_manager/nfc_manager.dart';

class ReadPage extends StatefulWidget {
  const ReadPage({super.key, required String uid});

  @override
  _ReadPageState createState() => _ReadPageState();
}

class _ReadPageState extends State<ReadPage> {
  Map<String, dynamic> profileData = {}; // Stores user profile data fetched from Firestore
  String? errorMessage; // To handle errors during NFC read or Firestore fetch

  @override
  void initState() {
    super.initState();
    _startNfcSession();
  }

  Future<void> _startNfcSession() async {
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

              // Remove unnecessary prefix if present (e.g., language prefix)
              if (uid.startsWith('\u0002en')) {
                uid = uid.substring(3);
              }

              await _fetchProfileData(uid);
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

  Future<void> _fetchProfileData(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('user_profiles')
          .doc(uid)
          .get();

      if (doc.exists) {
        setState(() {
          profileData = doc.data()!;
          errorMessage = null; // Clear any previous error messages
        });
      } else {
        setState(() {
          errorMessage = 'No user profile found for UID: $uid.';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching user profile: $e';
      });
    }
  }

  @override
  void dispose() {
    NfcManager.instance.stopSession();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Read NFC Data'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.lightBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: errorMessage != null
              ? Center(
            child: Text(
              errorMessage!,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.redAccent,
              ),
              textAlign: TextAlign.center,
            ),
          )
              : profileData.isNotEmpty
              ? Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'Profile Details',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Divider(color: Colors.blueGrey),
                  SizedBox(height: 10),
                  ...profileData.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${entry.key}: ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.black87,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              entry.value.toString(),
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          )
              : Center(
            child: Text(
              'Tap an NFC tag to read data.',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
