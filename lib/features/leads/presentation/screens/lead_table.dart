import 'package:flutter/material.dart';
import '../../data/models/lead.dart';

class LeadsTable extends StatelessWidget {
  final List<Lead> leads;
  final void Function(Lead) onEdit;
  final void Function(Lead) onDelete;
  final void Function(Lead) onConvert;

  const LeadsTable({
    super.key,
    required this.leads,
    required this.onEdit,
    required this.onDelete,
    required this.onConvert,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Name')),
          DataColumn(label: Text('Phone')),
          DataColumn(label: Text('Project Type')),
          DataColumn(label: Text('Stage')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Priority')),
          DataColumn(label: Text('Sales Rep')),
          DataColumn(label: Text('Budget')),
          DataColumn(label: Text('Probability')),
          DataColumn(label: Text('Client Rating')),
          DataColumn(label: Text('Actions')),
        ],
        rows: leads
            .map((lead) => DataRow(
                  cells: [
                    DataCell(Text(lead.name)),
                    DataCell(Text(lead.phone)),
                    DataCell(Text(lead.projectType)),
                    DataCell(Text(lead.status)), // This is the Stage column - using status for now
                    DataCell(Text(lead.status)), // This is the Status column
                    DataCell(Text(lead.priorityString)),
                    DataCell(Text(lead.assignedTo?.fullName ?? lead.assignedTeam)),
                    DataCell(Text(lead.budget?.toStringAsFixed(2) ?? '-')),
                    DataCell(Text('${lead.probabilityToWin}%')),
                    DataCell(Text('${lead.clientRating}/5')),
                    DataCell(
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          switch (value) {
                            case 'edit':
                              onEdit(lead);
                              break;
                            case 'convert':
                              onConvert(lead);
                              break;
                            case 'delete':
                              onDelete(lead);
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 20),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          if (lead.status.toLowerCase() != 'converted')
                            const PopupMenuItem(
                              value: 'convert',
                              child: Row(
                                children: [
                                  Icon(Icons.transform, size: 20, color: Colors.green),
                                  SizedBox(width: 8),
                                  Text('Convert to Customer'),
                                ],
                              ),
                            ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 20, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete'),
                              ],
                            ),
                          ),
                        ],
                        icon: const Icon(Icons.more_vert),
                      ),
                    ),
                  ],
                ))
            .toList(),
      ),
    );
  }
}
