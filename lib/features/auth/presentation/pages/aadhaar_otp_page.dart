import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_ride/features/auth/data/aadhaar_api.dart';

class AadhaarOtpPage extends StatefulWidget {
  const AadhaarOtpPage({
    super.key,
    required this.userId,
    required this.aadhaarNumber,
    required this.referenceId,
    this.testOtpHint,
  });

  final int userId;
  final String aadhaarNumber;
  final String referenceId;
  final String? testOtpHint;

  @override
  State<AadhaarOtpPage> createState() => _AadhaarOtpPageState();
}

class _AadhaarOtpPageState extends State<AadhaarOtpPage> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  bool _isVerifying = false;
  bool _isResending = false;
  String? _errorMessage;
  late String _referenceId;

  String get _aadhaarMask {
    final digits = widget.aadhaarNumber.replaceAll(' ', '');
    if (digits.length < 4) return 'your Aadhaar-linked mobile';
    return 'mobile linked with Aadhaar ending ${digits.substring(digits.length - 4)}';
  }

  @override
  void initState() {
    super.initState();
    _referenceId = widget.referenceId;
    if (kDebugMode && widget.testOtpHint != null) {
      _otpController.text = widget.testOtpHint!;
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _resendOtp() async {
    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    try {
      final result =
          await AadhaarApi.generateOtp(aadhaarNumber: widget.aadhaarNumber);
      if (!mounted) return;
      setState(() {
        _isResending = false;
        _referenceId = result.referenceId;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isResending = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _verifyOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      final result = await AadhaarApi.verifyOtp(
        userId: widget.userId,
        referenceId: _referenceId,
        otp: _otpController.text.trim(),
      );
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isBusy = _isVerifying || _isResending;

    return Scaffold(
      appBar: AppBar(title: const Text('Enter OTP')),
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
                      Icons.sms_outlined,
                      size: 56,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Enter OTP',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Code sent to $_aadhaarMask',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                    if (kDebugMode && widget.testOtpHint != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Test OTP: ${widget.testOtpHint}',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.black54,
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      enabled: !isBusy,
                      autofocus: true,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'OTP',
                        hintText: '6-digit code',
                        prefixIcon: Icon(Icons.lock_outline),
                        counterText: '',
                      ),
                      validator: (value) {
                        final text = (value ?? '').trim();
                        if (text.isEmpty) return 'Please enter OTP';
                        if (text.length != 6) return 'OTP must be 6 digits';
                        return null;
                      },
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: isBusy ? null : _verifyOtp,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isVerifying
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Verify OTP'),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: isBusy ? null : _resendOtp,
                      child: _isResending
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Resend OTP'),
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
