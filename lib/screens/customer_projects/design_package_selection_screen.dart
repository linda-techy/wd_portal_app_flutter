import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/responsive_utils.dart';
import '../../models/customer_project.dart';
import 'design_package_payment_screen.dart';

class DesignPackageSelectionScreen extends StatefulWidget {
  const DesignPackageSelectionScreen({
    super.key,
    required this.project,
  });

  final CustomerProject project;

  @override
  State<DesignPackageSelectionScreen> createState() =>
      _DesignPackageSelectionScreenState();
}

class _DesignPackageSelectionScreenState
    extends State<DesignPackageSelectionScreen> {
  String? _selectedPackage;

  final List<Map<String, dynamic>> _packages = [
    {
      'id': 'custom',
      'name': 'Custom',
      'price': '₹ 95 per sq.ft. (+18% GST)',
      'priceValue': 95.0,
      'discount': 'Upto 10% OFF',
      'features': [
        'Design Program',
        'BPI ⓘ',
        'Room-wise Functionality Mapping',
        'Plan (3 Changes)',
        'Elevation (3 Changes)',
        'Sanction Drawings',
        'Detailed Project Costing (DPC)',
        '3D Elevation Renders',
        'VR Walkthroughs (2 Sessions)',
        'Structural Design',
        'Curated Solutions',
      ],
      'color': AppTheme.deepSlate,
    },
    {
      'id': 'premium',
      'name': 'Premium',
      'price': '₹ 140 per sq.ft. (+18% GST)',
      'priceValue': 140.0,
      'discount': 'Upto 15% OFF',
      'features': [
        'Design Program',
        'BPI ⓘ',
        'Room-wise Functionality Mapping',
        'Plan (3 Changes)',
        'Elevation (3 Changes)',
        'Sanction Drawings',
        'Detailed Project Costing (DPC)',
        '3D Elevation & Interior Renders',
        'VR Walkthroughs (2 Sessions)',
        'Detailed Interior Design',
        'Detailed Landscape Design',
        'Detailed Furniture Design',
        'Detailed Lighting Design',
        'Individual Space Planning',
        'Structural and MEP Design ⓘ',
        'Additional VR Walkthrough (After finalization of interior & landscape design)',
        'Curated Solutions',
      ],
      'color': AppTheme.coralRed,
    },
    {
      'id': 'bespoke',
      'name': 'Bespoke',
      'price': '₹ 240 per sq.ft. (+18% GST)',
      'priceValue': 240.0,
      'discount': 'Upto 15% OFF',
      'features': [
        'Design Program',
        'BPI ⓘ',
        'Room-wise Functionality Mapping',
        'Plan (Unlimited Changes)',
        'Elevation (Unlimited Changes)',
        'Sanction Drawings',
        'Detailed Project Costing (DPC)',
        '3D Elevation & Interior Renders',
        'VR Walkthroughs (Unlimited Sessions)',
        'Detailed Interior Design',
        'Detailed Landscape Design',
        'Detailed Furniture Design',
        'Detailed Lighting Design',
        'Individual Space Planning',
        'Structural and MEP Design ⓘ',
        'Additional VR Walkthrough (Unlimited)',
        'Curated Solutions',
        'Dedicated Design Team',
        'Site Supervision (Periodic)',
      ],
      'color': const Color(0xFFD4AF37), // Gold color
    },
  ];

  void _onNext() {
    if (_selectedPackage == null) return;

    final selectedPkgDetails = _packages.firstWhere(
      (pkg) => pkg['name'] == _selectedPackage,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DesignPackagePaymentScreen(
          project: widget.project,
          packageDetails: selectedPkgDetails,
        ),
      ),
    ).then((result) {
      if (result == true) {
        Navigator.pop(context, true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Select Design Package'),
        centerTitle: true,
      ),
      body: AdaptiveContainer(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppTheme.spacingMD),
                children: [
                  Text(
                    'Choose the package that fits your vision',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.spacingSM),
                  Text(
                    'Select one of the options below to proceed with the design phase.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.spacingXL),
                  ResponsiveLayout(
                    mobile: Column(
                      children: _packages
                          .map((pkg) => _buildPackageCard(pkg))
                          .toList(),
                    ),
                    desktop: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _packages
                          .map((pkg) => Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: AppTheme.spacingSM),
                                  child: _buildPackageCard(pkg),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageCard(Map<String, dynamic> pkg) {
    final isSelected = _selectedPackage == pkg['name'];
    final color = pkg['color'] as Color;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPackage = pkg['name'];
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spacingMD),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          border: Border.all(
            color: isSelected ? color : AppTheme.borderLight,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? AppTheme.shadowMD : AppTheme.shadowSM,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingMD),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.05) : Colors.transparent,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppTheme.radiusLG - 1),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: isSelected ? color : AppTheme.textTertiary,
                  ),
                  const SizedBox(width: AppTheme.spacingSM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pkg['name'],
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                        ),
                        Text(
                          pkg['price'],
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMD),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Inclusions',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: AppTheme.spacingSM),
                  ...pkg['features'].map<Widget>((feature) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 6),
                              child: Icon(Icons.circle, size: 4, color: AppTheme.textTertiary),
                            ),
                            const SizedBox(width: AppTheme.spacingSM),
                            Expanded(
                              child: Text(
                                feature,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        boxShadow: AppTheme.shadowLG,
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _selectedPackage != null ? _onNext : null,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
          ),
          child: const Text('Next'),
        ),
      ),
    );
  }
}

