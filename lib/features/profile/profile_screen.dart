import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({required this.onDarkModeChanged, super.key});

  final ValueChanged<bool> onDarkModeChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: SvgPicture.asset(
                isDark
                    ? 'assets/chordplane_logo.svg'
                    : 'assets/chordplane_logo_light.svg',
                width: 84,
                height: 84,
              ),
            ),
            const SizedBox(height: 12),
            Text('Guitarist Name', style: theme.textTheme.headlineSmall),
            Text(
              '@guitaristname',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: const Text('Dark mode'),
              trailing: Switch(value: isDark, onChanged: onDarkModeChanged),
              onTap: () => onDarkModeChanged(!isDark),
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('App settings'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}
