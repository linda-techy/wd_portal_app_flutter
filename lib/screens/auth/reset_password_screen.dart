import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_motion.dart';
import '../../widgets/animations/entrance_animation.dart';
import '../../widgets/components/premium_input.dart';
import '../../widgets/components/premium_button.dart';
import '../../services/portal_auth_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/design_tokens.dart';

/// Reset Password screen.
/// Reached via the email link: /reset-password?token=<UUID>
/// Works on web (URL parsed from browser), iOS, and Android (deep link).
class ResetPasswordScreen extends StatefulWidget {
  /// The raw token extracted from the URL query parameter.
  final String token;

  const ResetPasswordScreen({super.key, required this.token});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  bool _success = false;
  String? _errorMessage;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: AppMotion.durationSlow,
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: AppMotion.curveEnter),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    _animController.dispose();
    super.dispose();
  }

  bool get _hasValidToken => widget.token.isNotEmpty && widget.token.length > 20;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await PortalAuthService.resetPassword(
          widget.token, _passwordController.text);
      if (mounted) setState(() => _success = true);
    } catch (e) {
      if (mounted) {
        setState(() =>
            _errorMessage = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
      ),
    );
  }

  Widget _buildMobileLayout() => SingleChildScrollView(
        child: Column(children: [
          _buildBrandPanel(isMobile: true),
          _buildFormPanel(isMobile: true),
        ]),
      );

  Widget _buildDesktopLayout() => Row(children: [
        Expanded(flex: 4, child: _buildBrandPanel(isMobile: false)),
        Expanded(flex: 6, child: _buildFormPanel(isMobile: false)),
      ]);

  // ── Brand panel ───────────────────────────────────────────────────────────

  Widget _buildBrandPanel({required bool isMobile}) {
    return Container(
      height: isMobile ? 200 : double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.coralRed, AppTheme.deepSlate],
        ),
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 20 : 48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: isMobile ? 70 : 120,
                height: isMobile ? 70 : 120,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset('assets/icons/wd_logo.png',
                      fit: BoxFit.contain),
                ),
              ),
              SizedBox(height: isMobile ? 12 : 24),
              Text(
                'New Password',
                style: GoogleFonts.poppins(
                  fontSize: isMobile ? 22 : 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Choose a strong password\nfor your portal account.',
                style: GoogleFonts.poppins(
                  fontSize: isMobile ? 14 : 16,
                  color: Colors.white.withOpacity(0.85),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Form panel ────────────────────────────────────────────────────────────

  Widget _buildFormPanel({required bool isMobile}) {
    final content = Center(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 48),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: _success
              ? _buildSuccessView()
              : !_hasValidToken
                  ? _buildInvalidTokenView()
                  : _buildResetForm(isMobile),
        ),
      ),
    );
    return isMobile ? content : SingleChildScrollView(child: content);
  }

  // ── Invalid token ─────────────────────────────────────────────────────────

  Widget _buildInvalidTokenView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.errorRed.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.link_off_outlined,
              color: AppTheme.errorRed, size: 40),
        ),
        const SizedBox(height: 24),
        Text(
          'Invalid Reset Link',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.deepSlate,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        const Text(
          'This password reset link is invalid or has expired.\nPlease request a new one.',
          style:
              TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.6),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        FilledButton.icon(
          onPressed: () => context.go('/forgot-password'),
          icon: const Icon(Icons.send_outlined, size: 16),
          label: const Text('Request New Link'),
          style: FilledButton.styleFrom(backgroundColor: AppTheme.coralRed),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () => context.go('/login'),
          icon: const Icon(Icons.arrow_back, size: 16),
          label: const Text('Back to Login'),
          style: TextButton.styleFrom(foregroundColor: AppTheme.textSecondary),
        ),
      ],
    );
  }

  // ── Reset form ─────────────────────────────────────────────────────────────

  Widget _buildResetForm(bool isMobile) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Set New Password',
            style: GoogleFonts.poppins(
              fontSize: isMobile ? 26 : 32,
              fontWeight: FontWeight.bold,
              color: AppTheme.deepSlate,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Your new password must be at least 8 characters. Choose something strong.',
            style: TextStyle(
                fontSize: 14, color: AppTheme.textSecondary, height: 1.6),
          ),
          SizedBox(
              height: isMobile ? DesignTokens.spacingLG : DesignTokens.spacingXXL),

          // Error banner
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppTheme.errorRed.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: AppTheme.errorRed.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: AppTheme.errorRed, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_errorMessage!,
                            style: const TextStyle(
                                color: AppTheme.errorRed, fontSize: 13)),
                        if (_errorMessage!.toLowerCase().contains('expired') ||
                            _errorMessage!.toLowerCase().contains('invalid')) ...[
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () => context.go('/forgot-password'),
                            child: const Text(
                              'Request a new reset link →',
                              style: TextStyle(
                                  color: AppTheme.coralRed,
                                  fontSize: 12,
                                  decoration: TextDecoration.underline),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // New password
          EntranceAnimation(
            delay: const Duration(milliseconds: 100),
            child: PremiumPasswordInput(
              controller: _passwordController,
              label: 'New Password',
              hint: 'At least 8 characters',
              semanticLabel: 'New password',
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please enter a password';
                if (v.length < 8) return 'Password must be at least 8 characters';
                if (!RegExp(r'(?=.*[A-Za-z])(?=.*[0-9])').hasMatch(v)) {
                  return 'Use a mix of letters and numbers';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: DesignTokens.spacingMD),

          // Confirm password
          EntranceAnimation(
            delay: const Duration(milliseconds: 180),
            child: PremiumPasswordInput(
              controller: _confirmController,
              label: 'Confirm Password',
              hint: 'Re-enter your new password',
              semanticLabel: 'Confirm password',
              onFieldSubmitted: (_) => _submit(),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please confirm your password';
                if (v != _passwordController.text) return 'Passwords do not match';
                return null;
              },
            ),
          ),

          // Password strength hint
          const SizedBox(height: 8),
          const Text(
            '💡 Tip: Use a mix of uppercase, lowercase, numbers, and symbols.',
            style: TextStyle(
                fontSize: 11, color: AppTheme.textTertiary, height: 1.5),
          ),

          SizedBox(
              height: isMobile ? DesignTokens.spacingLG : DesignTokens.spacingXL),

          // Submit
          EntranceAnimation(
            delay: const Duration(milliseconds: 260),
            child: PrimaryButton(
              label: 'Reset Password',
              onPressed: _isLoading ? null : _submit,
              isLoading: _isLoading,
              fullWidth: true,
              semanticLabel: 'Reset your password',
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: TextButton.icon(
              onPressed: () => context.go('/login'),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Back to Login'),
              style: TextButton.styleFrom(
                  foregroundColor: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  // ── Success view ──────────────────────────────────────────────────────────

  Widget _buildSuccessView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.successGreen.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.lock_open_outlined,
              color: AppTheme.successGreen, size: 40),
        ),
        const SizedBox(height: 24),
        Text(
          'Password Reset!',
          style: GoogleFonts.poppins(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppTheme.deepSlate,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        const Text(
          'Your password has been updated successfully.\nYou can now log in with your new password.',
          style:
              TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.6),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        FilledButton.icon(
          onPressed: () => context.go('/login'),
          icon: const Icon(Icons.login, size: 16),
          label: const Text('Go to Login'),
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.coralRed,
            minimumSize: const Size(180, 44),
          ),
        ),
      ],
    );
  }
}
