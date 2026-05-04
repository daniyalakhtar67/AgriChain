// lib/utils/payment_methods.dart
// ── Shared Payment Methods ───────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Payment method types ─────────────────────────────────────────────────────
enum AccountType { phone, iban, none }

class PaymentMethod {
  final String id;
  final String name;
  final String hint;
  final AccountType accountType;
  final Color brandColor;
  final Color brandTextColor;
  final Widget logo;

  const PaymentMethod({
    required this.id,
    required this.name,
    required this.hint,
    required this.accountType,
    required this.brandColor,
    required this.brandTextColor,
    required this.logo,
  });

  bool get requiresAccount => accountType != AccountType.none;
}

// ── Brand Logos ───────────────────────────────────────────────────────────────

Widget _easypaisaLogo() => Container(
  width: 32,
  height: 32,
  decoration: BoxDecoration(
    color: const Color(0xFF6CC04A),
    borderRadius: BorderRadius.circular(8),
  ),
  child: Center(
    child: Text('EP',
        style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold)),
  ),
);

Widget _jazzcashLogo() => Container(
  width: 32,
  height: 32,
  decoration: BoxDecoration(
    color: const Color(0xFFCC0000),
    borderRadius: BorderRadius.circular(8),
  ),
  child: Center(
    child: Text('JC',
        style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold)),
  ),
);

Widget _nayapayLogo() => Container(
  width: 32,
  height: 32,
  decoration: BoxDecoration(
    color: const Color(0xFF6C3FC5),
    borderRadius: BorderRadius.circular(8),
  ),
  child: Center(
    child: Text('NP',
        style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold)),
  ),
);

Widget _meezanLogo() => Container(
  width: 32,
  height: 32,
  decoration: BoxDecoration(
    color: const Color(0xFF006747),
    borderRadius: BorderRadius.circular(8),
  ),
  child: Center(
    child: Text('MB',
        style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold)),
  ),
);

Widget _ublLogo() => Container(
  width: 32,
  height: 32,
  decoration: BoxDecoration(
    color: const Color(0xFF003087),
    borderRadius: BorderRadius.circular(8),
  ),
  child: Center(
    child: Text('UBL',
        style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.bold)),
  ),
);

Widget _habibLogo() => Container(
  width: 32,
  height: 32,
  decoration: BoxDecoration(
    color: const Color(0xFF1A5276),
    borderRadius: BorderRadius.circular(8),
  ),
  child: Center(
    child: Text('HBL',
        style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.bold)),
  ),
);

Widget _cashLogo() => Container(
  width: 32,
  height: 32,
  decoration: BoxDecoration(
    color: const Color(0xFF27AE60),
    borderRadius: BorderRadius.circular(8),
  ),
  child: const Center(
    child: Icon(Icons.local_shipping_outlined, color: Colors.white, size: 18),
  ),
);

// ── Payment Methods List ──────────────────────────────────────────────────────

final List<PaymentMethod> kPaymentMethods = [
  PaymentMethod(
    id: 'easypaisa',
    name: 'EasyPaisa',
    hint: '03XX-XXXXXXX (11 digits)',
    accountType: AccountType.phone,
    brandColor: const Color(0xFF6CC04A),
    brandTextColor: Colors.white,
    logo: _easypaisaLogo(),
  ),
  PaymentMethod(
    id: 'jazzcash',
    name: 'JazzCash',
    hint: '03XX-XXXXXXX (11 digits)',
    accountType: AccountType.phone,
    brandColor: const Color(0xFFCC0000),
    brandTextColor: Colors.white,
    logo: _jazzcashLogo(),
  ),
  PaymentMethod(
    id: 'nayapay',
    name: 'NayaPay',
    hint: '03XX-XXXXXXX (11 digits)',
    accountType: AccountType.phone,
    brandColor: const Color(0xFF6C3FC5),
    brandTextColor: Colors.white,
    logo: _nayapayLogo(),
  ),
  PaymentMethod(
    id: 'meezan',
    name: 'Meezan Bank',
    hint: 'PKXX MEZN XXXX XXXX XXXX XXXX XX (24 chars after PK)',
    accountType: AccountType.iban,
    brandColor: const Color(0xFF006747),
    brandTextColor: Colors.white,
    logo: _meezanLogo(),
  ),
  PaymentMethod(
    id: 'ubl',
    name: 'UBL',
    hint: 'PKXX UNIL XXXX XXXX XXXX XXXX XX (24 chars after PK)',
    accountType: AccountType.iban,
    brandColor: const Color(0xFF003087),
    brandTextColor: Colors.white,
    logo: _ublLogo(),
  ),
  PaymentMethod(
    id: 'habib',
    name: 'Habib Bank',
    hint: 'PKXX HABB XXXX XXXX XXXX XXXX XX (24 chars after PK)',
    accountType: AccountType.iban,
    brandColor: const Color(0xFF1A5276),
    brandTextColor: Colors.white,
    logo: _habibLogo(),
  ),
  PaymentMethod(
    id: 'cash_on_del',
    name: 'Cash on Delivery',
    hint: '',
    accountType: AccountType.none,
    brandColor: const Color(0xFF27AE60),
    brandTextColor: Colors.white,
    logo: _cashLogo(),
  ),
];

