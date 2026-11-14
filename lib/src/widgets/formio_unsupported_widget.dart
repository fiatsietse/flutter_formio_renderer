import 'package:flutter/material.dart';

/// Development placeholder shown when a Form.io component type is not supported
/// or not yet registered in [FormioComponentRegistry].
class FormioUnsupportedWidget extends StatelessWidget {
  final String type;
  final String keyName;
  final String dataPath;

  const FormioUnsupportedWidget({
    super.key,
    required this.type,
    required this.keyName,
    required this.dataPath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.amber.shade400, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded,
              color: Colors.amber.shade800, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unsupported Component: "$type"',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Key: $keyName | Path: $dataPath',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.amber.shade900.withOpacity(0.8),
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Register a custom renderer via FormioComponentRegistry or inspect schema.',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
