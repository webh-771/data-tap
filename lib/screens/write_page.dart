import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';

class WritePage extends StatefulWidget {
  const WritePage({super.key, required this.uid});
  final String uid;

  @override
  State<WritePage> createState() => _WritePageState();
}

class _WritePageState extends State<WritePage> with SingleTickerProviderStateMixin {
  bool _isScanning = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _animation = Tween<double>(begin: 0, end: 100).animate(_animationController)
      ..addListener(() {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _writeToNfc(BuildContext context) async {
    bool isAvailable = await NfcManager.instance.isAvailable();

    if (!isAvailable) {
      _showSnackBar('NFC is not available on this device');
      return;
    }

    // Start ripple animation
    setState(() {
      _isScanning = true;
    });
    _animationController.repeat();

    // Start the NFC session
    NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        try {
          // Convert profile data to a string
          final data = widget.uid;

          // Ensure the data size is within the limit
          if (data.length > 137) {
            _stopScanningAndShow('Data exceeds the tag size limit of 137 bytes');
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
              _stopScanningAndShow('Data written successfully!', success: true);
            } else {
              _stopScanningAndShow('NFC tag is not writable');
            }
          } else {
            _stopScanningAndShow('Tag is not NDEF formatted');
          }
        } catch (e) {
          _stopScanningAndShow('Error: $e');
        } finally {
          NfcManager.instance.stopSession();
        }
      },
    );
  }

  void _stopScanningAndShow(String message, {bool success = false}) {
    setState(() {
      _isScanning = false;
    });
    _animationController.stop();
    _animationController.reset();
    _showSnackBar(message, success: success);
  }

  void _showSnackBar(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Write to NFC'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.8),
              Theme.of(context).colorScheme.background,
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // NFC icon
                Icon(
                  Icons.nfc_rounded,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 32),

                // Information text
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Ready to Write',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap the button below and hold your device near an NFC tag to write your data.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ID: ${widget.uid}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

                // Ripple animation
                if (_isScanning)
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      ...List.generate(3, (index) {
                        return CustomPaint(
                          painter: CirclePainter(
                            _animation.value - (index * 30),
                            Theme.of(context).colorScheme.primary,
                          ),
                          child: const SizedBox(
                            height: 150,
                            width: 150,
                          ),
                        );
                      }),
                      Container(
                        height: 80,
                        width: 80,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.nfc,
                          size: 40,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 48),

                // Write button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isScanning ? null : () => _writeToNfc(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 3,
                    ),
                    child: Text(
                      _isScanning ? 'Scanning...' : 'Write to NFC Tag',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Custom painter for the ripple effect
class CirclePainter extends CustomPainter {
  final double radius;
  final Color color;

  CirclePainter(this.radius, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(1 - radius / 100)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      radius * size.width / 200,
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}