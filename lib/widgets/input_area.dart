import 'package:flutter/material.dart';

class InputArea extends StatelessWidget {
  final TextEditingController controller;
  final bool isListening;
  final bool speechEnabled;
  final String lastWords;
  final Function(String) onSubmitted;
  final VoidCallback onStartListening;
  final VoidCallback onStopListening;

  const InputArea({
    super.key,
    required this.controller,
    required this.isListening,
    required this.speechEnabled,
    required this.lastWords,
    required this.onSubmitted,
    required this.onStartListening,
    required this.onStopListening,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: isListening
                    ? 'Listening: $lastWords'
                    : 'Enter details or tap mic...',
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
                suffixIcon: controller.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    onSubmitted(controller.text);
                    controller.clear();
                  },
                )
                    : null,
              ),
              onSubmitted: onSubmitted,
              textInputAction: TextInputAction.send,
            ),
          ),
          const SizedBox(width: 8.0),
          IconButton(
            icon: Icon(
              isListening ? Icons.mic : Icons.mic_none,
              color: speechEnabled
                  ? (isListening ? Colors.red : Theme.of(context).primaryColor)
                  : Colors.grey,
              size: 28,
            ),
            tooltip: isListening ? 'Stop listening' : (speechEnabled ? 'Tap to speak' : 'Speech not available'),
            onPressed: !speechEnabled ? null : (isListening ? onStopListening : onStartListening),
          ),
        ],
      ),
    );
  }
}