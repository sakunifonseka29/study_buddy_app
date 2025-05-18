import 'package:flutter/material.dart';

class APIConnectionStatus extends StatelessWidget {
  final bool isConnecting;
  final String message;
  final VoidCallback onRetry;

  const APIConnectionStatus({
    Key? key,
    required this.isConnecting,
    required this.message,
    required this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color:
            isConnecting
                ? Colors.blue.withOpacity(0.1)
                : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isConnecting ? Colors.blue.shade300 : Colors.orange.shade300,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:
                  isConnecting
                      ? Colors.blue.withOpacity(0.2)
                      : Colors.orange.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isConnecting ? Icons.cloud_sync : Icons.cloud_off,
              color: isConnecting ? Colors.blue : Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isConnecting ? 'Connecting...' : 'Connection Issue',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
          if (!isConnecting)
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          if (isConnecting)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }
}
