import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/neumorphic.dart';
import '../widgets/spatial_background.dart';

/// History & Analytics Screen
///
/// Faithfully reproduces the "History" screen from the Neumorphic reference image:
/// - Top bar with extruded back and menu buttons
/// - Bold "History" title
/// - Pill filter tabs ("Today", "Yesterday", "Month") with tactile inset indentation
/// - 3D Rainbow Donut Chart with raised center cap and "✖ 30% (Food)" callout badge
/// - "Show my transactions" extruded button
/// - Recent activity / transaction history list with soft extruded tiles
class HistoryScreen extends StatefulWidget {
  final VoidCallback? onBackTap;
  final VoidCallback? onMenuTap;

  const HistoryScreen({
    super.key,
    this.onBackTap,
    this.onMenuTap,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _selectedFilter = 0;
  bool _showTransactions = false;

  final List<String> _filters = const ['Today', 'Yesterday', 'Month'];

  final List<_TransactionItem> _transactions = const [
    _TransactionItem(
      title: 'Whole Foods Market',
      category: 'Food & Groceries',
      amount: '-\$42.50',
      icon: Icons.shopping_basket_rounded,
      time: '12:30 PM',
      percentage: '30%',
    ),
    _TransactionItem(
      title: 'Harmoniq Hi-Fi Stream',
      category: 'Digital Entertainment',
      amount: '-\$9.99',
      icon: Icons.headphones_rounded,
      time: '09:15 AM',
      percentage: '15%',
    ),
    _TransactionItem(
      title: 'Blue Bottle Coffee',
      category: 'Dining & Drinks',
      amount: '-\$6.75',
      icon: Icons.local_cafe_rounded,
      time: '08:40 AM',
      percentage: '8%',
    ),
    _TransactionItem(
      title: 'Salary Direct Deposit',
      category: 'Payroll & Income',
      amount: '+\$2,450.00',
      icon: Icons.account_balance_rounded,
      time: '06:00 AM',
      isIncome: true,
      percentage: '',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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

                // Title: History
                const Text(
                  'History',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 22),

                // Filter Pill Tabs (Today, Yesterday, Month)
                NeumorphicSegmentedControl(
                  segments: _filters,
                  selectedIndex: _selectedFilter,
                  onSelected: (index) => setState(() => _selectedFilter = index),
                ),
                const SizedBox(height: 36),

                // 3D Rainbow Donut Chart with raised center cap & callout badge
                const NeumorphicDonutChart(
                  size: 240,
                  calloutLabel: '30% (Food)',
                ),
                const SizedBox(height: 36),

                // "Show my transactions" Extruded Button
                Center(
                  child: NeumorphicButton(
                    borderRadius: 22,
                    depth: 4.5,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 36,
                      vertical: 16,
                    ),
                    onTap: () => setState(() => _showTransactions = !_showTransactions),
                    child: Text(
                      _showTransactions ? 'Hide transactions' : 'Show my transactions',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Recent Transactions List
                if (_showTransactions) ...[
                  const Text(
                    'Recent Activity',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ..._transactions.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: NeumorphicBox(
                          borderRadius: 18,
                          depth: 3.5,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              NeumorphicBox(
                                width: 42,
                                height: 42,
                                shape: BoxShape.circle,
                                depth: 2.5,
                                child: Icon(
                                  item.icon,
                                  size: 20,
                                  color: item.isIncome
                                      ? AppColors.success
                                      : AppColors.coral,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${item.category} · ${item.time}',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                item.amount,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: item.isIncome
                                      ? AppColors.success
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TransactionItem {
  final String title;
  final String category;
  final String amount;
  final IconData icon;
  final String time;
  final String percentage;
  final bool isIncome;

  const _TransactionItem({
    required this.title,
    required this.category,
    required this.amount,
    required this.icon,
    required this.time,
    required this.percentage,
    this.isIncome = false,
  });
}
