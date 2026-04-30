import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class FieldModel {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final String hint;
  final TextInputType keyboard;
  final List<TextInputFormatter>? formatters;
  final int? maxLength;
  final bool isPassword;

  FieldModel({
    required this.label,
    required this.controller,
    required this.icon,
    required this.hint,
    this.keyboard = TextInputType.text,
    this.formatters,
    this.maxLength,
    this.isPassword = false,
  });
}

class CNICFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(oldValue, newValue) {
    String digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 13) digits = digits.substring(0, 13);

    String formatted = '';
    for (int i = 0; i < digits.length; i++) {
      if (i == 5 || i == 12) formatted += '-';
      formatted += digits[i];
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class ReusableRegister extends StatefulWidget {
  final String title;
  final String image;
  final String buttonText;
  final List<FieldModel> fields;

  const ReusableRegister({
    super.key,
    required this.title,
    required this.image,
    required this.buttonText,
    required this.fields,
  });

  @override
  State<ReusableRegister> createState() => _ReusableRegisterState();
}

class _ReusableRegisterState extends State<ReusableRegister> {
  bool _loading = false;

  void _submit() async {
    for (var f in widget.fields) {
      if (f.controller.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("All fields required")),
        );
        return;
      }
    }

    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${widget.title} Success")),
      );
      Navigator.pop(context);
    }

    if (mounted) setState(() => _loading = false);
  }

  Widget buildField(FieldModel f) {
    if (f.isPassword) {
      return _PasswordField(controller: f.controller, label: f.label);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(f.label,
            style: GoogleFonts.montserrat(
                color: Colors.yellow, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        TextField(
          controller: f.controller,
          keyboardType: f.keyboard,
          inputFormatters: f.formatters,
          maxLength: f.maxLength,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: f.hint,
            counterText: "",
            prefixIcon: Icon(f.icon, color: Colors.yellow),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AgriChain"),
        backgroundColor: Colors.green,
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(widget.image),
            fit: BoxFit.cover,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(widget.title,
                  style: const TextStyle(
                      color: Colors.yellow,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    color: Colors.black.withValues(alpha: 0.5),
                    child: Column(
                      children: [
                        ...widget.fields.map(buildField),

                        const SizedBox(height: 20),

                        ElevatedButton(
                          onPressed: _loading ? null : _submit,
                          child: _loading
                              ? const CircularProgressIndicator()
                              : Text(widget.buttonText),
                        )
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;

  const _PasswordField({required this.controller, required this.label});

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool obs = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label,
            style: GoogleFonts.montserrat(
                color: Colors.yellow, fontWeight: FontWeight.bold)),
        TextField(
          controller: widget.controller,
          obscureText: obs,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.lock, color: Colors.yellow),
            suffixIcon: IconButton(
              icon: Icon(obs ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => obs = !obs),
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}