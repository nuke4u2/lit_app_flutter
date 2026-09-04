import 'package:flutter/material.dart';
import 'package:lit_reader/env/colors.dart';
import 'package:lit_reader/env/global.dart';
import 'package:lit_reader/screens/pin/pin_keypad.dart';

enum _PinFlow { create, change, remove }

enum _PinStep { current, newPin, confirm }

class PinSettingsScreen extends StatelessWidget {
  const PinSettingsScreen({super.key});

  Future<void> _openFlow(BuildContext context, _PinFlow flow) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (context) => _PinSetupScreen(flow: flow)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pinController,
      builder: (context, _) {
        final enabled = pinController.isEnabled;
        return Scaffold(
          appBar: AppBar(title: const Text('App PIN')),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(enabled ? Icons.lock : Icons.lock_open, size: 48, color: enabled ? kRed : null),
                        const SizedBox(height: 12),
                        Text(
                          enabled ? 'App PIN is on' : 'App PIN is off',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          enabled
                              ? 'Lit Reader locks whenever you leave the app or lock your phone.'
                              : 'Add a 4-digit PIN to hide your reading screen when you leave the app.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (!enabled)
                  FilledButton.icon(
                    onPressed: () => _openFlow(context, _PinFlow.create),
                    icon: const Icon(Icons.add),
                    label: const Text('Set PIN'),
                  )
                else ...[
                  FilledButton.icon(
                    onPressed: () => _openFlow(context, _PinFlow.change),
                    icon: const Icon(Icons.password),
                    label: const Text('Change PIN'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _openFlow(context, _PinFlow.remove),
                    icon: const Icon(Icons.lock_open),
                    label: const Text('Turn off PIN'),
                  ),
                ],
                const SizedBox(height: 24),
                Text(
                  'If you forget the PIN, clearing the app data or reinstalling the app is the only recovery option.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white60),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PinSetupScreen extends StatefulWidget {
  const _PinSetupScreen({required this.flow});

  final _PinFlow flow;

  @override
  State<_PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<_PinSetupScreen> {
  late _PinStep _step;
  String? _newPin;
  String? _errorText;
  int _attempt = 0;

  @override
  void initState() {
    super.initState();
    _step = widget.flow == _PinFlow.create ? _PinStep.newPin : _PinStep.current;
  }

  String get _title {
    return switch (_step) {
      _PinStep.current => 'Enter current PIN',
      _PinStep.newPin => widget.flow == _PinFlow.change ? 'Enter new PIN' : 'Create a PIN',
      _PinStep.confirm => 'Confirm new PIN',
    };
  }

  String? get _subtitle {
    return switch (_step) {
      _PinStep.current when widget.flow == _PinFlow.remove => 'Required before turning off the app lock',
      _PinStep.newPin => 'Choose exactly four digits',
      _PinStep.confirm => 'Enter the same four digits again',
      _ => null,
    };
  }

  Future<void> _handlePin(String pin) async {
    switch (_step) {
      case _PinStep.current:
        if (!pinController.verifyPin(pin)) {
          _showError('Incorrect PIN');
          return;
        }
        if (widget.flow == _PinFlow.remove) {
          await pinController.removePin();
          if (mounted) {
            Navigator.of(context).pop();
          }
          return;
        }
        setState(() {
          _step = _PinStep.newPin;
          _errorText = null;
          _attempt += 1;
        });
        return;
      case _PinStep.newPin:
        _newPin = pin;
        setState(() {
          _step = _PinStep.confirm;
          _errorText = null;
          _attempt += 1;
        });
        return;
      case _PinStep.confirm:
        if (pin != _newPin) {
          _newPin = null;
          setState(() {
            _step = _PinStep.newPin;
            _errorText = 'PINs did not match. Try again.';
            _attempt += 1;
          });
          return;
        }
        await pinController.setPin(pin);
        if (mounted) {
          Navigator.of(context).pop();
        }
    }
  }

  void _showError(String message) {
    setState(() {
      _errorText = message;
      _attempt += 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.flow == _PinFlow.remove ? 'Turn off PIN' : 'App PIN')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: PinKeypad(
              key: ValueKey('${_step.name}-$_attempt'),
              title: _title,
              subtitle: _subtitle,
              errorText: _errorText,
              onCompleted: _handlePin,
            ),
          ),
        ),
      ),
    );
  }
}
