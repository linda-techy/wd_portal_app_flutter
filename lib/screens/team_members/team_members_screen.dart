import 'package:flutter/material.dart';
import 'package:admin/constants.dart';

class TeamMembersScreen extends StatefulWidget {
  const TeamMembersScreen({super.key});

  @override
  _TeamMembersScreenState createState() => _TeamMembersScreenState();
}

class _TeamMembersScreenState extends State<TeamMembersScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Team Members Management",
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
                    "Team Members Management - Coming Soon",
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
