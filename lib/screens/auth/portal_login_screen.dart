import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_motion.dart';
import '../../widgets/animations/entrance_animation.dart';
import '../../widgets/animations/shake_widget.dart';
import '../../widgets/components/premium_input.dart';
import '../../widgets/components/premium_button.dart';
import '../../providers/portal_auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/design_tokens.dart';
import '../../utils/motion_toast.dart';

class PortalLoginScreen extends StatefulWidget {
  const PortalLoginScreen({super.key});

  @override
  State<PortalLoginScreen> createState() => _PortalLoginScreenState();
}

class _PortalLoginScreenState extends State<PortalLoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  bool _isLoading = false;
  bool _shouldShake = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: AppMotion.durationSlow,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _animationController, curve: AppMotion.curveEnter),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _shouldShake = true);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _shouldShake = false);
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider =
          Provider.of<PortalAuthProvider>(context, listen: false);
      final success = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
        context,
      );

      if (!success && mounted) {
        MotionToast.showError(
          context,
          message: 'Login failed: Invalid credentials',
        );
      }
    } catch (e) {
      if (mounted) {
        MotionToast.showError(
          context,
          message: 'Login failed: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildBrandedSection(isMobile: true),
          _buildFormSection(isMobile: true),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: _buildBrandedSection(isMobile: false),
        ),
        Expanded(
          flex: 6,
          child: _buildFormSection(isMobile: false),
        ),
      ],
    );
  }

  Widget _buildBrandedSection({required bool isMobile}) {
    return Container(
      height: isMobile ? 200 : double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.coralRed,
            AppTheme.deepSlate,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Abstract pattern overlay
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: CustomPaint(
                painter: _GeometricPatternPainter(),
              ),
            ),
          ),
          // Content
          Center(
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 20.0 : 48.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
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
                      child: Image.asset(
                        'assets/icons/wd_logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  SizedBox(height: isMobile ? 12 : 32),
                  // Company name
                  Text(
                    'Walldot Builders',
                    style: GoogleFonts.poppins(
                      fontSize: isMobile ? 28 : 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  // Tagline
                  Text(
                    'Building excellence, together.',
                    style: GoogleFonts.poppins(
                      fontSize: isMobile ? 16 : 18,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withOpacity(0.9),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection({required bool isMobile}) {
    final content = Center(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16.0 : 48.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: ShakeWidget(
            shouldShake: _shouldShake,
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode
                  .disabled, // Only validate on submit or field blur
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Login heading
                  Text(
                    'Login',
                    style: GoogleFonts.poppins(
                      fontSize: isMobile ? 28 : 36,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.deepSlate,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Welcome back! Please login to your account.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(
                      height: isMobile
                          ? DesignTokens.spacingLG
                          : DesignTokens.spacingXXL),

                  // Email Field
                  EntranceAnimation(
                    delay: const Duration(milliseconds: 100),
                    child: PremiumTextInput(
                      controller: _emailController,
                      focusNode: _emailFocusNode,
                      label: 'Email',
                      hint: 'username@gmail.com',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      semanticLabel: 'Email address',
                      // Cross-platform: Tab key (desktop/web) or Next button (mobile) moves to password
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(height: DesignTokens.spacingMD),

                  // Password Field
                  EntranceAnimation(
                    delay: const Duration(milliseconds: 200),
                    child: PremiumPasswordInput(
                      controller: _passwordController,
                      focusNode: _passwordFocusNode,
                      label: 'Password',
                      hint: 'Enter your password',
                      semanticLabel: 'Password',
                      // Cross-platform: Enter/Done submits form on all platforms
                      onFieldSubmitted: (_) {
                        _handleLogin();
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(
                      height: isMobile
                          ? DesignTokens.spacingLG
                          : DesignTokens.spacingXL),

                  // Login Button
                  EntranceAnimation(
                    delay: const Duration(milliseconds: 300),
                    child: PrimaryButton(
                      label: 'Sign In',
                      onPressed: _isLoading ? null : _handleLogin,
                      isLoading: _isLoading,
                      fullWidth: true,
                      semanticLabel: 'Sign in to your account',
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // Only scroll locally if NOT mobile (Desktop side)
    // Mobile parent already handles scrolling
    return isMobile ? content : SingleChildScrollView(child: content);
  }
}

// Custom painter for geometric pattern
class _GeometricPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final brickWidth = 80.0;
    final brickHeight = 40.0;
    final mortarGap = 2.0;

    // Draw brick pattern
    for (double y = 0;
        y < size.height + brickHeight;
        y += brickHeight + mortarGap) {
      final isOffsetRow = ((y / (brickHeight + mortarGap)) % 2) == 1;
      final startX = isOffsetRow ? -brickWidth / 2 : 0.0;

      for (double x = startX;
          x < size.width + brickWidth;
          x += brickWidth + mortarGap) {
        // Draw brick outline
        canvas.drawRect(
          Rect.fromLTWH(x, y, brickWidth, brickHeight),
          paint,
        );
      }
    }

    // Add some construction elements (scaffolding lines)
    final scaffoldPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Vertical scaffolding lines
    for (double x = 0; x < size.width; x += size.width / 4) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        scaffoldPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
