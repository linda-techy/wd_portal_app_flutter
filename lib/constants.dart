import 'package:flutter/material.dart';
import 'package:admin/config/app_config.dart';

// Modern Professional Theme Colors - 2024
const Color primaryColor = Color(0xFF2563EB); // Modern Blue
const Color secondaryColor = Color(0xFFF8FAFC); // Clean Light Gray
const Color bgColor = Color(0xFFFFFFFF); // Pure White

// Container Colors - Modern Professional Theme
const Color containerBackground = Color(0xFFF8FAFC); // Clean light gray
const Color cardBackground = Color(0xFFFFFFFF); // Pure white
const Color containerBorder = Color(0xFFE2E8F0); // Modern gray border
const Color containerShadow = Color(0x0A000000); // Subtle modern shadow

// Box Container Colors - Modern Professional Theme
const Color boxPrimary = Color(0xFFEFF6FF); // Light modern blue
const Color boxSecondary = Color(0xFFF8FAFC); // Clean light gray
const Color boxSuccess = Color(0xFFECFDF5); // Light emerald green
const Color boxWarning = Color(0xFFFFFBEB); // Light amber
const Color boxError = Color(0xFFFEF2F2); // Light modern red
const Color boxInfo = Color(0xFFF0F9FF); // Light cyan
const Color boxGray = Color(0xFFF9FAFB); // Very light gray
const Color boxPurple = Color(0xFFF3E8FF); // Light modern purple

// Box Border Colors - Modern Professional Theme
const Color boxBorderPrimary = Color(0xFFBFDBFE); // Modern blue border
const Color boxBorderSecondary = Color(0xFFCBD5E1); // Modern gray border
const Color boxBorderSuccess = Color(0xFFA7F3D0); // Modern emerald border
const Color boxBorderWarning = Color(0xFFFDE68A); // Modern amber border
const Color boxBorderError = Color(0xFFFECACA); // Modern red border
const Color boxBorderInfo = Color(0xFF7DD3FC); // Modern cyan border

// Modern Professional Accent Colors - 2024
const Color successColor = Color(0xFF059669); // Modern Emerald Green
const Color warningColor = Color(0xFFF59E0B); // Modern Amber
const Color errorColor = Color(0xFFDC2626); // Modern Red
const Color infoColor = Color(0xFF0891B2); // Modern Cyan

// Text Colors
const Color textPrimary = Color(0xFF1F2937);
const Color textSecondary = Color(0xFF6B7280);
const Color textMuted = Color(0xFF9CA3AF);

const double defaultPadding = 16.0;

// API Configuration - Using AppConfig
class ApiConfig {
  // Get the appropriate base URL based on environment
  static String get baseUrl => AppConfig.apiBaseUrl;

  // API version
  static const String apiVersion = AppConfig.apiVersion;

  // Full API URL
  static String get fullApiUrl => AppConfig.fullApiUrl;
}

// Legacy support (keeping for backward compatibility)
const String baseUrl = AppConfig.localApiUrl;
const String apiVersion = AppConfig.apiVersion;

// CRM Module Names
const String dashboardModule = 'Dashboard';
const String leadsModule = 'Leads';
const String customersModule = 'Customers';
const String clientsModule = 'Clients';
const String projectsModule = 'Projects';
const String quotationsModule = 'Quotations';
const String contractsModule = 'Contracts';
const String followUpsModule = 'Follow-ups';
const String siteVisitsModule = 'Site Visits';
const String tasksModule = 'Tasks';
const String teamMembersModule = 'Team Members';
const String communicationModule = 'Communication';
const String documentsModule = 'Documents';
const String invoicesModule = 'Invoices';
const String reportsModule = 'Reports';

// Status Constants
const List<String> leadStatuses = [
  'New Inquiry',
  'Contacted',
  'Qualified Lead',
  'Proposal Sent',
  'Negotiation',
  'Project Won',
  'Lost'
];
const List<String> projectStatuses = [
  'Planning',
  'In Progress',
  'On Hold',
  'Completed',
  'Cancelled'
];
const List<String> taskStatuses = [
  'Pending',
  'In Progress',
  'Completed',
  'Cancelled'
];
const List<String> priorityLevels = ['Low', 'Medium', 'High', 'Urgent'];
