import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../services/contacts_service.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final ContactsService _contactsService = ContactsService();
  List<EmergencyContact> _contacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final contacts = await _contactsService.getContacts();
    if (mounted) {
      setState(() {
        _contacts = contacts;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveContact(String name, String phone) async {
    final newContact = EmergencyContact(name: name, phone: phone);
    setState(() {
      _contacts.add(newContact);
    });
    await _contactsService.saveContacts(_contacts);
  }

  Future<void> _deleteContact(int index) async {
    setState(() {
      _contacts.removeAt(index);
    });
    await _contactsService.saveContacts(_contacts);
  }

  void _showAddContactDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceCard,
          title: const Text('Add Emergency Contact', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Name', labelStyle: TextStyle(color: Colors.white54)),
              ),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Phone Number', labelStyle: TextStyle(color: Colors.white54)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.primaryRed)),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty && phoneController.text.isNotEmpty) {
                  _saveContact(nameController.text, phoneController.text);
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.safetyGreen),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('EMERGENCY CONTACTS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.primaryRed))
        : Padding(
            padding: const EdgeInsets.all(AppDesign.standardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "We'll ask if you want to alert these contacts when you report an accident.",
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: _contacts.isEmpty
                    ? const Center(child: Text("No contacts saved.", style: TextStyle(color: Colors.white54)))
                    : ListView.builder(
                        itemCount: _contacts.length,
                        itemBuilder: (context, index) {
                          final contact = _contacts[index];
                          return Card(
                            color: AppColors.surfaceCard,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: const Icon(Icons.person, color: AppColors.secondaryBlue),
                              title: Text(contact.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              subtitle: Text(contact.phone, style: const TextStyle(color: Colors.white70)),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: AppColors.primaryRed),
                                onPressed: () => _deleteContact(index),
                              ),
                            ),
                          );
                        },
                      ),
                ),
                if (_contacts.length < 3)
                  ElevatedButton.icon(
                    onPressed: _showAddContactDialog,
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text("ADD CONTACT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  )
                else
                  const Center(child: Text("Maximum 3 contacts reached.", style: TextStyle(color: AppColors.warningOrange))),
              ],
            ),
          ),
    );
  }
}
