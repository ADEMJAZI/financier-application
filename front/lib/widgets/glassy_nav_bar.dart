import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_animations.dart';

/// Height of the glassy navbar including its padding, used by child screens
/// to add bottom padding so their FABs/content don't get hidden.
const double kGlassyNavBarHeight = 110;

class GlassyNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;
  final List<BottomNavigationBarItem> items;

  const GlassyNavBar({
    super.key,
    required this.currentIndex,
    required this.onIndexChanged,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 24),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // Background Glass Pill
          ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                height: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFF151515).withOpacity(0.8),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.05),
                    width: 1,
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final itemWidth = constraints.maxWidth / items.length;
                    
                    return Stack(
                      children: [
                        // Animated sliding indicator
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          left: currentIndex * itemWidth,
                          bottom: 0,
                          width: itemWidth,
                          height: 4,
                          child: Center(
                            child: Container(
                              width: currentIndex == 2 ? 24 : 20,
                              height: currentIndex == 2 ? 4 : 3,
                              decoration: BoxDecoration(
                                color: const Color(0xFF00B894),
                                borderRadius: BorderRadius.circular(2),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00B894).withOpacity(0.5),
                                    blurRadius: currentIndex == 2 ? 6 : 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(items.length, (index) {
                            if (index == 2) {
                              return SizedBox(width: itemWidth);
                            }
                            return SizedBox(
                              width: itemWidth,
                              child: _NavBarItem(
                                item: items[index],
                                isSelected: currentIndex == index,
                                onTap: () => onIndexChanged(index),
                              ),
                            );
                          }),
                        ),
                      ],
                    );
                  }
                ),
              ),
            ),
          ),
          
          // Center Floating Button — Teal green to match app theme
          Positioned(
            bottom: 25,
            child: GestureDetector(
              onTap: () => onIndexChanged(2),
              child: ScaleInWidget(
                delay: const Duration(milliseconds: 500),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF00B894),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00B894).withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: IconTheme(
                      data: const IconThemeData(
                        color: Colors.white,
                        size: 28,
                      ),
                      child: items[2].icon,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Center item label
          Positioned(
            bottom: 8,
            child: Text(
              items[2].label ?? '',
              style: TextStyle(
                fontSize: 10,
                color: currentIndex == 2 ? Colors.white : Colors.white54,
                fontWeight: currentIndex == 2 ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final BottomNavigationBarItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(0, isSelected ? -4 : 0, 0),
            child: IconTheme(
              data: IconThemeData(
                color: isSelected ? Colors.white : Colors.white54,
                size: 24,
              ),
              child: isSelected ? item.activeIcon : item.icon,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? Colors.white : Colors.white54,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
            child: Text(
              item.label ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 7),
        ],
      ),
    );
  }
}
