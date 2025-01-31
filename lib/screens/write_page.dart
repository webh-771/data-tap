import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';

class WritePage extends StatelessWidget {
  const WritePage({super.key, required this.uid});
  final String uid;

  Future<void> _writeToNfc(BuildContext context) async {
    bool isAvailable = await NfcManager.instance.isAvailable();

    if (!isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('NFC is not available on this device')),
      );
      return;
    }

    // Start the NFC session
    NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        try {
          // Convert profile data to a string
          final data = uid;

          // Ensure the data size is within the limit
          if (data.length > 137) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Data exceeds the tag size limit of 137 bytes')),
            );
            NfcManager.instance.stopSession();
            return;
          }

          // Create an NDEF message
          final ndefRecord = NdefRecord.createText(data);
          final ndefMessage = NdefMessage([ndefRecord]);

          // Check if the tag is NDEF
          final ndef = Ndef.from(tag);
          if (ndef != null) {
            if (ndef.isWritable) {
              // Write the NDEF message to the tag
              await ndef.write(ndefMessage);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Data written successfully!')),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('NFC tag is not writable')),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Tag is not NDEF formatted')),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        } finally {
          NfcManager.instance.stopSession();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Write Data to NFC'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Tap an NFC tag to write your data.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _writeToNfc(context),
              child: Text('Write to NFC'),
            ),
          ],
        ),
      ),
    );
  }
}
