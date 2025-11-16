import 'package:flutter/material.dart';
import 'package:admin/constants.dart';

class QuotationsScreen extends StatefulWidget {
  const QuotationsScreen({super.key});

  @override
  _QuotationsScreenState createState() => _QuotationsScreenState();
}

class _QuotationsScreenState extends State<QuotationsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Quotations Management",
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
                    "Quotations Management - Coming Soon",
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
