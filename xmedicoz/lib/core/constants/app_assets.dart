/// Centralized Asset Constants for 100% DRY asset path management across the app.
/// Usage: AppAssets.appIcon, AppAssets.appIconMinimal (just like AppColors)
class AppAssets {
  // Base Path
  static const String _iconsDir = 'assets/icons';

  // Branded App Icons Matching the Theme
  static const String appIcon = '$_iconsDir/app_icon.png';
  static const String appIcon3d = '$_iconsDir/app_icon.png';
  static const String appIconMinimal = '$_iconsDir/app_icon_minimal.png';
  static const String appIcon3dJpg = '$_iconsDir/app_icon_3d.jpg';
}
