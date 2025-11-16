import 'package:flutter/material.dart';
import 'package:admin/constants.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  _ProjectsScreenState createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Projects Management",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: defaultPadding),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(defaultPadding),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                child: const Center(
                  child: Text(
                    "Projects Management - Coming Soon",
                    style: TextStyle(fontSize: 18),
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
