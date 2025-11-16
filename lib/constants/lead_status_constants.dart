import 'package:flutter/material.dart';

class LeadStatusConstants {
  // Lead status values
  static const String newInquiry = 'new_inquiry';
  static const String contacted = 'contacted';
  static const String qualifiedLead = 'qualified_lead';
  static const String proposalSent = 'proposal_sent';
  static const String negotiation = 'negotiation';
  static const String projectWon = 'project_won';
  static const String lost = 'lost';

  // Lead status labels
  static const String newInquiryLabel = 'New Inquiry';
  static const String contactedLabel = 'Contacted';
  static const String qualifiedLeadLabel = 'Qualified Lead';
  static const String proposalSentLabel = 'Proposal Sent';
  static const String negotiationLabel = 'Negotiation';
  static const String projectWonLabel = 'Project Won';
  static const String lostLabel = 'Lost';

  // Dropdown items
  static const List<DropdownMenuItem<String>> dropdownItems = [
    DropdownMenuItem(value: newInquiry, child: Text(newInquiryLabel)),
    DropdownMenuItem(value: contacted, child: Text(contactedLabel)),
    DropdownMenuItem(value: qualifiedLead, child: Text(qualifiedLeadLabel)),
    DropdownMenuItem(value: proposalSent, child: Text(proposalSentLabel)),
    DropdownMenuItem(value: negotiation, child: Text(negotiationLabel)),
    DropdownMenuItem(value: projectWon, child: Text(projectWonLabel)),
    DropdownMenuItem(value: lost, child: Text(lostLabel)),
  ];

  // Search dropdown items (includes 'All')
  static const List<DropdownMenuItem<String>> searchDropdownItems = [
    DropdownMenuItem(value: newInquiry, child: Text(newInquiryLabel)),
    DropdownMenuItem(value: contacted, child: Text(contactedLabel)),
    DropdownMenuItem(value: qualifiedLead, child: Text(qualifiedLeadLabel)),
    DropdownMenuItem(value: proposalSent, child: Text(proposalSentLabel)),
    DropdownMenuItem(value: negotiation, child: Text(negotiationLabel)),
    DropdownMenuItem(value: projectWon, child: Text(projectWonLabel)),
    DropdownMenuItem(value: lost, child: Text(lostLabel)),
    DropdownMenuItem(value: 'All', child: Text('All')),
  ];

  // All valid values
  static const List<String> validValues = [
    newInquiry,
    contacted,
    qualifiedLead,
    proposalSent,
    negotiation,
    projectWon,
    lost,
  ];

  // Default value
  static const String defaultValue = newInquiry;

  // Get label by value
  static String getLabel(String value) {
    switch (value) {
      case newInquiry:
        return newInquiryLabel;
      case contacted:
        return contactedLabel;
      case qualifiedLead:
        return qualifiedLeadLabel;
      case proposalSent:
        return proposalSentLabel;
      case negotiation:
        return negotiationLabel;
      case projectWon:
        return projectWonLabel;
      case lost:
        return lostLabel;
      default:
        return newInquiryLabel;
    }
  }

  // Validate value
  static bool isValid(String value) {
    return validValues.contains(value);
  }

  // Get valid value or default
  static String getValidValue(String value) {
    return isValid(value) ? value : defaultValue;
  }
}
