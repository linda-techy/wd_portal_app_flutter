import 'package:admin/models/recent_file.dart';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../constants.dart';
import '../../../utils/container_styles.dart';

class RecentFiles extends StatelessWidget {
  const RecentFiles({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return StyledContainer(
      type: ContainerType.secondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Recent Files",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(
            width: double.infinity,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: defaultPadding,
                columns: const [
                  DataColumn(
                    label: Text("File Name"),
                  ),
                  DataColumn(
                    label: Text("Date"),
                  ),
                  DataColumn(
                    label: Text("Size"),
                  ),
                ],
                rows: List.generate(
                  demoRecentFiles.length,
                  (index) => recentFileDataRow(demoRecentFiles[index]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

DataRow recentFileDataRow(RecentFile fileInfo) {
  return DataRow(
    cells: [
      DataCell(
        Row(
          children: [
            SvgPicture.asset(
              fileInfo.icon!,
              height: 30,
              width: 30,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
                child: Text(
                  fileInfo.title!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
      DataCell(
        Text(
          fileInfo.date!,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      DataCell(
        Text(
          fileInfo.size!,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}
