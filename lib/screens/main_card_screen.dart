import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/neumorphic.dart';
import '../widgets/spatial_background.dart';

/// Main Card Screen
///
/// Faithfully reproduces the "Main Card" screen from the Neumorphic reference image:
/// - Top bar with extruded back and menu buttons
/// - Bold "Main Card" typography
/// - Extruded VISA Card with embossed details
/// - Neumorphic interactive switches for NFC Payment, Deposit, Fast blocking
/// - Recessed Transaction Limit slider with tactile dot knob
class MainCardScreen extends StatefulWidget {
  final VoidCallback? onBackTap;
  final VoidCallback? onMenuTap;

  const MainCardScreen({
    super.key,
    this.onBackTap,
    this.onMenuTap,
  });

  @override
  State<MainCardScreen> createState() => _MainCardScreenState();
}

class _MainCardScreenState extends State<MainCardScreen> {
  bool _nfcPayment = false;
  bool _deposit = true;
  bool _fastBlocking = true;
  double _transactionLimit = 2000.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SpatialNebulaBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Bar: Back Button + Menu Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    NeumorphicIconButton(
                      icon: Icons.arrow_back_rounded,
                      tooltip: 'Back',
                      onTap: () {
                        if (widget.onBackTap != null) {
                          widget.onBackTap!();
                        } else if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
                      },
                    ),
                    NeumorphicIconButton(
                      icon: Icons.menu_rounded,
                      tooltip: 'Menu',
                      onTap: widget.onMenuTap,
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Title: Main Card
                const Text(
                  'Main Card',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 22),

                // Neumorphic Credit Card
                const NeumorphicCreditCard(
                  cardNumber: '****  ****  ****  1385',
                  expires: '10/24',
                  cvv: '123',
                  cardType: 'VISA',
                ),
                const SizedBox(height: 32),

                // NFC Payment Toggle Row
                NeumorphicSettingRow(
                  icon: Icons.wifi,
                  title: 'NFC Payment',
                  subtitle: _nfcPayment ? 'Enabled' : 'Disabled',
                  trailing: NeumorphicSwitch(
                    value: _nfcPayment,
                    onChanged: (val) => setState(() => _nfcPayment = val),
                  ),
                ),
                const SizedBox(height: 12),

                // Deposit Toggle Row
                NeumorphicSettingRow(
                  icon: Icons.attach_money_rounded,
                  title: 'Deposit',
                  subtitle: _deposit ? 'Active · Direct deposits enabled' : 'Paused',
                  trailing: NeumorphicSwitch(
                    value: _deposit,
                    onChanged: (val) => setState(() => _deposit = val),
                  ),
                ),
                const SizedBox(height: 12),

                // Fast Blocking Toggle Row (from top-left of reference)
                NeumorphicSettingRow(
                  icon: Icons.lock_outline_rounded,
                  title: 'Fast blocking',
                  subtitle: _fastBlocking ? 'Active · Instant fraud protection' : 'Inactive',
                  trailing: NeumorphicSwitch(
                    value: _fastBlocking,
                    onChanged: (val) => setState(() => _fastBlocking = val),
                  ),
                ),
                const SizedBox(height: 24),

                // Transaction Limit Slider Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Transaction Limit:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '\$${_transactionLimit.toInt()}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                NeumorphicSlider(
                  value: _transactionLimit,
                  min: 500,
                  max: 5000,
                  onChanged: (val) => setState(() => _transactionLimit = val),
                ),
                const SizedBox(height: 32),

                // Quick Action Button
                Center(
                  child: NeumorphicButton(
                    borderRadius: 20,
                    depth: 4.5,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Card settings updated.'),
                          backgroundColor: AppColors.textPrimary,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: const Text(
                      'Manage Card Limits',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
