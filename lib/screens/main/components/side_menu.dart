import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:admin/constants.dart';
import 'package:admin/providers/portal_auth_provider.dart';

class SideMenu extends StatelessWidget {
  const SideMenu({
    super.key,
    required this.onMenuItemClick,
    required this.selectedIndex,
    this.isDrawer = false,
  });

  final Function(int) onMenuItemClick;
  final int selectedIndex;
  final bool isDrawer;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isDrawer ? null : 250,
      decoration: BoxDecoration(
        color: secondaryColor,
        border: Border(
          right: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            height: 100,
            padding: const EdgeInsets.all(defaultPadding),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
            ),
            child: Center(
              child: Image.asset(
                "assets/icons/wd_logo.png",
                width: 120,
                height: 40,
                fit: BoxFit.contain,
              ),
            ),
          ),
          // Menu Items
          Expanded(
            child: ListView(
              children: [
                // _buildMenuItem(
                //   context,
                //   title: dashboardModule,
                //   svgSrc: "assets/icons/menu_dashboard.svg",
                //   index: 0,
                // ),
                _buildMenuItem(
                  context,
                  title: leadsModule,
                  svgSrc: "assets/icons/menu_leads.svg",
                  index: 1,
                ),
                _buildMenuItem(
                  context,
                  title: customersModule,
                  svgSrc: "assets/icons/menu_profile.svg",
                  index: 2,
                ),
                // _buildMenuItem(
                //   context,
                //   title: clientsModule,
                //   svgSrc: "assets/icons/menu_doc.svg",
                //   index: 3,
                // ),
                // _buildMenuItem(
                //   context,
                //   title: projectsModule,
                //   svgSrc: "assets/icons/menu_task.svg",
                //   index: 3,
                // ),
                // _buildMenuItem(
                //   context,
                //   title: quotationsModule,
                //   svgSrc: "assets/icons/menu_doc.svg",
                //   index: 4,
                // ),
                // _buildMenuItem(
                //   context,
                //   title: contractsModule,
                //   svgSrc: "assets/icons/menu_doc.svg",
                //   index: 5,
                // ),
                // _buildMenuItem(
                //   context,
                //   title: followUpsModule,
                //   svgSrc: "assets/icons/menu_notification.svg",
                //   index: 6,
                // ),
                // _buildMenuItem(
                //   context,
                //   title: siteVisitsModule,
                //   svgSrc: "assets/icons/menu_store.svg",
                //   index: 7,
                // ),
                // _buildMenuItem(
                //   context,
                //   title: tasksModule,
                //   svgSrc: "assets/icons/menu_task.svg",
                //   index: 8,
                // ),
                // _buildMenuItem(
                //   context,
                //   title: teamMembersModule,
                //   svgSrc: "assets/icons/menu_profile.svg",
                //   index: 9,
                // ),
                // _buildMenuItem(
                //   context,
                //   title: communicationModule,
                //   svgSrc: "assets/icons/menu_notification.svg",
                //   index: 10,
                // ),
                // _buildMenuItem(
                //   context,
                //   title: documentsModule,
                //   svgSrc: "assets/icons/menu_doc.svg",
                //   index: 11,
                // ),
                // _buildMenuItem(
                //   context,
                //   title: invoicesModule,
                //   svgSrc: "assets/icons/menu_tran.svg",
                //   index: 12,
                // ),
                // _buildMenuItem(
                //   context,
                //   title: reportsModule,
                //   svgSrc: "assets/icons/menu_setting.svg",
                //   index: 13,
                // ),
              ],
            ),
          ),
          // Logout Button
          Container(
            padding: const EdgeInsets.all(defaultPadding),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final authProvider =
                      Provider.of<PortalAuthProvider>(context, listen: false);
                  await authProvider.logout();
                },
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required String title,
    required String svgSrc,
    required int index,
  }) {
    final isSelected = selectedIndex == index;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? primaryColor : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        onTap: () {
          onMenuItemClick(index);
          if (isDrawer) {
            Navigator.of(context).pop(); // Close drawer on mobile
          }
        },
        horizontalTitleGap: 0.0,
        selected: isSelected,
        selectedTileColor: Colors.transparent,
        leading: SvgPicture.asset(
          svgSrc,
          colorFilter: ColorFilter.mode(
            isSelected ? Colors.white : Colors.grey[600]!,
            BlendMode.srcIn,
          ),
          height: 16,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
