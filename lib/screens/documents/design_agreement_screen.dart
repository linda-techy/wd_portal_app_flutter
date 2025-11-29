import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/responsive_utils.dart';
import 'dart:html' as html;
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
          borderSide: BorderSide(color: AppTheme.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          borderSide: BorderSide(color: AppTheme.primaryBlue, width: 2),
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
      content = content.replaceAll('{{CLIENT_NAME}}', _clientNameController.text);
      content = content.replaceAll('{{TOTAL_PROJECT_AREA}}', _projectAreaController.text);
      content = content.replaceAll('{{DESIGN_FEE_PER_SFT}}', _designFeeController.text);
      content = content.replaceAll('{{ADVANCE_PAYMENT_RATE}}', _advanceRateController.text);
      content = content.replaceAll('{{PRELIMINARY_DESIGN_PAYMENT_RATE}}', _preliminaryRateController.text);
      content = content.replaceAll('{{INTERIOR_DESIGN_PAYMENT_RATE}}', _interiorRateController.text);

      // Create Blob and download
      final blob = html.Blob([content], 'text/html');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'Design_Agreement_${_clientNameController.text.replaceAll(' ', '_')}.html')
        ..click();
      
      html.Url.revokeObjectUrl(url);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agreement generated and downloaded successfully!'),
          backgroundColor: AppTheme.statusSuccess,
        ),
      );
    }
  }
}
