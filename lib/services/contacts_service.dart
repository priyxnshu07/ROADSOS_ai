import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class EmergencyContact {
  final String name;
  final String phone;

  EmergencyContact({required this.name, required this.phone});

  Map<String, dynamic> toJson() => {
    'name': name,
    'phone': phone,
  };

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      name: json['name'],
      phone: json['phone'],
    );
  }
}

class ContactsService {
  static const String _contactsKey = 'roadsos_contacts';

  Future<List<EmergencyContact>> getContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? contactsJson = prefs.getString(_contactsKey);
    if (contactsJson == null) return [];
    
    final List<dynamic> decoded = jsonDecode(contactsJson);
    return decoded.map((c) => EmergencyContact.fromJson(c)).toList();
  }

  Future<void> saveContacts(List<EmergencyContact> contacts) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(contacts.map((c) => c.toJson()).toList());
    await prefs.setString(_contactsKey, encoded);
  }
}
