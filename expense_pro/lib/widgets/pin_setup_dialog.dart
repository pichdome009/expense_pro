import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/security_service.dart';

class PinSetupDialog extends StatefulWidget {
  final VoidCallback onPinSet;

  const PinSetupDialog({super.key, required this.onPinSet});

  @override
  State<PinSetupDialog> createState() => _PinSetupDialogState();
}

class _PinSetupDialogState extends State<PinSetupDialog> {
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  String? _errorMessage;

  void _onKeyPress(String digit) {
    setState(() {
      _errorMessage = null;
      if (!_isConfirming) {
        if (_pin.length < 4) {
          _pin += digit;
          if (_pin.length == 4) {
            // Move to confirmation step
            Future.delayed(const Duration(milliseconds: 150), () {
              if (mounted) {
                setState(() => _isConfirming = true);
              }
            });
          }
        }
      } else {
        if (_confirmPin.length < 4) {
          _confirmPin += digit;
          if (_confirmPin.length == 4) {
            // Verify
            if (_pin == _confirmPin) {
              _savePin();
            } else {
              setState(() {
                _errorMessage = 'លេខកូដមិនត្រូវគ្នាទេ! សូមសាកល្បងម្តងទៀត';
                _confirmPin = '';
                _pin = '';
                _isConfirming = false;
              });
            }
          }
        }
      }
    });
  }

  void _onBackspace() {
    setState(() {
      _errorMessage = null;
      if (_isConfirming) {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        } else {
          _isConfirming = false;
        }
      } else {
        if (_pin.isNotEmpty) {
          _pin = _pin.substring(0, _pin.length - 1);
        }
      }
    });
  }

  Future<void> _savePin() async {
    await SecurityService.setPinCode(_pin);
    await SecurityService.setAppLockEnabled(true);
    if (mounted) {
      widget.onPinSet();
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('បានកំណត់លេខកូដ PIN ដោយជោគជ័យ!'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeLength = _isConfirming ? _confirmPin.length : _pin.length;

    return Dialog(
      backgroundColor: isDark ? AppColors.cardDark : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_outline_rounded, color: AppColors.primary, size: 30),
            ),
            const SizedBox(height: 16),
            Text(
              _isConfirming ? 'ផ្ទៀងផ្ទាត់លេខសម្ងាត់ PIN' : 'កំណត់លេខសម្ងាត់ PIN ថ្មី',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _isConfirming
                  ? 'សូមបញ្ចូលលេខកូដ ៤ ខ្ទង់ម្តងទៀត'
                  : 'សូមបញ្ចូលលេខកូដសម្ងាត់ ៤ ខ្ទង់ដើម្បីការពារទិន្នន័យ',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            // Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final filled = index < activeLength;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: filled ? 18 : 14,
                  height: filled ? 18 : 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled ? AppColors.primary : Colors.grey.withValues(alpha: 0.25),
                  ),
                );
              }),
            ),
            const SizedBox(height: 28),
            // Keypad
            _buildKeypad(isDark),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'បោះបង់',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad(bool isDark) {
    return Column(
      children: [
        for (var row = 0; row < 3; row++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (var col = 1; col <= 3; col++)
                  _keyButton('${row * 3 + col}', isDark),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: 60, height: 60),
              _keyButton('0', isDark),
              SizedBox(
                width: 60,
                height: 60,
                child: IconButton(
                  icon: const Icon(Icons.backspace_outlined),
                  onPressed: _onBackspace,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _keyButton(String text, bool isDark) {
    return SizedBox(
      width: 60,
      height: 60,
      child: Material(
        color: isDark ? Colors.white10 : Colors.grey.shade100,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _onKeyPress(text),
          child: Center(
            child: Text(
              text,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
