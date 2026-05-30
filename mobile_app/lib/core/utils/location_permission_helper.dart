import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../localization/app_localizations.dart';

class LocationPermissionHelper {
  static const String _promptedKey = 'location_permission_prompted';

  /// Performs the startup location permission check.
  /// If permission is denied or undetermined, displays a beautiful permission prompt.
  static Future<void> checkAndRequestStartupLocation(
    BuildContext context, {
    VoidCallback? onPermissionGranted,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // We check the permission status
      LocationPermission status = await Geolocator.checkPermission();

      // If already granted, invoke the success callback and return
      if (status == LocationPermission.always || status == LocationPermission.whileInUse) {
        onPermissionGranted?.call();
        return;
      }

      // If we haven't prompted or status is denied, show the sheet
      if (context.mounted) {
        _showProfessionalLocationSheet(context, status, onPermissionGranted);
      }
    } catch (e) {
      debugPrint('Error in location check: $e');
    }
  }

  /// Shows the gorgeous, professional bottom sheet explaining the benefits of location access.
  static void _showProfessionalLocationSheet(
    BuildContext context,
    LocationPermission currentStatus,
    VoidCallback? onPermissionGranted,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.6),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (BuildContext sheetCtx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.only(
            top: 12,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 24),
              
              // Glowing location icon container
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFC8E6C9), width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2E7D32).withOpacity(0.12),
                      blurRadius: 24,
                      spreadRadius: 6,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Color(0xFF2E7D32),
                  size: 44,
                ),
              ),
              const SizedBox(height: 20),
              
              // Title
              const Text(
                'लोकेशन परवानगी आवश्यक',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Location Permission Required',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              
              // Feature list
              _buildFeatureItem(
                icon: Icons.cloudy_snowing,
                titleMr: 'अचूक हवामान अंदाज',
                titleEn: 'Accurate Weather',
                descMr: 'तुमच्या परिसरातील हवामान आणि फवारणीची माहिती मिळवा.',
                descEn: 'Get real-time weather and spray advisory for your village.',
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(
                icon: Icons.storefront,
                titleMr: 'जवळची खत दुकाने',
                titleEn: 'Nearby Shops',
                descMr: 'तुमच्या गावाजवळील अधिकृत कृषी दुकाने शोधा व संपर्क करा.',
                descEn: 'Discover and contact certified agri-shops near you.',
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(
                icon: Icons.campaign_outlined,
                titleMr: 'स्थानिक खरेदी-विक्री जाहिराती',
                titleEn: 'Local Marketplace',
                descMr: 'तुमच्या परिसरातील पशू, अवजारे व शेती साहित्य जाहिराती पहा.',
                descEn: 'Buy or sell livestock, equipment, and land near your area.',
              ),
              const SizedBox(height: 32),
              
              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      onPressed: () {
                        Navigator.pop(sheetCtx);
                      },
                      child: const Text(
                        'नंतर / Not Now',
                        style: TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () async {
                        Navigator.pop(sheetCtx);
                        if (currentStatus == LocationPermission.deniedForever) {
                          await Geolocator.openAppSettings();
                        } else {
                          LocationPermission permission = await Geolocator.requestPermission();
                          if (permission == LocationPermission.always ||
                              permission == LocationPermission.whileInUse) {
                            onPermissionGranted?.call();
                          }
                        }
                      },
                      child: Text(
                        currentStatus == LocationPermission.deniedForever
                            ? 'सेटिंग्ज / Settings'
                            : 'मंजूर करा / Allow',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildFeatureItem({
    required IconData icon,
    required String titleMr,
    required String titleEn,
    required String descMr,
    required String descEn,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF2E7D32), size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    titleMr,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '($titleEn)',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                descMr,
                style: TextStyle(
                  fontSize: 12.5,
                  color: Colors.grey[700],
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                descEn,
                style: TextStyle(
                  fontSize: 11.5,
                  color: Colors.grey[500],
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
