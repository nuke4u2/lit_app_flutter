import 'package:flutter/material.dart';
import 'package:lit_reader/controllers/pin_controller.dart';
import 'package:lit_reader/screens/pin/pin_keypad.dart';

class AppLockGate extends StatefulWidget {
  const AppLockGate({super.key, required this.controller, required this.child});

  final PinController controller;
  final Widget child;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  int _failedAttempts = 0;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      widget.controller.lock();
    }
  }

  Future<void> _unlock(String pin) async {
    if (await widget.controller.unlock(pin)) {
      if (mounted) {
        setState(() => _errorText = null);
      }
      return;
    }

    if (mounted) {
      setState(() {
        _failedAttempts += 1;
        _errorText = 'Incorrect PIN';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final locked = widget.controller.isLocked;
        return Stack(
          fit: StackFit.expand,
          children: [
            Offstage(
              offstage: locked,
              child: TickerMode(enabled: !locked, child: widget.child),
            ),
            if (locked)
              ColoredBox(
                color: Colors.black,
                child: SafeArea(
                  child: Material(
                    color: Colors.black,
                    child: PopScope(
                      canPop: false,
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.lock_outline, size: 48),
                              const SizedBox(height: 20),
                              PinKeypad(
                                key: ValueKey(_failedAttempts),
                                title: 'Lit Reader is locked',
                                subtitle: 'Enter your 4-digit PIN',
                                errorText: _errorText,
                                onCompleted: _unlock,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
