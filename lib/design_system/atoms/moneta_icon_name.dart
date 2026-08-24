/// Every icon on the Figma iconography page (node `5:7`), addressable by name.
///
/// The set is exported vector assets rather than an icon package: the design is
/// drawn at stroke weight 1.75, which no published set matches, and the file
/// includes brand marks that no icon package carries. See
/// docs/adr/0002-icon-delivery.md.
enum MonetaIconName {
  /// `icon/alert-triangle`.
  alertTriangle('alert-triangle'),

  /// `icon/arrow-down-left`.
  arrowDownLeft('arrow-down-left'),

  /// `icon/arrow-up-right`.
  arrowUpRight('arrow-up-right'),

  /// `icon/award`.
  award('award'),

  /// `icon/bell`.
  bell('bell'),

  /// `icon/brand-apple`.
  brandApple('brand-apple'),

  /// `icon/brand-google`.
  brandGoogle('brand-google', preservesColour: true),

  /// `icon/briefcase`.
  briefcase('briefcase'),

  /// `icon/calendar`.
  calendar('calendar'),

  /// `icon/camera`.
  camera('camera'),

  /// `icon/car`.
  car('car'),

  /// `icon/check`.
  check('check'),

  /// `icon/chevron-down`.
  chevronDown('chevron-down'),

  /// `icon/chevron-left`.
  chevronLeft('chevron-left'),

  /// `icon/chevron-right`.
  chevronRight('chevron-right'),

  /// `icon/chevron-up`.
  chevronUp('chevron-up'),

  /// `icon/coffee`.
  coffee('coffee'),

  /// `icon/credit-card`.
  creditCard('credit-card'),

  /// `icon/dollar-sign`.
  dollarSign('dollar-sign'),

  /// `icon/download`.
  download('download'),

  /// `icon/edit`.
  edit('edit'),

  /// `icon/eye`.
  eye('eye'),

  /// `icon/eye-off`.
  eyeOff('eye-off'),

  /// `icon/file-text`.
  fileText('file-text'),

  /// `icon/film`.
  film('film'),

  /// `icon/gift`.
  gift('gift'),

  /// `icon/heart`.
  heart('heart'),

  /// `icon/help-circle`.
  helpCircle('help-circle'),

  /// `icon/home`.
  home('home'),

  /// `icon/info`.
  info('info'),

  /// `icon/list`.
  list('list'),

  /// `icon/lock`.
  lock('lock'),

  /// `icon/mail`.
  mail('mail'),

  /// `icon/more-horizontal`.
  moreHorizontal('more-horizontal'),

  /// `icon/pie-chart`.
  pieChart('pie-chart'),

  /// `icon/plus`.
  plus('plus'),

  /// `icon/repeat`.
  repeat('repeat'),

  /// `icon/scan-face`.
  scanFace('scan-face'),

  /// `icon/search`.
  search('search'),

  /// `icon/shield`.
  shield('shield'),

  /// `icon/shopping-bag`.
  shoppingBag('shopping-bag'),

  /// `icon/sliders`.
  sliders('sliders'),

  /// `icon/smartphone`.
  smartphone('smartphone'),

  /// `icon/target`.
  target('target'),

  /// `icon/trash`.
  trash('trash'),

  /// `icon/trending-up`.
  trendingUp('trending-up'),

  /// `icon/user`.
  user('user'),

  /// `icon/wifi-off`.
  wifiOff('wifi-off'),

  /// `icon/x`.
  x('x'),

  /// `icon/zap`.
  zap('zap');

  const MonetaIconName(this.figmaName, {this.preservesColour = false});

  /// The icon's name in Figma, without the `icon/` prefix.
  final String figmaName;

  /// Whether the asset carries its own colours and must not be tinted.
  ///
  /// True only for multi-colour brand marks. Tinting `brand-google` would
  /// flatten Google's four-colour mark into one colour, which is both wrong and
  /// a brand-guideline violation.
  final bool preservesColour;

  /// Path of the bundled SVG.
  String get assetPath => 'assets/icons/$figmaName.svg';

  /// Looks up an icon by its Figma name.
  ///
  /// Returns `null` rather than a placeholder: a silently missing icon is worse
  /// than a visible failure, because it looks like a layout bug.
  static MonetaIconName? tryParse(String figmaName) {
    for (final value in values) {
      if (value.figmaName == figmaName) return value;
    }
    return null;
  }
}
