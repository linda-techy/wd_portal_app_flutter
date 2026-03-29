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

/// Forgot Password screen.
/// User enters their email → backend sends a reset link if the account exists.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;
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
    _emailController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await PortalAuthService.forgotPassword(_emailController.text.trim());
      if (mounted) setState(() => _emailSent = true);
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString().replaceFirst('Exception: ', ''));
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
                'Forgot Password?',
                style: GoogleFonts.poppins(
                  fontSize: isMobile ? 22 : 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "We'll send you a link to\nreset your password.",
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
          child: _emailSent ? _buildSuccessView() : _buildRequestView(isMobile),
        ),
      ),
    );
    return isMobile ? content : SingleChildScrollView(child: content);
  }

  Widget _buildRequestView(bool isMobile) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Reset Password',
            style: GoogleFonts.poppins(
              fontSize: isMobile ? 26 : 32,
              fontWeight: FontWeight.bold,
              color: AppTheme.deepSlate,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Enter your registered email address and we\'ll send you a password reset link.',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.6,
            ),
          ),
          SizedBox(height: isMobile ? DesignTokens.spacingLG : DesignTokens.spacingXXL),

          // Error banner
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppTheme.errorRed.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.errorRed.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: AppTheme.errorRed, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                          color: AppTheme.errorRed, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Email field
          EntranceAnimation(
            delay: const Duration(milliseconds: 100),
            child: PremiumTextInput(
              controller: _emailController,
              label: 'Email Address',
              hint: 'your@email.com',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              semanticLabel: 'Email address',
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please enter your email';
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
              onFieldSubmitted: (_) => _submit(),
            ),
          ),
          SizedBox(height: isMobile ? DesignTokens.spacingLG : DesignTokens.spacingXL),

          // Submit button
          EntranceAnimation(
            delay: const Duration(milliseconds: 200),
            child: PrimaryButton(
              label: 'Send Reset Link',
              onPressed: _isLoading ? null : _submit,
              isLoading: _isLoading,
              fullWidth: true,
              semanticLabel: 'Send password reset link',
            ),
          ),
          const SizedBox(height: 20),

          // Back to login
          Center(
            child: TextButton.icon(
              onPressed: () => context.go('/login'),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Back to Login'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Success icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.successGreen.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.mark_email_read_outlined,
              color: AppTheme.successGreen, size: 40),
        ),
        const SizedBox(height: 24),
        Text(
          'Check Your Email',
          style: GoogleFonts.poppins(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppTheme.deepSlate,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'If ${_emailController.text.trim()} is registered, you\'ll receive a password reset link shortly.\n\nThe link expires in 30 minutes.',
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
            height: 1.6,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Don\'t see the email? Check your spam folder.',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textTertiary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        // Resend
        OutlinedButton.icon(
          onPressed: () => setState(() => _emailSent = false),
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Send Again'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.coralRed,
            side: const BorderSide(color: AppTheme.coralRed),
          ),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () => context.go('/login'),
          icon: const Icon(Icons.arrow_back, size: 16),
          label: const Text('Back to Login'),
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
