import 'package:moneta/app/gallery/gallery_catalog.dart';
import 'package:moneta/design_system/atoms/moneta_icon_name.dart';
import 'package:moneta/design_system/molecules/date_group_header.dart';
import 'package:moneta/design_system/molecules/list_row.dart';
import 'package:moneta/design_system/molecules/section_header.dart';

/// Gallery sections for 📱 02 Home & Dashboard.
///
/// **Owner: the home agent.** The auth agent must not edit this file — see
/// `docs/ai-workflow/parallel-brief-home-dashboard.md`.
///
/// `test/app/gallery_test.dart` fails if a class under `lib/design_system` is
/// absent from the catalog, so every component built for the home flow is
/// registered here, in every variant Figma authors.
final List<GallerySection> homeSections = [
  // --- HOME: add below ---
  GallerySection(
    component: 'DateGroupHeader',
    figmaNodeId: '29:71',
    variants: [
      GalleryVariant(
        'Variant=Default',
        (_) => DateGroupHeader(
          date: DateTime.utc(2026, DateTime.august, 28, 17),
        ),
      ),
    ],
  ),
  GallerySection(
    component: 'ListRow',
    figmaNodeId: '35:113',
    variants: [
      GalleryVariant(
        'Accessory=Chevron',
        (_) => const ListRow(
          title: 'Notifications',
          subtitle: 'Manage account alerts',
          leadingIcon: MonetaIconName.bell,
          accessory: ListRowAccessory.chevron,
        ),
      ),
      GalleryVariant(
        'Accessory=Value',
        (_) => const ListRow(
          title: 'Currency',
          leadingIcon: MonetaIconName.dollarSign,
          accessory: ListRowAccessory.value,
          value: 'VND',
        ),
      ),
      GalleryVariant(
        'Accessory=Toggle',
        (_) => const ListRow(
          title: 'Budget alerts',
          subtitle: 'Warn before limits are reached',
          leadingIcon: MonetaIconName.alertTriangle,
          accessory: ListRowAccessory.toggle,
          toggled: true,
        ),
      ),
      GalleryVariant(
        'Accessory=Badge',
        (_) => const ListRow(
          title: 'Inbox',
          leadingIcon: MonetaIconName.mail,
          accessory: ListRowAccessory.badge,
          badgeLabel: '3 new',
        ),
      ),
      GalleryVariant(
        'Accessory=None',
        (_) => const ListRow(
          title: 'App version',
          subtitle: 'Moneta 1.0',
          leadingIcon: MonetaIconName.smartphone,
          accessory: ListRowAccessory.none,
        ),
      ),
    ],
  ),
  GallerySection(
    component: 'SectionHeader',
    figmaNodeId: '55:107',
    variants: [
      GalleryVariant(
        'Variant=Default',
        (_) => const SectionHeader(
          title: 'Recent activity',
          actionLabel: 'See all',
        ),
      ),
    ],
  ),
];
