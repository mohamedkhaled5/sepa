import 'package:flutter/material.dart';
import 'package:seba/screens/home/group_screens/groups_display_screen.dart';

/// الصفحة الرئيسية للتطبيق. لا تحتوي على Scaffold خاص بها لتفادي ظهور
/// AppBar مزدوج، لأن GroupsDisplayScreen تحتها لها Scaffold وAppBar
/// وأزرار (FAB) خاصة بها بالفعل، بما فيها زرار "إضافة طالب" العام.
class HomePageScreen extends StatelessWidget {
  const HomePageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const GroupsDisplayScreen();
  }
}
