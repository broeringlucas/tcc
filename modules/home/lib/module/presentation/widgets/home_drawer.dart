import 'package:flutter/material.dart';

import 'thesis_info_section.dart';

class HomeDrawer extends StatelessWidget {
  const HomeDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return const Drawer(child: SafeArea(child: ThesisInfoSection()));
  }
}
