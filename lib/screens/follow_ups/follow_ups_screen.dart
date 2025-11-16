import 'package:flutter/material.dart';
import 'package:admin/constants.dart';

class FollowUpsScreen extends StatefulWidget {
  const FollowUpsScreen({super.key});

  @override
  _FollowUpsScreenState createState() => _FollowUpsScreenState();
}

class _FollowUpsScreenState extends State<FollowUpsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Follow-ups Management",
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
                    "Follow-ups Management - Coming Soon",
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