// ── Validation helpers ────────────────────────────────────────────────────────

bool isValidPakistanPhone(String val) {
  final digits = val.replaceAll(RegExp(r'\D'), '');
  return digits.length == 11 && digits.startsWith('03');
}

bool isValidIBAN(String val) {
  final clean = val.replaceAll(RegExp(r'\s'), '').toUpperCase();
  return RegExp(r'^PK\d{2}[A-Z]{4}\d{16}$').hasMatch(clean);
}

String? validateAccount(PaymentMethod method, String val) {
  if (method.accountType == AccountType.phone) {
    if (!isValidPakistanPhone(val)) {
      return 'Enter valid 11-digit number starting with 03';
    }
  } else if (method.accountType == AccountType.iban) {
    if (!isValidIBAN(val)) {
      return 'Enter valid IBAN: PK + 2 digits + 4 letters + 16 digits';
    }
  }
  return null;
}

// ── Helper: parse payment_methods_json safely ────────────────────────────────
/// Returns a list of {name, account} maps from the jsonb column.
/// Falls back to legacy single payment_method / payment_account fields.
List<Map<String, String>> parsePaymentMethods(Map<String, dynamic> product) {
  final jsonList = product['payment_methods_json'];
  if (jsonList != null && jsonList is List && jsonList.isNotEmpty) {
    return jsonList
        .map<Map<String, String>>((e) => {
      'id': (e['id'] ?? '').toString(),
      'name': (e['name'] ?? '').toString(),
      'account': (e['account'] ?? '').toString(),
    })
        .toList();
  }
  // Legacy fallback
  final legacyMethod = (product['payment_method'] ?? '').toString().trim();
  final legacyAccount = (product['payment_account'] ?? '').toString().trim();
  if (legacyMethod.isNotEmpty) {
    return [
      {'id': '', 'name': legacyMethod, 'account': legacyAccount}
    ];
  }
  return [];
}

// ── PaymentSelector Widget (single-select — used in BuyNow / Cart) ────────────

class PaymentSelector extends StatelessWidget {
  final String? selectedId;
  final ValueChanged<String> onChanged;
  final TextEditingController accountController;
  final Color accentColor;

  const PaymentSelector({
    super.key,
    required this.selectedId,
    required this.onChanged,
    required this.accountController,
    this.accentColor = Colors.green,
  });

