import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../localization/app_localizations.dart';

class LocationPermissionHelper {
  static const String _promptedKey = 'location_permission_prompted';

  /// Performs the startup location permission check.
  /// If the prompt has never occurred, requests permission.
  /// If permission is denied, displays a dialog detailing benefits.
  static Future<void> checkAndRequestStartupLocation(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool alreadyPrompted = prefs.getBool(_promptedKey) ?? false;

      LocationPermission status = await Geolocator.checkPermission();

      if (!alreadyPrompted) {
        // Mark as prompted immediately to prevent repeat requests on restarts
        await prefs.setBool(_promptedKey, true);

        if (status == LocationPermission.denied) {
          status = await Geolocator.requestPermission();
        }

        if (status == LocationPermission.denied || status == LocationPermission.deniedForever) {
          if (context.mounted) {
            _showExplanationDialog(context);
          }
        }
      } else {
        // If already prompted but they somehow ended up with denied, 
        // we do not auto-prompt.
        if (status == LocationPermission.denied) {
          // No auto prompt.
        }
      }
    } catch (e) {
      debugPrint('Error in location check: $e');
    }
  }

  /// Shows the friendly dialog explaining the benefits of location access.
  static void _showExplanationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const Icon(Icons.location_on, color: Color(0xFF2E7D32), size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.translate('location_required'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
          content: Text(
            context.translate('location_explanation'),
            style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                context.translate('cancel'),
                style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onPressed: () async {
                Navigator.pop(dialogContext);
                await Geolocator.openAppSettings();
              },
              child: Text(
                context.translate('grant_permission'),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
}
