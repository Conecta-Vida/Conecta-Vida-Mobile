// lib/components/custom_bottom_nav_bar.dart
import 'package:flutter/material.dart';
import '../global/appCor.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(Icons.home, Icons.home_outlined, 0),
          _buildNotificationItem(1),
          _buildCenterAddItem(2),
          _buildNavItem(Icons.shopping_bag, Icons.shopping_bag_outlined, 3),
          _buildNavItem(Icons.person, Icons.person_outline, 4),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData activeIcon, IconData inactiveIcon, int index) {
    bool isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Icon(
          isSelected ? activeIcon : inactiveIcon,
          color: isSelected ? AppCor.primary : Colors.grey.shade400,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildNotificationItem(int index) {
    bool isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Stack(
          children: [
            Icon(
              isSelected
                  ? Icons.notifications
                  : Icons.notifications_none_outlined,
              color: isSelected ? AppCor.primary : Colors.grey.shade400,
              size: 28,
            ),
            Positioned(
              right: 2,
              top: 2,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterAddItem(int index) {
    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: AppCor.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 26),
      ),
    );
  }
}
