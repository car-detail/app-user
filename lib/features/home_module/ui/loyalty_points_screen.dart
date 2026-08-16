import 'package:flutter/material.dart';
import '../../../Common/Color.dart';
import '../../../Common/CommonWidget.dart';
import '../../../Common/Constant.dart';

class LoyaltyPointsScreen extends StatelessWidget {
  final int points;

  const LoyaltyPointsScreen({required this.points, super.key});

  @override
  Widget build(BuildContext context) {
    final double discountValue = points * 50.0;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Loyalty Rewards",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontFamily: "Pop600",
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: ColorClass.base_color,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Premium Points Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    ColorClass.base_color,
                    ColorClass.base_color.withOpacity(0.8),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: ColorClass.base_color.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.stars_rounded,
                      color: Colors.white,
                      size: 64,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Your Balance",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontFamily: "Pop400",
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "$points Points",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontFamily: "Pop700",
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Equivalent to ${Constant.rupee}${discountValue.toStringAsFixed(0)} off next booking",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontFamily: "Pop500",
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Benefits List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "How it works",
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: "Pop600",
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildHowItWorksRow(
                    Icons.add_shopping_cart_rounded,
                    "Earn Points",
                    "Earn 1 loyalty point for every ₹100 spent on booking completed services.",
                    ColorClass.base_color,
                  ),
                  const Divider(height: 32),
                  _buildHowItWorksRow(
                    Icons.monetization_on_rounded,
                    "Big Value",
                    "1 loyalty point equals ₹50. The more you spend, the more discounts you get.",
                    Colors.orange,
                  ),
                  const Divider(height: 32),
                  _buildHowItWorksRow(
                    Icons.offline_pin_rounded,
                    "Auto-Apply",
                    "Redeem points directly on checkout when booking any service.",
                    Colors.blue,
                  ),
                  const SizedBox(height: 40),
                  // Terms banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.grey[600]),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            "Points are awarded once service is completed and cannot be transferred or exchanged for cash.",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                              fontFamily: "Pop400",
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHowItWorksRow(IconData icon, String title, String desc, Color iconColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: "Pop600",
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: "Pop400",
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
