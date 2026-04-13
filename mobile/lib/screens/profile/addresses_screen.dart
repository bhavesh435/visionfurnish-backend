import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/theme.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});
  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  List<_SavedAddress> _addresses = [];
  bool _loading = true;

  static const _storageKey = 'saved_addresses';

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  /// Load addresses from SharedPreferences
  Future<void> _loadAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(raw);
        _addresses = decoded.map((e) => _SavedAddress.fromJson(e)).toList();
      } catch (_) {
        _addresses = [];
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  /// Save addresses to SharedPreferences
  Future<void> _saveAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_addresses.map((a) => a.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  void _showAddDialog() {
    final labelC = TextEditingController();
    final addrC = TextEditingController();
    final cityC = TextEditingController();
    final stateC = TextEditingController();
    final zipC = TextEditingController();
    final phoneC = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Address', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            const SizedBox(height: 20),
            _field(labelC, 'Label (Home, Office, etc.)', Icons.label_outline_rounded),
            const SizedBox(height: 12),
            _field(addrC, 'Street Address *', Icons.location_on_outlined),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _field(cityC, 'City *', Icons.location_city_outlined)),
              const SizedBox(width: 12),
              Expanded(child: _field(stateC, 'State', Icons.map_outlined)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _field(zipC, 'ZIP', Icons.pin_outlined)),
              const SizedBox(width: 12),
              Expanded(child: _field(phoneC, 'Phone *', Icons.phone_outlined)),
            ]),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: () {
                  if (addrC.text.isEmpty || cityC.text.isEmpty) return;
                  setState(() {
                    _addresses.add(_SavedAddress(
                      label: labelC.text.isEmpty ? 'Other' : labelC.text,
                      address: addrC.text, city: cityC.text,
                      state: stateC.text, zip: zipC.text, phone: phoneC.text,
                      isDefault: _addresses.isEmpty, // first address is default
                    ));
                  });
                  _saveAddresses();
                  Navigator.pop(ctx);
                },
                child: const Text('Save Address'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String hint, IconData icon) => TextField(
    controller: c, style: const TextStyle(color: AppTheme.textPrimary),
    decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon, size: 20, color: AppTheme.textMuted)),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        title: Text('My Addresses', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: AppTheme.accent,
        foregroundColor: AppTheme.bgPrimary,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: Text('Add', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : _addresses.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.location_off_rounded, size: 56, color: AppTheme.textMuted),
                  const SizedBox(height: 16),
                  Text('No saved addresses', style: GoogleFonts.inter(fontSize: 16, color: AppTheme.textSecondary)),
                  const SizedBox(height: 8),
                  Text('Tap + to add your first address', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMuted)),
                ]))
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: _addresses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) => _addressCard(_addresses[i], i),
                ),
    );
  }

  Widget _addressCard(_SavedAddress addr, int index) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: addr.isDefault ? AppTheme.accent.withValues(alpha: 0.5) : AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: addr.isDefault ? AppTheme.accent.withValues(alpha: 0.15) : AppTheme.bgSurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(addr.label, style: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: addr.isDefault ? AppTheme.accent : AppTheme.textSecondary,
              )),
            ),
            if (addr.isDefault) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check_circle_rounded, size: 16, color: AppTheme.accent),
              const SizedBox(width: 4),
              Text('Default', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.accent, fontWeight: FontWeight.w600)),
            ],
            const Spacer(),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, size: 20, color: AppTheme.textMuted),
              color: AppTheme.bgElevated,
              onSelected: (val) {
                if (val == 'default') {
                  setState(() {
                    for (var a in _addresses) { a.isDefault = false; }
                    _addresses[index].isDefault = true;
                  });
                  _saveAddresses();
                } else if (val == 'delete') {
                  setState(() => _addresses.removeAt(index));
                  _saveAddresses();
                }
              },
              itemBuilder: (_) => [
                if (!addr.isDefault) const PopupMenuItem(value: 'default', child: Text('Set as Default', style: TextStyle(color: AppTheme.textPrimary))),
                const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppTheme.danger))),
              ],
            ),
          ]),
          const SizedBox(height: 10),
          Text(addr.address, style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textPrimary, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text('${addr.city}${addr.state.isNotEmpty ? ', ${addr.state}' : ''} ${addr.zip}',
              style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary)),
          if (addr.phone.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(addr.phone, style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMuted)),
          ],
        ],
      ),
    );
  }
}

class _SavedAddress {
  final String label;
  final String address;
  final String city;
  final String state;
  final String zip;
  final String phone;
  bool isDefault;

  _SavedAddress({
    required this.label, required this.address, required this.city,
    this.state = '', this.zip = '', this.phone = '', this.isDefault = false,
  });

  Map<String, dynamic> toJson() => {
    'label': label,
    'address': address,
    'city': city,
    'state': state,
    'zip': zip,
    'phone': phone,
    'isDefault': isDefault,
  };

  factory _SavedAddress.fromJson(Map<String, dynamic> j) => _SavedAddress(
    label: j['label'] ?? 'Other',
    address: j['address'] ?? '',
    city: j['city'] ?? '',
    state: j['state'] ?? '',
    zip: j['zip'] ?? '',
    phone: j['phone'] ?? '',
    isDefault: j['isDefault'] == true,
  );
}
