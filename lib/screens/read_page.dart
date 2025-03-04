import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:url_launcher/url_launcher.dart';

class ReadPage extends StatefulWidget {
  const ReadPage({super.key});

  @override
  State<ReadPage> createState() => _ReadPageState();
}

class _ReadPageState extends State<ReadPage> with SingleTickerProviderStateMixin {
  final Map<String, Map<String, dynamic>> allData = {
    'Profile': {},
    'Medical': {},
    'Identification': {},
    'Education': {},
    'Employment': {},
    'Emergency': {},
    'Family': {},
    'Financial': {},
  };

  final Map<String, Color> categoryColors = {
    'Profile': Colors.blue,
    'Medical': Colors.green,
    'Identification': Colors.purple,
    'Education': Colors.teal,
    'Employment': Colors.indigo,
    'Emergency': Colors.red,
    'Family': Colors.amber,
    'Financial': Colors.cyan,
  };

  final Map<String, IconData> categoryIcons = {
    'Profile': Icons.person,
    'Medical': Icons.medical_services,
    'Identification': Icons.badge,
    'Education': Icons.school,
    'Employment': Icons.work,
    'Emergency': Icons.emergency,
    'Family': Icons.family_restroom,
    'Financial': Icons.account_balance,
  };

  String? errorMessage;
  String? selectedRecordKey;
  String selectedMode = 'Profile';
  bool isLoading = false;
  bool isScanning = false;
  String? lastScannedUid;
  bool isCategoryExpanded = true;
  bool showNfcAnimation = true;
  final ScrollController _scrollController = ScrollController();

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
    _scrollController.dispose();
    super.dispose();
  }

  void _startNfcSession() async {
    bool isAvailable = await NfcManager.instance.isAvailable();
    if (!isAvailable) {
      _showSnackBar('NFC is not available on this device.', isError: true);
      return;
    }

    setState(() {
      isScanning = true;
      errorMessage = null;
      showNfcAnimation = true;
    });

    _animationController.repeat();

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
              _stopScanningAndShow('NFC tag read successfully');

              // Vibrate on successful scan
              HapticFeedback.mediumImpact();

              setState(() {
                lastScannedUid = uid;
                showNfcAnimation = false;
              });
              await _fetchData(uid);
            } else {
              _stopScanningAndShow('No NDEF records found on the tag.', isError: true);
            }
          } else {
            _stopScanningAndShow('Tag is not NDEF formatted.', isError: true);
          }
        } catch (e) {
          _stopScanningAndShow('Error reading NFC tag: $e', isError: true);
        } finally {
          NfcManager.instance.stopSession();
        }
      },
    );
  }

  void _stopScanningAndShow(String message, {bool isError = false}) {
    setState(() {
      isScanning = false;
    });
    _animationController.stop();
    _animationController.reset();
    _showSnackBar(message, isError: isError);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 3),
        action: isError
            ? SnackBarAction(
          label: 'Try Again',
          textColor: Colors.white,
          onPressed: () {
            _startNfcSession();
          },
        )
            : null,
      ),
    );
  }

  Future<void> _fetchData(String uid) async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      if (selectedMode == 'Profile') {
        // Profile is directly under users collection
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();

        if (doc.exists) {
          setState(() {
            allData[selectedMode] = doc.data()!;
          });
        } else {
          setState(() {
            errorMessage = "No profile data found for this user.";
            allData[selectedMode] = {};
          });
        }
      } else if (selectedMode == 'Medical') {
        await _fetchMedicalRecords(uid);
      } else if (selectedMode == 'Family') {
        await _fetchSubcollectionData(uid, 'family', 'Family');
      } else if (selectedMode == 'Emergency') {
        await _fetchSubcollectionData(uid, 'emergency_contacts', 'Emergency');
      } else if (selectedMode == 'Financial') {
        await _fetchSubcollectionData(uid, 'finances', 'Financial');
      } else if(selectedMode == 'Identification') {
        await _fetchSubcollectionData(uid, 'identification','Identification');
      }else{
        // For other categories (Identification, Education, Employment)
        // Use the subcollection structure
        final String subcollectionName = selectedMode.toLowerCase();

        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection(subcollectionName)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          // For simplicity, we'll just use the first document
          setState(() {
            allData[selectedMode] = querySnapshot.docs.first.data();
          });
        } else {
          setState(() {
            errorMessage = "No ${selectedMode.toLowerCase()} data found for this user.";
            allData[selectedMode] = {};
          });
        }
      }

      // Collapse category section if data is found (for better focus on data)
      if (allData[selectedMode]!.isNotEmpty && isCategoryExpanded) {
        setState(() {
          isCategoryExpanded = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching data: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });

      // Auto-scroll to data section when new data is loaded
      if (allData[selectedMode]!.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              150,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          }
        });
      }
    }
  }

  Future<void> _fetchMedicalRecords(String uid) async {
    final recordsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('medicalRecords')
        .orderBy('uploadedAt', descending: true)
        .get();

    if (recordsSnapshot.docs.isNotEmpty) {
      setState(() {
        allData['Medical'] = {for (var doc in recordsSnapshot.docs) doc.id: doc.data()};
        selectedRecordKey = allData['Medical']!.keys.first;
      });
    } else {
      setState(() {
        errorMessage = "No medical records found.";
        allData['Medical'] = {};
        selectedRecordKey = null;
      });
    }
  }

  Future<void> _fetchSubcollectionData(String uid, String subcollection, String category) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection(subcollection)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final data = {
        for (var doc in snapshot.docs) doc.id: doc.data()
      };
      setState(() {
        allData[category] = data;
      });
    } else {
      setState(() {
        errorMessage = "No ${category.toLowerCase()} data found.";
        allData[category] = {};
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart ID Reader', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        elevation: 2,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
        actions: [
          // Refresh button
          if (lastScannedUid != null)
            IconButton(
              icon: Icon(
                  Icons.refresh_rounded,
                  color: Theme.of(context).colorScheme.onPrimaryContainer
              ),
              onPressed: () {
                if (lastScannedUid != null) {
                  _fetchData(lastScannedUid!);
                  _showSnackBar('Refreshing data...');
                }
              },
              tooltip: 'Refresh Data',
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4),
              Theme.of(context).colorScheme.background,
            ],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              if (lastScannedUid != null) {
                await _fetchData(lastScannedUid!);
              }
            },
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                // Category Section with improved UI
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Header with toggle button
                      InkWell(
                        onTap: () {
                          setState(() {
                            isCategoryExpanded = !isCategoryExpanded;
                          });

                          // Haptic feedback
                          HapticFeedback.lightImpact();
                        },
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.category_rounded,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Information Categories',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                              // Animated rotation for the arrow icon
                              TweenAnimationBuilder<double>(
                                tween: Tween<double>(
                                  begin: isCategoryExpanded ? 0 : 0.5,
                                  end: isCategoryExpanded ? 0 : 0.5,
                                ),
                                duration: const Duration(milliseconds: 300),
                                builder: (context, value, child) {
                                  return Transform.rotate(
                                    angle: value * pi,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.expand_more,
                                        color: Theme.of(context).colorScheme.primary,
                                        size: 20,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Expandable content with improved UI
                      AnimatedCrossFade(
                        firstChild: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          child: _buildCategoryChips(),
                        ),
                        secondChild: const SizedBox(height: 0),
                        crossFadeState: isCategoryExpanded
                            ? CrossFadeState.showFirst
                            : CrossFadeState.showSecond,
                        duration: const Duration(milliseconds: 300),
                      ),
                    ],
                  ),
                ),

                // Selected category indicator (visible when categories are collapsed)
                if (!isCategoryExpanded)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: categoryColors[selectedMode]!.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: categoryColors[selectedMode]!.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: categoryColors[selectedMode]!.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            categoryIcons[selectedMode],
                            color: categoryColors[selectedMode],
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          selectedMode,
                          style: TextStyle(
                            color: categoryColors[selectedMode],
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        InkWell(
                          onTap: () {
                            setState(() {
                              isCategoryExpanded = true;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: categoryColors[selectedMode]!.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.edit,
                              color: categoryColors[selectedMode],
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Scan Button and Animation with improved UI
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: categoryColors[selectedMode]!.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: isScanning ? 240 : (showNfcAnimation && lastScannedUid == null ? 220 : 80),
                    child: Center(
                      child: isScanning
                          ? _buildScanningAnimation()
                          : (showNfcAnimation && lastScannedUid == null)
                          ? _buildNfcIntroduction()
                          : _buildScanButton(),
                    ),
                  ),
                ),

                // UID display if scanned with improved styling
                if (lastScannedUid != null && !isScanning)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: categoryColors[selectedMode]!.withOpacity(0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: categoryColors[selectedMode]!.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.perm_identity,
                            size: 24,
                            color: categoryColors[selectedMode],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Scanned ID',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                                ),
                              ),
                              Text(
                                lastScannedUid!,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Button to copy UID
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: lastScannedUid!));
                              _showSnackBar('ID copied to clipboard');
                              HapticFeedback.lightImpact();
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: categoryColors[selectedMode]!.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.copy,
                                    size: 16,
                                    color: categoryColors[selectedMode],
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Copy',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: categoryColors[selectedMode],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Loading indicator with improved styling
                if (isLoading)
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 60,
                          width: 60,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              categoryColors[selectedMode]!,
                            ),
                            strokeWidth: 4,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Loading ${selectedMode.toLowerCase()} data...',
                          style: TextStyle(
                            color: categoryColors[selectedMode],
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Error message with improved styling
                if (errorMessage != null)
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.red.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.error_outline, color: Colors.red.shade700),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Error',
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          errorMessage!,
                          style: TextStyle(color: Colors.red.shade700, fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.refresh, size: 18),
                              label: const Text('Try Again'),
                              onPressed: () {
                                if (lastScannedUid != null) {
                                  _fetchData(lastScannedUid!);
                                } else {
                                  _startNfcSession();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.red.shade700,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                // Data display with improved styling
                if (selectedMode == 'Medical' && allData['Medical']!.isNotEmpty)
                  _buildMedicalRecordCard()
                else if (allData[selectedMode]!.isNotEmpty)
                  _buildDataCard(allData[selectedMode]!, categoryColors[selectedMode]!)
                else if (lastScannedUid != null && !isLoading && errorMessage == null)
                    _buildEmptyState()
                  else if (!isScanning && lastScannedUid == null && !isLoading && !showNfcAnimation)
                      _buildInitialState(),

                // Add bottom padding for better scrolling
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
      // Floating action button to scan with improved UI
      floatingActionButton: !isScanning && lastScannedUid != null ?
      FloatingActionButton.extended(
        onPressed: _startNfcSession,
        backgroundColor: categoryColors[selectedMode],
        icon: const Icon(Icons.nfc, color: Colors.white),
        label: const Text('Scan New ID', style: TextStyle(color: Colors.white)),
        elevation: 4,
      ) : null,
    );
  }

  Widget _buildScanningAnimation() {
    return Stack(
      alignment: Alignment.center,
      children: [
        ...List.generate(3, (index) {
          return CustomPaint(
            painter: CirclePainter(
              _animation.value - (index * 30),
              categoryColors[selectedMode]!,
            ),
            child: const SizedBox(
              height: 220,
              width: 220,
            ),
          );
        }),
        Container(
          height: 80,
          width: 80,
          decoration: BoxDecoration(
            color: categoryColors[selectedMode],
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: categoryColors[selectedMode]!.withOpacity(0.3),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.nfc,
            size: 40,
            color: Colors.white,
          ),
        ),
        Positioned(
          bottom: 30,
          child: Column(
            children: [
              Text(
                'Looking for NFC tag',
                style: TextStyle(
                  color: categoryColors[selectedMode],
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Hold your device near the ID card',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  NfcManager.instance.stopSession();
                  setState(() {
                    isScanning = false;
                  });
                  _animationController.stop();
                  _animationController.reset();
                },
                icon: const Icon(Icons.cancel, size: 16),
                label: const Text('Cancel'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.grey.shade800,
                  backgroundColor: Colors.grey.shade200,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNfcIntroduction() {
    return Padding(
        padding: const EdgeInsets.all(20.0),
    child: SingleChildScrollView(
    child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
    Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
    Stack(
    alignment: Alignment.center,
    children: [
    TweenAnimationBuilder<double>(
    tween: Tween<double>(begin: 0.8, end: 1.2),
    duration: const Duration(seconds: 1),
    builder: (context, value, child) {
    return Transform.scale(
    scale: value,
    child: Container(
    width: 60,
    height: 60,
    decoration: BoxDecoration(
    color: categoryColors[selectedMode]!.withOpacity(0.1),
    shape: BoxShape.circle,
    ),
    ),
    );
    },
    onEnd: () {
    setState(() {});
    },
    ),
    Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
    color: categoryColors[selectedMode]!.withOpacity(0.2),
    shape: BoxShape.circle,
    ),
    child: Icon(
    Icons.nfc,
    size: 32,
    color: categoryColors[selectedMode],
    ),
    ),
    ],
    ),
    const SizedBox(width: 20),
    Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
    color: Colors.grey.shade100,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
    color: Colors.grey.shade300,
      width: 1,
    ),
    ),
      child: Icon(
        Icons.credit_card,
        size: 32,
        color: Colors.grey.shade700,
      ),
    ),
    ],
    ),
      const SizedBox(height: 20),
      Text(
        'Scan Smart ID Card',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      const SizedBox(height: 12),
      Text(
        'Tap the button below and hold your device near an ID card to scan',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade600,
        ),
      ),
      const SizedBox(height: 16),
      ElevatedButton.icon(
        onPressed: _startNfcSession,
        icon: Icon(
          Icons.nfc,
          color: Colors.white,
          size: 20,
        ),
        label: const Text(
          'Start Scanning',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: categoryColors[selectedMode],
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    ],
    ),
    ),
    );
  }

  Widget _buildScanButton() {
    return ElevatedButton.icon(
      onPressed: _startNfcSession,
      icon: Icon(
        Icons.nfc,
        color: Colors.white,
        size: 20,
      ),
      label: const Text(
        'Tap to Scan ID Card',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: categoryColors[selectedMode],
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: categoryColors[selectedMode]!.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              categoryIcons[selectedMode],
              size: 40,
              color: categoryColors[selectedMode]!.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No ${selectedMode.toLowerCase()} data found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'This ID card does not contain ${selectedMode.toLowerCase()} data or you may not have permission to access it.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {
              // Change mode to another category
              setState(() {
                isCategoryExpanded = true;
              });
            },
            icon: const Icon(Icons.category, size: 18),
            label: const Text('Try Another Category'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(color: categoryColors[selectedMode]!),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialState() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.info_outline,
              size: 40,
              color: Colors.blue.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Ready to Scan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Please scan an ID card to view information in your selected category.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _startNfcSession,
            icon: const Icon(Icons.nfc, color: Colors.white, size: 18),
            label: const Text('Start Scanning', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataCard(Map<String, dynamic> data, Color color) {
    // Filter out null and empty values
    final filteredData = Map<String, dynamic>.from(data)
      ..removeWhere((key, value) => value == null || (value is String && value.isEmpty));

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Icon(categoryIcons[selectedMode], size: 24, color: color),
                const SizedBox(width: 12),
                Text(
                  '$selectedMode Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // If data is nested (e.g., for family, emergency, financial)
                if (data.values.any((v) => v is Map))
                  ...data.entries.map((entry) {
                    if (entry.value is Map) {
                      final Map<String, dynamic> subData = Map<String, dynamic>.from(entry.value as Map);
                      return _buildNestedDataItem(entry.key, subData, color);
                    } else {
                      return _buildDataItem(entry.key, entry.value, color);
                    }
                  }).toList()
                else
                  ...filteredData.entries.map((entry) {
                    return _buildDataItem(entry.key, entry.value, color);
                  }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNestedDataItem(String title, Map<String, dynamic> data, Color color) {
    // Filter out null and empty values
    final filteredData = Map<String, dynamic>.from(data)
      ..removeWhere((key, value) => value == null || (value is String && value.isEmpty));

    if (filteredData.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatFieldName(title),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 12),
          ...filteredData.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_formatFieldName(entry.key)}: ',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _formatValue(entry.value),
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildDataItem(String field, dynamic value, Color color) {
    if (field == 'photoUrl' && value is String && value.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Photo',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  value,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image, color: color.withOpacity(0.5), size: 40),
                          const SizedBox(height: 8),
                          Text(
                            'Unable to load image',
                            style: TextStyle(color: color.withOpacity(0.7)),
                          ),
                          TextButton(
                            onPressed: () {
                              launchUrl(Uri.parse(value));
                            },
                            child: const Text('Open in Browser'),
                          ),
                        ],
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                            : null,
                        color: color,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Skip non-user-friendly fields
    if (['id', 'uid', 'userId', 'createdAt', 'updatedAt', 'documentId'].contains(field)) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatFieldName(field),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          _buildValueWidget(field, value, color),
        ],
      ),
    );
  }

  Widget _buildValueWidget(String field, dynamic value, Color color) {
    // Handle different types of values
    if (value is Timestamp) {
      final date = value.toDate();
      return Text(
        DateFormat('MMM d, yyyy').format(date),
        style: const TextStyle(fontSize: 16),
      );
    } else if (value is bool) {
      return Row(
        children: [
          Icon(
            value ? Icons.check_circle : Icons.cancel,
            color: value ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            value ? 'Yes' : 'No',
            style: const TextStyle(fontSize: 16),
          ),
        ],
      );
    } else if (field.toLowerCase().contains('phone')) {
      return InkWell(
        onTap: () {
          launchUrl(Uri.parse('tel:$value'));
        },
        child: Row(
          children: [
            Text(
              _formatValue(value),
              style: TextStyle(
                fontSize: 16,
                color: color,
                decoration: TextDecoration.underline,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.phone, size: 16, color: color),
          ],
        ),
      );
    } else if (field.toLowerCase().contains('email')) {
      return InkWell(
        onTap: () {
          launchUrl(Uri.parse('mailto:$value'));
        },
        child: Row(
          children: [
            Text(
              _formatValue(value),
              style: TextStyle(
                fontSize: 16,
                color: color,
                decoration: TextDecoration.underline,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.email, size: 16, color: color),
          ],
        ),
      );
    } else if (field.toLowerCase().contains('website') || field.toLowerCase().contains('url')) {
      return InkWell(
        onTap: () {
          launchUrl(Uri.parse(value.toString().startsWith('http') ? value : 'https://$value'));
        },
        child: Row(
          children: [
            Expanded(
              child: Text(
                _formatValue(value),
                style: TextStyle(
                  fontSize: 16,
                  color: color,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.open_in_new, size: 16, color: color),
          ],
        ),
      );
    } else if (field.toLowerCase().contains('address')) {
      return InkWell(
        onTap: () {
          launchUrl(Uri.parse('https://maps.google.com/?q=${Uri.encodeComponent(value.toString())}'));
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                _formatValue(value),
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.map, size: 16, color: color),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(top: 2.0),
        child: Text(
          _formatValue(value),
          style: const TextStyle(fontSize: 16),
        ),
      );
    }
  }

  String _formatValue(dynamic value) {
    if (value == null) return 'Not provided';

    if (value is Timestamp) {
      return DateFormat('MMM d, yyyy').format(value.toDate());
    } else if (value is DateTime) {
      return DateFormat('MMM d, yyyy').format(value);
    } else if (value is bool) {
      return value ? 'Yes' : 'No';
    } else if (value is Map) {
      return value.entries.map((e) => '${e.key}: ${e.value}').join(', ');
    } else if (value is List) {
      return value.join(', ');
    }

    return value.toString();
  }

  String _formatFieldName(String name) {
    // Convert camelCase or snake_case to Title Case
    String result = name.replaceAllMapped(
      RegExp(r'([A-Z])'),
          (Match match) => ' ${match[1]}',
    );

    result = result.replaceAll('_', ' ');

    // Handle special abbreviations
    result = result
        .replaceAll(' Id', ' ID')
        .replaceAll(' Dob', ' DOB')
        .replaceAll(' Ssn', ' SSN')
        .replaceAll(' Url', ' URL');

    // Capitalize first letter of each word
    result = result.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');

    return result;
  }

  Widget _buildMedicalRecordCard() {
    final records = allData['Medical']! as Map<String, dynamic>;
    final recordKeys = records.keys.toList();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: categoryColors['Medical']!.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: categoryColors['Medical']!.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Icon(categoryIcons['Medical'], size: 24, color: categoryColors['Medical']),
                const SizedBox(width: 12),
                Text(
                  'Medical Records',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: categoryColors['Medical'],
                  ),
                ),
              ],
            ),
          ),

          // Record selector (if multiple records exist)
          if (recordKeys.length > 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Record',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedRecordKey,
                        isExpanded: true,
                        icon: Icon(Icons.arrow_drop_down, color: categoryColors['Medical']),
                        items: recordKeys.map((String key) {
                          final record = records[key] as Map<String, dynamic>;
                          String displayText = 'Record';

                          if (record.containsKey('recordType')) {
                            displayText = record['recordType'].toString();
                          } else if (record.containsKey('type')) {
                            displayText = record['type'].toString();
                          }

                          if (record.containsKey('uploadedAt')) {
                            final date = record['uploadedAt'] is Timestamp
                                ? (record['uploadedAt'] as Timestamp).toDate()
                                : DateTime.now();
                            displayText += ' (${DateFormat('MMM d, yyyy').format(date)})';
                          }

                          return DropdownMenuItem<String>(
                            value: key,
                            child: Text(
                              displayText,
                              style: const TextStyle(fontSize: 15),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              selectedRecordKey = newValue;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Record content
          if (selectedRecordKey != null)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _buildMedicalRecordContent(records[selectedRecordKey] as Map<String, dynamic>),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildMedicalRecordContent(Map<String, dynamic> recordData) {
    final widgets = <Widget>[];
    final priorityFields = ['recordType', 'type', 'condition', 'doctor', 'hospital', 'date', 'diagnosis', 'treatment'];

    // First display priority fields in order
    for (final field in priorityFields) {
      if (recordData.containsKey(field)) {
        widgets.add(_buildDataItem(field, recordData[field], categoryColors['Medical']!));
      }
    }

    // Then display remaining fields
    for (final entry in recordData.entries) {
      if (!priorityFields.contains(entry.key) &&
          !['id', 'userId', 'uploadedAt', 'createdAt', 'updatedAt'].contains(entry.key)) {
        widgets.add(_buildDataItem(entry.key, entry.value, categoryColors['Medical']!));
      }
    }

    // If a file URL exists, show it at the bottom
    if (recordData.containsKey('fileUrl') && recordData['fileUrl'] is String && recordData['fileUrl'].isNotEmpty) {
      widgets.add(const SizedBox(height: 16));
      widgets.add(
        OutlinedButton.icon(
          onPressed: () {
            launchUrl(Uri.parse(recordData['fileUrl']));
          },
          icon: const Icon(Icons.file_present),
          label: const Text('View Full Medical Record'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            side: BorderSide(color: categoryColors['Medical']!),
          ),
        ),
      );
    }

    return widgets;
  }

  Widget _buildCategoryChips() {
    return Wrap(
      spacing: 8.0,
      runSpacing: 12.0,
      children: categoryColors.keys.map((String category) {
        final bool isSelected = selectedMode == category;
        return ChoiceChip(
          label: Text(category),
          selected: isSelected,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : categoryColors[category],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          backgroundColor: categoryColors[category]!.withOpacity(0.1),
          selectedColor: categoryColors[category],
          avatar: Icon(
            categoryIcons[category],
            size: 18,
            color: isSelected ? Colors.white : categoryColors[category],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: isSelected ? Colors.transparent : categoryColors[category]!.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          onSelected: (bool selected) {
            if (selected) {
              setState(() {
                selectedMode = category;
                selectedRecordKey = null;
              });
              if (lastScannedUid != null) {
                _fetchData(lastScannedUid!);
              }

              // Haptic feedback
              HapticFeedback.selectionClick();
            }
          },
        );
      }).toList(),
    );
  }
}

class CirclePainter extends CustomPainter {
  final double radius;
  final Color color;

  CirclePainter(this.radius, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color.withOpacity((100 - radius) / 100)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      radius * size.width / 200,
      paint,
    );
  }

  @override
  bool shouldRepaint(CirclePainter oldDelegate) {
    return oldDelegate.radius != radius;
  }
}