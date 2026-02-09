import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../theme/app_theme.dart';
import '../../theme/responsive_utils.dart';
import 'design_agreement_template.dart';

class DesignAgreementScreen extends StatefulWidget {
  const DesignAgreementScreen({super.key});

  @override
  State<DesignAgreementScreen> createState() => _DesignAgreementScreenState();
}

class _DesignAgreementScreenState extends State<DesignAgreementScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form Controllers
  final _clientNameController = TextEditingController();
  final _projectAreaController = TextEditingController();
  final _designFeeController = TextEditingController();
  final _advanceRateController = TextEditingController();
  final _preliminaryRateController = TextEditingController();
  final _interiorRateController = TextEditingController();

  @override
  void dispose() {
    _clientNameController.dispose();
    _projectAreaController.dispose();
    _designFeeController.dispose();
    _advanceRateController.dispose();
    _preliminaryRateController.dispose();
    _interiorRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Create Design Agreement'),
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: AdaptiveContainer(
        child: SingleChildScrollView(
          padding: ResponsiveUtils.responsivePadding(context),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Client Details'),
                const SizedBox(height: AppTheme.spacingMD),
                _buildTextField(
                  controller: _clientNameController,
                  label: 'Client Name',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: AppTheme.spacingMD),
                _buildTextField(
                  controller: _projectAreaController,
                  label: 'Total Project Area (sq ft)',
                  icon: Icons.square_foot_outlined,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AppTheme.spacingXL),
                _buildSectionTitle('Fee Structure'),
                const SizedBox(height: AppTheme.spacingMD),
                _buildTextField(
                  controller: _designFeeController,
                  label: 'Design Fee (Rs. per sq ft)',
                  icon: Icons.currency_rupee,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AppTheme.spacingXL),
                _buildSectionTitle('Payment Schedule Rates'),
                const SizedBox(height: AppTheme.spacingMD),
                _buildTextField(
                  controller: _advanceRateController,
                  label: 'Advance Payment Rate (Rs./sq ft)',
                  icon: Icons.payments_outlined,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AppTheme.spacingMD),
                _buildTextField(
                  controller: _preliminaryRateController,
                  label: 'Preliminary Design Rate (Rs./sq ft)',
                  icon: Icons.payments_outlined,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AppTheme.spacingMD),
                _buildTextField(
                  controller: _interiorRateController,
                  label: 'Interior Design Rate (Rs./sq ft)',
                  icon: Icons.payments_outlined,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AppTheme.spacingXL),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _generateAgreement,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                      ),
                    ),
                    child: const Text(
                      'Generate Agreement',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryBlue,
          ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          borderSide: const BorderSide(color: AppTheme.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
        ),
        filled: true,
        fillColor: AppTheme.surface,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        return null;
      },
    );
  }

  void _generateAgreement() {
    if (_formKey.currentState!.validate()) {
      // Get values from controllers
      String content = DesignAgreementTemplate.htmlContent;

      // Replace placeholders
      content =
          content.replaceAll('{{CLIENT_NAME}}', _clientNameController.text);
      content = content.replaceAll(
          '{{TOTAL_PROJECT_AREA}}', _projectAreaController.text);
      content = content.replaceAll(
          '{{DESIGN_FEE_PER_SFT}}', _designFeeController.text);
      content = content.replaceAll(
          '{{ADVANCE_PAYMENT_RATE}}', _advanceRateController.text);
      content = content.replaceAll('{{PRELIMINARY_DESIGN_PAYMENT_RATE}}',
          _preliminaryRateController.text);
      content = content.replaceAll(
          '{{INTERIOR_DESIGN_PAYMENT_RATE}}', _interiorRateController.text);

      // Download functionality - web only
      if (kIsWeb) {
        // Web platform download
        // Note: For web, you would need to use dart:html or a package like universal_html
        // For now, we'll show the content in a dialog or copy to clipboard
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                const Text('Agreement generated! Content ready for download.'),
            backgroundColor: AppTheme.statusSuccess,
            action: SnackBarAction(
              label: 'Copy',
              onPressed: () {
                // Copy to clipboard would go here
              },
            ),
          ),
        );
      } else {
        // For non-web platforms, show content or save to file
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Agreement generated successfully!'),
            backgroundColor: AppTheme.statusSuccess,
          ),
        );
      }
    }
  }
}
