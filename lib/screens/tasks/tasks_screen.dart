import 'package:flutter/material.dart';
import 'package:admin/constants.dart';
import 'package:admin/utils/container_styles.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  _TasksScreenState createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Tasks Management",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: defaultPadding),
            const Expanded(
              child: StyledContainer(
                type: ContainerType.info,
                child: Center(
                  child: Text(
                    "Tasks Management - Coming Soon",
                    style: TextStyle(fontSize: 18, color: textPrimary),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
