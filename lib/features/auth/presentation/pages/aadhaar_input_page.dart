import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_ride/features/auth/data/aadhaar_api.dart';
import 'package:share_ride/features/auth/presentation/pages/aadhaar_otp_page.dart';

class AadhaarInputPage extends StatefulWidget {
  const AadhaarInputPage({
    super.key,
    required this.userId,
    this.forDriverOnboarding = false,
  });

  final int userId;
  final bool forDriverOnboarding;

  @override
  State<AadhaarInputPage> createState() => _AadhaarInputPageState();
}

class _AadhaarInputPageState extends State<AadhaarInputPage> {
  final _formKey = GlobalKey<FormState>();
  final _aadhaarController = TextEditingController();
  bool _consentGiven = false;
  bool _isSending = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      _aadhaarController.text = '123456789015';
      _consentGiven = true;
    }
  }

  @override
  void dispose() {
    _aadhaarController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_consentGiven) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please give consent to verify Aadhaar')),
      );
      return;
    }

    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    final aadhaarNumber = _aadhaarController.text.replaceAll(' ', '');

    try {
      final result = await AadhaarApi.generateOtp(aadhaarNumber: aadhaarNumber);
      if (!mounted) return;

      setState(() => _isSending = false);

      final verified = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => AadhaarOtpPage(
            userId: widget.userId,
            aadhaarNumber: aadhaarNumber,
            referenceId: result.referenceId,
            testOtpHint: result.testOtp,
          ),
        ),
      );

      if (!mounted || verified != true) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.forDriverOnboarding ? 'Driver Setup' : 'Aadhaar'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.badge_outlined,
                      size: 56,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Enter Aadhaar number',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'We will send an OTP to your Aadhaar-linked mobile.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _aadhaarController,
                      keyboardType: TextInputType.number,
                      enabled: !_isSending,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(12),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Aadhaar number',
                        hintText: '12-digit Aadhaar',
                        prefixIcon: Icon(Icons.credit_card_outlined),
                      ),
                      validator: (value) {
                        final digits = (value ?? '').replaceAll(' ', '');
                        if (digits.isEmpty) return 'Enter your Aadhaar number';
                        if (digits.length != 12) {
                          return 'Aadhaar must be 12 digits';
                        }
                        return null;
                      },
                    ),
                    CheckboxListTile(
                      value: _consentGiven,
                      onChanged: _isSending
                          ? null
                          : (value) {
                              setState(() => _consentGiven = value ?? false);
                            },
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: const Text(
                        'I consent to Aadhaar verification for KYC',
                      ),
                    ),
                    if (_errorMessage != null) ...[
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    FilledButton(
                      onPressed: _isSending ? null : _sendOtp,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isSending
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Continue'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
