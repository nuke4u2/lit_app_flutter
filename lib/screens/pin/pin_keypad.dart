import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lit_reader/env/colors.dart';

class PinKeypad extends StatefulWidget {
  const PinKeypad({
    super.key,
    required this.title,
    required this.onCompleted,
    this.subtitle,
    this.errorText,
  });

  final String title;
  final String? subtitle;
  final String? errorText;
  final FutureOr<void> Function(String pin) onCompleted;

  @override
  State<PinKeypad> createState() => _PinKeypadState();
}

class _PinKeypadState extends State<PinKeypad> {
  String _pin = '';
  bool _isSubmitting = false;

  Future<void> _addDigit(int digit) async {
    if (_isSubmitting || _pin.length == 4) {
      return;
    }

    HapticFeedback.selectionClick();
    setState(() => _pin += digit.toString());
    if (_pin.length == 4) {
      setState(() => _isSubmitting = true);
      await widget.onCompleted(_pin);
    }
  }

  void _removeDigit() {
    if (_isSubmitting || _pin.isEmpty) {
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        if (widget.subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.subtitle!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
        ],
        const SizedBox(height: 24),
        Semantics(
          label: '${_pin.length} of 4 PIN digits entered',
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              4,
              (index) => Container(
                width: 16,
                height: 16,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index < _pin.length ? kRed : Colors.transparent,
                  border: Border.all(color: index < _pin.length ? kRed : Colors.white54, width: 2),
                ),
              ),
            ),
          ),
        ),
        SizedBox(
          height: 44,
          child: Center(
            child: Text(
              widget.errorText ?? '',
              style: const TextStyle(color: kRed),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            children: [
              for (final row in const [
                [1, 2, 3],
                [4, 5, 6],
                [7, 8, 9],
              ])
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: row.map((digit) => _digitButton(digit)).toList(),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const SizedBox(width: 72, height: 72),
                  _digitButton(0),
                  SizedBox(
                    width: 72,
                    height: 72,
                    child: IconButton(
                      tooltip: 'Delete digit',
                      onPressed: _pin.isEmpty || _isSubmitting ? null : _removeDigit,
                      icon: const Icon(Icons.backspace_outlined),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _digitButton(int digit) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: SizedBox(
        width: 72,
        height: 72,
        child: OutlinedButton(
          onPressed: _isSubmitting ? null : () => _addDigit(digit),
          style: OutlinedButton.styleFrom(
            shape: const CircleBorder(),
            side: const BorderSide(color: Colors.white24),
          ),
          child: Text('$digit', style: Theme.of(context).textTheme.headlineMedium),
        ),
      ),
    );
  }
}
