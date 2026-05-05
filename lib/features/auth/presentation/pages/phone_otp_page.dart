import 'package:flutter/material.dart';
import 'package:share_ride/features/auth/data/verify_api.dart';

class PhoneOtpPage extends StatefulWidget {
  const PhoneOtpPage({
    super.key,
    required this.phoneNumber,
  });

  final String phoneNumber;

  @override
  State<PhoneOtpPage> createState() => _PhoneOtpPageState();
}

class _PhoneOtpPageState extends State<PhoneOtpPage> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  bool _isVerifying = false;
  bool _isSending = true;
  String? _sendError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestOtp();
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    setState(() {
      _isSending = true;
      _sendError = null;
    });
    try {
      await VerifyApi.sendOtp(widget.phoneNumber);
      if (!mounted) return;
      setState(() {
        _isSending = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification code sent')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _sendError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _verifyOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isVerifying = true;
    });

    try {
      await VerifyApi.verifyOtp(
        phone: widget.phoneNumber,
        code: _otpController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number verified successfully')),
      );
      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
      });
      final message = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message.isEmpty ? 'Verification failed' : message),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Phone Verification')),
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
                    if (_isSending) const LinearProgressIndicator(),
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
                      'Code sent to ${widget.phoneNumber}',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                    if (_sendError != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _sendError!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.tonal(
                        onPressed: _isSending ? null : _requestOtp,
                        child: const Text('Try again'),
                      ),
                    ],
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 10,
                      enabled: !_isSending && _sendError == null,
                      decoration: const InputDecoration(
                        labelText: 'OTP',
                        hintText: 'Enter code from SMS',
                        prefixIcon: Icon(Icons.lock_outline),
                        counterText: '',
                      ),
                      validator: (value) {
                        final text = (value ?? '').trim();
                        if (text.isEmpty) return 'Please enter OTP';
                        if (text.length < 4) return 'Code is too short';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: (_isVerifying ||
                              _isSending ||
                              _sendError != null)
                          ? null
                          : _verifyOtp,
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
                      onPressed: (_isSending || _sendError != null)
                          ? null
                          : _requestOtp,
                      child: const Text('Resend OTP'),
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
