import 'package:flutter/material.dart';
import '../config/theme.dart';

/// AppBar standard de l'app, avec le dégradé identité ConnectSoft en fond
/// (au lieu du bleu plat par défaut du thème). À utiliser partout où un
/// AppBar simple (titre + retour + actions) est nécessaire.
class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;

  const GradientAppBar({super.key, this.title, this.actions, this.leading});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title,
      actions: actions,
      leading: leading,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(gradient: WaqtiTheme.primaryGradient),
      ),
    );
  }
}
