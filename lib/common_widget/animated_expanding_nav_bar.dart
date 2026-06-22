import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';

class AnimatedExpandingNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<AnimatedNavDestination> destinations;
  final Color? backgroundColor;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;
  final double height;

  const AnimatedExpandingNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    this.backgroundColor,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.height = 70,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          height: height,
          padding: EdgeInsets.only(left: 16, right: 16),
          decoration: BoxDecoration(
            color: (backgroundColor ?? Colors.white).withOpacity(0.7),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.2), width: 0.5),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: destinations.asMap().entries.map((entry) {
              final index = entry.key;
              final destination = entry.value;
              final isSelected = selectedIndex == index;

              return GestureDetector(
                onTap: () => onDestinationSelected(index),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  padding: EdgeInsets.symmetric(
                    horizontal: isSelected ? 16 : 12,
                    vertical: 13, // Increased by 5 (from 8 to 13)
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (selectedItemColor ?? AppColors.primary)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          isSelected
                              ? Colors.white
                              : (unselectedItemColor ?? AppColors.grey),
                          BlendMode.srcIn,
                        ),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: isSelected
                                ? destination.selectedIcon
                                : destination.icon,
                          ),
                        ),
                      ),
                      if (isSelected)
                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: Padding(
                            padding: const EdgeInsets.only(
                              left: 8.0,
                              right: 8.0,
                            ),
                            child: Text(
                              destination.label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.clip,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class AnimatedNavDestination {
  final Widget icon;
  final Widget selectedIcon;
  final String label;

  const AnimatedNavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}
