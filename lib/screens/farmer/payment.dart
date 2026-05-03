// lib/utils/payment_methods.dart
// ── Shared Payment Methods — use everywhere in app ──────────────────────────

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PaymentMethod {
  final String id;
  final String name;
  final String icon;
  final bool requiresAccount;

  const PaymentMethod({
    required this.id,
    required this.name,
    required this.icon,
    required this.requiresAccount,
  });
}

const List<PaymentMethod> kPaymentMethods = [
  PaymentMethod(id: 'easypaisa',   name: 'EasyPaisa',   icon: '📱', requiresAccount: true),
  PaymentMethod(id: 'jazzcash',    name: 'JazzCash',    icon: '🎵', requiresAccount: true),
  PaymentMethod(id: 'nayapay',     name: 'NayaPay',     icon: '💜', requiresAccount: true),
  PaymentMethod(id: 'meezan',      name: 'Meezan Bank', icon: '🕌', requiresAccount: true),
  PaymentMethod(id: 'ubl',         name: 'UBL',         icon: '🏛️', requiresAccount: true),
  PaymentMethod(id: 'habib',       name: 'Habib Bank',  icon: '🏦', requiresAccount: true),
  PaymentMethod(id: 'cash_on_del', name: 'Cash on Del.',icon: '🚚', requiresAccount: false),
];

/// Shared reusable payment selector + account field widget.
/// Wrap inside StatefulBuilder so [selectedId] updates rebuild the UI.
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
        ? kPaymentMethods.firstWhere((m) => m.id == selectedId)
        : null;
    final needsAccount = selected?.requiresAccount ?? false;

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
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: kPaymentMethods.map((method) {
            final isSelected = selectedId == method.id;
            return GestureDetector(
              onTap: () => onChanged(method.id),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? accentColor.withValues(alpha: 0.35)
                      : Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? accentColor : Colors.white24,
                  ),
                ),
                child: Text(
                  '${method.icon} ${method.name}',
                  style: GoogleFonts.poppins(
                    color: isSelected ? accentColor : Colors.white70,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (needsAccount) ...[
          const SizedBox(height: 12),
          dialogField(
            '${selected!.icon} ${selected.name} Account No.',
            accountController,
            Icons.credit_card,
            accentColor: accentColor,
            keyboardType: TextInputType.number,
          ),
        ],
      ],
    );
  }
}

/// Shared dialog text field — import and call anywhere.
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
      ),
    ),
  );
}