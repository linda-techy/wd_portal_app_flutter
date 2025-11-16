import 'package:flutter/material.dart';
import 'package:admin/constants.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  _InvoicesScreenState createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Invoices Management",
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
                    "Invoices Management - Coming Soon",
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