  @override
  Widget build(BuildContext context) {
    final selected = selectedId != null
        ? kPaymentMethods.firstWhere((m) => m.id == selectedId,
        orElse: () => kPaymentMethods.first)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Method *',
          style: GoogleFonts.poppins(
            color: accentColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: kPaymentMethods.map((method) {
            final isSelected = selectedId == method.id;
            return GestureDetector(
              onTap: () => onChanged(method.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected
                      ? method.brandColor.withValues(alpha: 0.22)
                      : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isSelected ? method.brandColor : Colors.white24,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child:
                        FittedBox(fit: BoxFit.cover, child: method.logo),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      method.name,
                      style: GoogleFonts.poppins(
                        color:
                        isSelected ? method.brandColor : Colors.white70,
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        if (selected != null && selected.requiresAccount) ...[
          const SizedBox(height: 14),
          _AccountField(
            method: selected,
            controller: accountController,
            accentColor: selected.brandColor,
          ),
        ],
      ],
    );
  }
}

// ── MultiPaymentSelector Widget (multi-select — used when adding crops) ───────

class MultiPaymentSelector extends StatelessWidget {
  final List<String> selectedIds;
  final ValueChanged<List<String>> onChanged;
  final Map<String, TextEditingController> accountControllers;
  final Color accentColor;

  const MultiPaymentSelector({
    super.key,
    required this.selectedIds,
    required this.onChanged,
    required this.accountControllers,
    this.accentColor = Colors.green,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.payment, color: accentColor, size: 16),
            const SizedBox(width: 6),
            Text(
              'Payment Methods *',
              style: GoogleFonts.poppins(
                color: accentColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Ek ya zyada select kar sakte ho',
          style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11),
        ),
        const SizedBox(height: 10),

        // ── Multi-select chip grid ──
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: kPaymentMethods.map((method) {
            final isSelected = selectedIds.contains(method.id);
            return GestureDetector(
              onTap: () {
                final updated = List<String>.from(selectedIds);
                if (isSelected) {
                  updated.remove(method.id);
                  accountControllers[method.id]?.dispose();
                  accountControllers.remove(method.id);
                } else {
                  updated.add(method.id);
                  if (method.requiresAccount) {
                    accountControllers.putIfAbsent(
                        method.id, () => TextEditingController());
                  }
                }
                onChanged(updated);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected
                      ? method.brandColor.withValues(alpha: 0.22)
                      : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isSelected ? method.brandColor : Colors.white24,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child:
                        FittedBox(fit: BoxFit.cover, child: method.logo),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      method.name,
                      style: GoogleFonts.poppins(
                        color:
                        isSelected ? method.brandColor : Colors.white70,
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.normal,
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 5),
                      Icon(Icons.check_circle,
                          color: method.brandColor, size: 13),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),

        // ── Account input for each selected method that requires one ──
        ...selectedIds.map((id) {
          final method = kPaymentMethods.firstWhere((m) => m.id == id,
              orElse: () => kPaymentMethods.first);
          if (!method.requiresAccount) return const SizedBox.shrink();
          accountControllers.putIfAbsent(
              id, () => TextEditingController());
          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: _AccountField(
              method: method,
              controller: accountControllers[id]!,
              accentColor: method.brandColor,
            ),
          );
        }).toList(),
      ],
    );
  }
}

// ── Account input field with live format hint + validation ───────────────────

class _AccountField extends StatefulWidget {
  final PaymentMethod method;
  final TextEditingController controller;
  final Color accentColor;

  const _AccountField({
    required this.method,
    required this.controller,
    required this.accentColor,
  });

  @override
  State<_AccountField> createState() => _AccountFieldState();
}

class _AccountFieldState extends State<_AccountField> {
  String? _error;

  void _validate(String val) {
    setState(() {
      _error = val.isEmpty ? null : validateAccount(widget.method, val);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = widget.method.accountType == AccountType.phone;
    final isIban = widget.method.accountType == AccountType.iban;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: widget.accentColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: widget.accentColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(
                isPhone ? Icons.phone_android : Icons.account_balance,
                color: widget.accentColor,
                size: 14,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  isPhone
                      ? 'Format: 03XXXXXXXXX  (11 digits)'
                      : 'Format: PK + 2 digits + 4 letters + 16 digits\nExample: PK36MEZN0001230123456702',
                  style: GoogleFonts.poppins(
                    color: widget.accentColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: widget.controller,
          onChanged: _validate,
          keyboardType:
          isPhone ? TextInputType.phone : TextInputType.text,
          inputFormatters: isPhone
              ? [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(11),
          ]
              : isIban
              ? [
            _IbanFormatter(),
            LengthLimitingTextInputFormatter(29),
          ]
              : [],
          style:
          const TextStyle(color: Colors.white, letterSpacing: 1.2),
          decoration: InputDecoration(
            labelText: isPhone
                ? '${widget.method.name} Number'
                : '${widget.method.name} IBAN',
            labelStyle: TextStyle(
                color: widget.accentColor.withValues(alpha: 0.8)),
            hintText: isPhone ? '03XXXXXXXXX' : 'PK36XXXX...',
            hintStyle:
            const TextStyle(color: Colors.white30, fontSize: 12),
            prefixIcon: Icon(
              isPhone ? Icons.phone_android : Icons.account_balance,
              color: widget.accentColor,
            ),
            suffixIcon:
            _error == null && widget.controller.text.isNotEmpty
                ? const Icon(Icons.check_circle,
                color: Colors.greenAccent, size: 20)
                : null,
            errorText: _error,
            errorStyle: GoogleFonts.poppins(
                color: Colors.redAccent, fontSize: 10),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.06),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color:
                  _error != null ? Colors.redAccent : Colors.white24),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: widget.accentColor),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
          ),
        ),
      ],
    );
  }
}

// ── IBAN auto-formatter ───────────────────────────────────────────────────────
class _IbanFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final clean = newValue.text.replaceAll(' ', '').toUpperCase();
    final buffer = StringBuffer();
    for (int i = 0; i < clean.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(clean[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// ── Shared dialog text field ──────────────────────────────────────────────────
Widget dialogField(
    String label,
    TextEditingController c,
    IconData icon, {
      Color accentColor = Colors.green,
      TextInputType keyboardType = TextInputType.text,
      int maxLines = 1,
    }) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(
      controller: c,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: accentColor),
        prefixIcon: Icon(icon, color: accentColor),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accentColor),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
      ),
    ),
  );
}