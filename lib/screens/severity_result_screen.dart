import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/constants.dart';
import '../models/accident_report.dart';
import '../widgets/severity_badge.dart';
import '../widgets/action_buttons.dart';
import '../services/contacts_service.dart';
import 'emergency_map_screen.dart';
import 'guidance_screen.dart';

class SeverityResultScreen extends StatefulWidget {
  final AccidentReport report;
  final bool isFromHistory;
  final Future<AccidentReport>? aiAssessmentFuture;

  const SeverityResultScreen({
    super.key, 
    required this.report, 
    this.isFromHistory = false,
    this.aiAssessmentFuture,
  });

  @override
  State<SeverityResultScreen> createState() => _SeverityResultScreenState();
}

class _SeverityResultScreenState extends State<SeverityResultScreen> {
  late AccidentReport _currentReport;

  @override
  void initState() {
    super.initState();
    _currentReport = widget.report;

    // Listen to background AI task if provided
    if (widget.aiAssessmentFuture != null) {
      widget.aiAssessmentFuture!.then((updatedReport) {
        if (mounted) {
          setState(() {
            _currentReport = updatedReport;
          });
          // Show alert to check contacts once AI is actually done
          _checkAndAlertContacts();
        }
      }).catchError((e) {
        debugPrint("AI Future failed in ResultScreen: $e");
      });
    } else if (!widget.isFromHistory) {
      // If there's no future (e.g. offline mode), show immediately
      Future.microtask(() => _checkAndAlertContacts());
    }
  }

  Future<void> _checkAndAlertContacts() async {
    final contactsService = ContactsService();
    final contacts = await contactsService.getContacts();

    if (contacts.isNotEmpty && mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.surfaceCard,
          title: const Text('Alert Emergency Contacts?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("You have saved contacts. Send them an emergency SMS?", style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 12),
              ...contacts.map((c) => Text("• ${c.name} (${c.phone})", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Skip', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _sendEmergencySMS(contacts);
              },
              icon: const Icon(Icons.message, color: Colors.white, size: 16),
              label: const Text('Send SMS', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryRed),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _sendEmergencySMS(List<EmergencyContact> contacts) async {
    final phones = contacts.map((c) => c.phone).join(',');
    final severityName = (_currentReport.severity ?? Severity.minor).name.toUpperCase();
    final message = '''🚨 EMERGENCY ALERT ($severityName) 🚨
I am at: ${_currentReport.locationName}
GPS: https://maps.google.com/?q=${_currentReport.latitude},${_currentReport.longitude}
Please send help!''';

    final uri = Uri.parse('sms:$phones?body=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch SMS app.')));
      }
    }
  }

  void _shareEmergency() {
    final severityName = (_currentReport.severity ?? Severity.minor).name.toUpperCase();
    final message = '''
🚨 EMERGENCY ALERT ($severityName) 🚨
I am at: ${_currentReport.locationName}
GPS: https://maps.google.com/?q=${_currentReport.latitude},${_currentReport.longitude}

Please send help immediately.
(Sent via RoadSOS AI)
''';
    Share.share(message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('ASSESSMENT RESULT', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // AI PENDING BANNER
          if (_currentReport.isPendingAI)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              color: AppColors.secondaryBlue,
              child: const Row(
                children: [
                  SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "AI analyzing scene in background. Universal safety protocols active.",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDesign.standardPadding),
              child: Column(
                children: [
                  // IMAGE THUMBNAIL
                  if (_currentReport.imagePath != null || _currentReport.image != null)
                    Center(
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24, width: 2),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: _currentReport.image != null 
                              ? Image.network(_currentReport.image!.path, fit: BoxFit.cover)
                              : (_currentReport.imagePath != null 
                                  ? Image.network(_currentReport.imagePath!, fit: BoxFit.cover) 
                                  : const Icon(Icons.broken_image, color: Colors.white24)),
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 32),
                  
                  // LARGE SEVERITY BADGE
                  SeverityBadge(severity: _currentReport.severity ?? Severity.minor),
                  
                  const SizedBox(height: 32),
                  
                  // WHAT TO DO NEXT SECTION
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('WHAT TO DO NEXT:', style: AppTextStyles.labelText),
                        const SizedBox(height: 16),
                        
                        // ACTION BUTTONS
                        ActionButton(
                          label: "Find Hospitals Nearby",
                          icon: Icons.local_hospital_rounded,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const EmergencyMapScreen()),
                          ),
                          style: ActionButtonStyle.navigate,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        ActionButton(
                          label: "View Emergency First Aid",
                          icon: Icons.health_and_safety_rounded,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => GuidanceScreen(report: _currentReport)),
                          ),
                          style: ActionButtonStyle.call,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // SHARE BUTTON
                  Align(
                    alignment: Alignment.centerRight,
                    child: FloatingActionButton.extended(
                      onPressed: _shareEmergency,
                      backgroundColor: Colors.white10,
                      icon: const Icon(Icons.share_rounded, color: Colors.white),
                      label: const Text("SHARE LOCATION", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
