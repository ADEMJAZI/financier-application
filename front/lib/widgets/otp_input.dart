import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ── Public OTP row ─────────────────────────────────────────────────────────────

/// A row of [count] individual digit boxes for OTP entry.
/// Handles auto-advance, backspace, paste (Ctrl/Cmd+V on first box),
/// and error-state border coloring.
class OtpBoxRow extends StatelessWidget {
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final void Function(int index, String value) onChanged;
  final void Function(String pasted) onPaste;
  final bool hasError;

  const OtpBoxRow({
    super.key,
    required this.controllers,
    required this.focusNodes,
    required this.onChanged,
    required this.onPaste,
    required this.hasError,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(controllers.length, (i) {
        return Padding(
          padding: EdgeInsets.only(left: i == 0 ? 0 : 10),
          child: OtpBox(
            controller: controllers[i],
            focusNode: focusNodes[i],
            hasError: hasError,
            onChanged: (v) => onChanged(i, v),
            onPaste: i == 0 ? onPaste : null,
          ),
        );
      }),
    );
  }
}

// ── Individual digit box ───────────────────────────────────────────────────────

class OtpBox extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final ValueChanged<String> onChanged;
  final void Function(String)? onPaste;

  const OtpBox({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.hasError,
    required this.onChanged,
    this.onPaste,
  });

  @override
  State<OtpBox> createState() => _OtpBoxState();
}

class _OtpBoxState extends State<OtpBox> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    setState(() => _focused = widget.focusNode.hasFocus);
  }

  Color get _borderColor {
    if (widget.hasError) return const Color(0xFFFF4B6E);
    if (_focused) return const Color(0xFF00B894);
    if (widget.controller.text.isNotEmpty) {
      return const Color(0xFF00B894).withOpacity(0.5);
    }
    return Colors.white.withOpacity(0.1);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 46,
      height: 58,
      decoration: BoxDecoration(
        color: const Color(0xFF1C1B2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor, width: _focused ? 1.8 : 1.2),
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: const Color(0xFF00B894).withOpacity(0.25),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: RawKeyboardListener(
        focusNode: FocusNode(),
        onKey: (event) {
          if (widget.onPaste == null) return;
          if (event is RawKeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.keyV &&
              (event.isControlPressed || event.isMetaPressed)) {
            Clipboard.getData(Clipboard.kTextPlain).then((data) {
              if (data?.text != null) widget.onPaste!(data!.text!);
            });
          }
        },
        child: TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(2),
          ],
          maxLength: 2,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
          decoration: const InputDecoration(
            counterText: '',
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: widget.onChanged,
        ),
      ),
    );
  }
}

// ── Resend row ─────────────────────────────────────────────────────────────────

/// Shows "Didn't receive a code?" with either a countdown timer, a loading
/// spinner, or an active "Resend code" link depending on state.
class ResendRow extends StatelessWidget {
  final int secondsRemaining;
  final bool isResending;
  final VoidCallback onResend;

  const ResendRow({
    super.key,
    required this.secondsRemaining,
    required this.isResending,
    required this.onResend,
  });

  @override
  Widget build(BuildContext context) {
    final canResend = secondsRemaining == 0 && !isResending;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Didn't receive a code? ",
          style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 13,
          ),
        ),
        if (isResending)
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              color: Color(0xFF00B894),
              strokeWidth: 2,
            ),
          )
        else if (secondsRemaining > 0)
          Text(
            'Resend in ${secondsRemaining}s',
            style: TextStyle(
              color: Colors.white.withOpacity(0.35),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          )
        else
          GestureDetector(
            onTap: canResend ? onResend : null,
            child: const Text(
              'Resend code',
              style: TextStyle(
                color: Color(0xFF00B894),
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}

// ── OTP screen mixin ───────────────────────────────────────────────────────────

/// Shared state logic for any screen that hosts a 6-box OTP input.
/// Mix into a [State] class to get controllers, focus nodes, paste handling,
/// auto-advance, and the 60-second resend cooldown timer for free.
///
/// Usage:
///   class _MyScreenState extends ConsumerState<MyScreen>
///       with OtpInputMixin, SingleTickerProviderStateMixin { ... }
mixin OtpInputMixin<T extends StatefulWidget> on State<T> {
  static const int otpLength = 6;
  static const int resendCooldownSeconds = 60;

  final List<TextEditingController> otpControllers =
      List.generate(otpLength, (_) => TextEditingController());
  final List<FocusNode> otpFocusNodes =
      List.generate(otpLength, (_) => FocusNode());

  int resendSecondsRemaining = resendCooldownSeconds;
  Timer? resendTimer;

  String get currentOtpCode => otpControllers.map((c) => c.text).join();
  bool get isOtpComplete =>
      currentOtpCode.length == otpLength && !currentOtpCode.contains(' ');

  void startResendTimer() {
    resendTimer?.cancel();
    setState(() => resendSecondsRemaining = resendCooldownSeconds);
    resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (resendSecondsRemaining > 0) {
          resendSecondsRemaining--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  void onOtpDigitChanged(int index, String value, {VoidCallback? onComplete}) {
    if (value.isEmpty) {
      if (index > 0) otpFocusNodes[index - 1].requestFocus();
      return;
    }
    final digit = value.characters.last;
    otpControllers[index].text = digit;
    otpControllers[index].selection =
        const TextSelection.collapsed(offset: 1);

    if (index < otpLength - 1) {
      otpFocusNodes[index + 1].requestFocus();
    } else {
      otpFocusNodes[index].unfocus();
      if (isOtpComplete) onComplete?.call();
    }
  }

  void onOtpPaste(String pasted, {VoidCallback? onComplete}) {
    final digits = pasted.replaceAll(RegExp(r'\D'), '');
    if (digits.length < otpLength) return;
    for (int i = 0; i < otpLength; i++) {
      otpControllers[i].text = digits[i];
    }
    otpFocusNodes[otpLength - 1].unfocus();
    setState(() {});
    if (isOtpComplete) onComplete?.call();
  }

  void clearOtpBoxes() {
    for (final c in otpControllers) {
      c.clear();
    }
    if (otpFocusNodes[0].canRequestFocus) otpFocusNodes[0].requestFocus();
  }

  void disposeOtpResources() {
    resendTimer?.cancel();
    for (final c in otpControllers) {
      c.dispose();
    }
    for (final f in otpFocusNodes) {
      f.dispose();
    }
  }
}
