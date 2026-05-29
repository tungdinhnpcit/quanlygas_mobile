// lib/features/home/presentation/widgets/menu_grid_item.dart
import 'package:flutter/material.dart';
import '../../../../core/utils/menu_icon_mapper.dart';
import '../../../../features/auth/data/auth_models.dart';

class MenuGridItem extends StatelessWidget {
  final MenuInfo menu;
  final int index;
  final VoidCallback onTap;

  const MenuGridItem({
    super.key,
    required this.menu,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = menuCardColor(index);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color, color.withValues(alpha: 0.75)],
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildIcon(color),
              const SizedBox(height: 12),
              Text(
                menu.menuName,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(Color baseColor) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Icon(
        mapMenuIcon(menu.menuCode),
        size: 28,
        color: Colors.white,
      ),
    );
  }
}
