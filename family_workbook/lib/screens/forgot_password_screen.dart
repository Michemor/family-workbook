import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  /// Optional pre-filled email (passed from the Sign In screen).
  final String? initialEmail;

  const ForgotPasswordScreen({super.key, this.initialEmail});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;

  bool _isLoading = false;
  bool _emailSent = false;

  // Resend cooldown
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _emailController =
        TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Converts raw Firebase error strings into friendly messages.
  String _friendlyError(Object e) {
    final raw = e.toString();
    if (raw.contains('user-not-found') || raw.contains('invalid-email')) {
      return 'No account found for that email address.';
    }
    if (raw.contains('too-many-requests')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    if (raw.contains('network-request-failed')) {
      return 'Network error. Please check your connection and try again.';
    }
    return 'Something went wrong. Please try again.';
  }

  void _startCooldown() {
    _resendCooldown = 60;
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _resendCooldown--;
        if (_resendCooldown <= 0) t.cancel();
      });
    });
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _authService.resetPassword(_emailController.text.trim());
      if (mounted) {
        setState(() {
          _emailSent = true;
        });
        _startCooldown();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_friendlyError(e)),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleResend() async {
    if (_resendCooldown > 0) return;
    setState(() => _isLoading = true);

    try {
      await _authService.resetPassword(_emailController.text.trim());
      if (mounted) {
        _startCooldown();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Reset email resent successfully!'),
            backgroundColor: AppTheme.successGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_friendlyError(e)),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleTryDifferentEmail() {
    setState(() {
      _emailSent = false;
      _emailController.clear();
      _resendCooldown = 0;
      _cooldownTimer?.cancel();
    });
  }

  void _handleBackToSignIn() => Navigator.of(context).pop();

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Gradient background — same style as Sign In
          Container(
            decoration: const BoxDecoration(gradient: AppTheme.primaryOmbre),
          ),
          SingleChildScrollView(
            child: SizedBox(
              height: MediaQuery.of(context).size.height,
              child: Column(
                children: [
                  // ── Top header area ──────────────────────────────────────
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.22,
                    child: SafeArea(
                      child: Stack(
                        children: [
                          // Back arrow
                          Positioned(
                            left: 8,
                            top: 0,
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back,
                                  color: Colors.white, size: 24),
                              onPressed: _handleBackToSignIn,
                            ),
                          ),
                          // Centered header
                          Center(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 400),
                              child: _emailSent
                                  ? _buildHeaderContent(
                                      key: const ValueKey('sent'),
                                      icon: Icons.mark_email_read_outlined,
                                      title: 'Email Sent!',
                                      subtitle:
                                          'Check your inbox for reset instructions',
                                    )
                                  : _buildHeaderContent(
                                      key: const ValueKey('form'),
                                      icon: Icons.lock_reset_outlined,
                                      title: 'Forgot Password?',
                                      subtitle:
                                          'We\'ll send a reset link to your inbox',
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Wavy white panel — same pattern as Sign In ───────────
                  Expanded(
                    child: ClipPath(
                      clipper: _WaveClipper(),
                      child: Container(
                        color: Colors.white,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 450),
                            transitionBuilder: (child, animation) =>
                                FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.08),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            ),
                            child: _emailSent
                                ? _buildSuccessPanel()
                                : _buildFormPanel(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sub-widgets ────────────────────────────────────────────────────────────

  Widget _buildHeaderContent({
    required Key key,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Column(
      key: key,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Icon(icon, color: Colors.white, size: 32),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Color(0x44000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 13,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFormPanel() {
    return Column(
      key: const ValueKey('form-panel'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reset Password',
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter the email address linked to your account and we\'ll send you a link to reset your password.',
          style: Theme.of(context)
              .textTheme
              .bodyMedium!
              .copyWith(color: AppTheme.textLight, height: 1.5),
        ),
        const SizedBox(height: 28),
        Form(
          key: _formKey,
          child: Column(
            children: [
              // Email field
              TextFormField(
                controller: _emailController,
                style: const TextStyle(color: Colors.black, fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  labelStyle: const TextStyle(color: Colors.black54),
                  hintText: 'your@email.com',
                  hintStyle: const TextStyle(color: Colors.black38),
                  prefixIcon: const Icon(
                    Icons.email_outlined,
                    color: AppTheme.primaryColor,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppTheme.softTan),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppTheme.softTan),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppTheme.primaryColor, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppTheme.errorRed, width: 1.5),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _handleResetPassword(),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your email address';
                  }
                  if (!RegExp(
                    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                  ).hasMatch(value.trim())) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 28),
              // Send reset link button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleResetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const _LoadingRow(label: 'Sending...')
                      : const Text(
                          'Send Reset Link',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              // Back to sign in
              Center(
                child: TextButton(
                  onPressed: _handleBackToSignIn,
                  child: Text(
                    '← Back to Sign In',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessPanel() {
    final email = _emailController.text.trim();
    return Column(
      key: const ValueKey('success-panel'),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Success icon
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppTheme.successGreen.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.successGreen.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: const Icon(
            Icons.check_circle_outline_rounded,
            color: AppTheme.successGreen,
            size: 38,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Check Your Email',
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: AppTheme.textLight,
                  height: 1.6,
                ),
            children: [
              const TextSpan(text: 'We\'ve sent a password reset link to\n'),
              TextSpan(
                text: email,
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'The link expires in 1 hour. Check your spam folder if you don\'t see it.',
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: AppTheme.textLight,
                height: 1.5,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        // Back to Sign In — primary CTA
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _handleBackToSignIn,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Back to Sign In',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Resend button with cooldown
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed:
                (_resendCooldown > 0 || _isLoading) ? null : _handleResend,
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: _resendCooldown > 0
                    ? AppTheme.textLight.withValues(alpha: 0.4)
                    : AppTheme.primaryColor,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const _LoadingRow(
                    label: 'Resending...',
                    color: AppTheme.primaryColor,
                  )
                : Text(
                    _resendCooldown > 0
                        ? 'Resend in ${_resendCooldown}s'
                        : 'Resend Email',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: _resendCooldown > 0
                          ? AppTheme.textLight
                          : AppTheme.primaryColor,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 16),

        // Try a different email
        Center(
          child: TextButton(
            onPressed: _handleTryDifferentEmail,
            child: Text(
              'Try a different email',
              style: TextStyle(
                color: AppTheme.textLight,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Shared loading row widget ──────────────────────────────────────────────────

class _LoadingRow extends StatelessWidget {
  final String label;
  final Color color;

  const _LoadingRow({
    required this.label,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }
}

// ── Wave Clipper — mirrors the one in SignInScreen ─────────────────────────────

class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, 40);
    path.quadraticBezierTo(size.width / 4, 0, size.width / 2, 40);
    path.quadraticBezierTo(
        size.width - size.width / 4, 80, size.width, 40);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_WaveClipper oldClipper) => false;
}
