import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'products/products_screen.dart';
import 'collections/collections_screen.dart';
import 'routine/routine_home_screen.dart';
import 'profile/profile_screen.dart';

class MainNavigation extends StatefulWidget {
  final int initialIndex;
  const MainNavigation({super.key, this.initialIndex = 2});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late int _index = widget.initialIndex;

  final _screens = const [
    ProductsScreen(),
    CollectionsScreen(),
    RoutineHomeScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildNavBar() {
    final items = [
      {'icon': Icons.shopping_bag_outlined, 'label': 'Ürünler'},
      {'icon': Icons.bookmarks_outlined, 'label': 'Koleksiyon'},
      {'icon': Icons.calendar_today_outlined, 'label': 'Rutin'},
      {'icon': Icons.person_outline, 'label': 'Profil'},
    ];
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          border:
              Border(top: BorderSide(color: AppColors.softGreen, width: 0.5))),
      child: SafeArea(
        child: SizedBox(
          height: 58,
          child: Row(
              children: List.generate(items.length, (i) {
            final active = i == _index;
            return Expanded(
              child: InkWell(
                onTap: () => setState(() => _index = i),
                splashColor: AppColors.lightGreen,
                highlightColor: AppColors.lightGreen,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(items[i]['icon'] as IconData,
                            size: 21,
                            color: active
                                ? AppColors.primary
                                : AppColors.textLight),
                        const SizedBox(height: 3),
                        Text(items[i]['label'] as String,
                            style: TextStyle(
                                fontSize: 8.5,
                                color: active
                                    ? AppColors.primary
                                    : AppColors.textGrey,
                                fontWeight: active
                                    ? FontWeight.w600
                                    : FontWeight.w400)),
                      ]),
                ),
              ),
            );
          })),
        ),
      ),
    );
  }
}
