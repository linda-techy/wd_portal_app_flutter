import 'package:flutter/material.dart';
import '../../models/lead.dart';

class LeadTable extends StatelessWidget {
  final List<Lead> leads;
  final void Function(Lead) onEdit;
  const LeadTable({super.key, required this.leads, required this.onEdit});

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
                    DataCell(Text(lead.status)),
                    DataCell(Text(lead.priorityString)),
                    DataCell(Text(lead.assignedTeam)),
                    DataCell(Text(lead.budget?.toStringAsFixed(2) ?? '-')),
                    DataCell(Text('${lead.probabilityToWin}%')),
                    DataCell(Text('${lead.clientRating}/5')),
                    DataCell(Row(children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => onEdit(lead),
                      ),
                    ])),
                  ],
                ))
            .toList(),
      ),
    );
  }
}
