import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/shop_model.dart';
import '../services/api_service.dart';

class ShopDetailsScreen extends StatelessWidget {
  final ShopModel shop;
  final String? categoryKey;
  final ApiService _api = ApiService();

  ShopDetailsScreen({super.key, required this.shop, this.categoryKey});

  String _getPrefilledMessage() {
    switch (categoryKey?.toLowerCase()) {
      case 'fertilizers':
        return "नमस्कार, मी रॉयल शेतकरी ॲपवरून आपल्या दुकानाची माहिती पाहिली. मला खते आणि बियाणे खरेदी करायचे आहेत, कृपया माहिती द्या.\n\nI saw your shop on Royal Shetkari. I want to buy fertilizers & seeds, please share details.";
      case 'crop':
        return "नमस्कार, मी रॉयल शेतकरी ॲपवरून आपल्या दुकानाची माहिती पाहिली. मला धान्य व पीक खरेदी/विक्री संदर्भात चर्चा करायची आहे.\n\nI saw your profile on Royal Shetkari. I want to discuss crop buying/selling.";
      case 'equipment_repair':
        return "नमस्कार, मी रॉयल शेतकरी ॲपवरून आपल्या दुरुस्ती केंद्राची माहिती पाहिली. मला माझ्या शेती अवजारांच्या दुरुस्तीची सेवा हवी आहे.\n\nI saw your service on Royal Shetkari. I want farming equipment repairing service.";
      case 'hardware':
        return "नमस्कार, मी रॉयल शेतकरी ॲपवरून आपल्या हार्डवेअर दुकानाची माहिती पाहिली. मला कृषी हार्डवेअर साहित्य खरेदी करायचे आहे.\n\nI saw your shop on Royal Shetkari. I want to buy agricultural hardware supplies.";
      case 'organic_farming':
        return "नमस्कार, मी रॉयल शेतकरी ॲपवरून आपल्या सेंद्रिय केंद्राची माहिती पाहिली. मला सेंद्रिय शेती साहित्य खरेदी करायचे आहे.\n\nI saw your shop on Royal Shetkari. I want to buy organic farming inputs.";
      default:
        return "नमस्कार, मी रॉयल शेतकरी ॲपवरून आपल्या दुकानाची माहिती पाहिली. मला आपल्या दुकानाच्या सेवांबद्दल माहिती हवी आहे.\n\nI saw your profile on Royal Shetkari. I want more information about your services.";
    }
  }

  String _formatWhatsAppNumber(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10) {
      return '91$digits';
    }
    return digits;
  }

  Future<void> _launchWhatsApp() async {
    final rawNumber = shop.whatsappNumber ?? shop.contactMobile;
    final number = _formatWhatsAppNumber(rawNumber);
    final message = Uri.encodeComponent(_getPrefilledMessage());
    final url = "whatsapp://send?phone=$number&text=$message";
    
    await _api.trackShopClick(shop.id, 'whatsapp');
    
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      final webUrl = "https://wa.me/$number?text=$message";
      await launchUrl(Uri.parse(webUrl), mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchCall() async {
    final url = "tel:${shop.contactMobile}";
    await _api.trackShopClick(shop.id, 'call');
    await launchUrl(Uri.parse(url));
  }

  Future<void> _launchMap() async {
    final url = "https://www.google.com/maps/search/?api=1&query=${shop.latitude},${shop.longitude}";
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final isDeleted = shop.status.toLowerCase() == 'deleted';
    final isInactive = shop.status.toLowerCase() == 'inactive';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            leading: IconButton(
              key: const Key('btn_back_shop_details'),
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            expandedHeight: 280,
            pinned: true,
            backgroundColor: const Color(0xFF1B5E20),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                shop.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 16,
                  shadows: [
                    Shadow(blurRadius: 10, color: Colors.black54, offset: Offset(0, 2))
                  ],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    _api.getImageUrl(shop.profilePhoto),
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.green.shade50,
                        alignment: Alignment.center,
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                              : null,
                          color: const Color(0xFF1B5E20),
                        ),
                      );
                    },
                    errorBuilder: (c, e, s) => Container(
                      color: Colors.green.shade50,
                      child: const Icon(Icons.store, size: 80, color: Color(0xFF1B5E20)),
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black38, Colors.transparent, Colors.black87],
                        stops: [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              if (isDeleted || isInactive)
                Container(
                  color: Colors.red.shade100,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isDeleted 
                              ? 'हे दुकान काढण्यात आले आहे (Deleted Shop)' 
                              : 'हे दुकान सध्या निष्क्रिय आहे (Inactive Shop)',
                          style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Owner & Verification Banner
                    _buildMerchantCard(),
                    const SizedBox(height: 24),
                    
                    // Services Section
                    _buildSectionHeader('सेवा आणि माहिती / Services Info'),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Text(
                        shop.services != null && shop.services!.isNotEmpty
                            ? shop.services!
                            : 'सर्व प्रकारच्या दर्जेदार सेवा व साहित्य उपलब्ध.\nQuality service and products available.',
                        style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Available categories
                    _buildSectionHeader('वर्गीकरण / Shop Category'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: shop.categories.map((cat) => _buildCategoryTag(cat)).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Contact & Pincode Card
                    _buildSectionHeader('पत्ता आणि संपर्क / Location & Address'),
                    const SizedBox(height: 12),
                    _buildAddressCard(),
                    const SizedBox(height: 24),

                    // Dynamic Product Slider (Gallery)
                    if (shop.images.isNotEmpty) ...[
                      _buildSectionHeader('उत्पादन गॅलरी / Product Gallery'),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 160,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: shop.images.length,
                          itemBuilder: (context, index) {
                            return Container(
                              width: 220,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  )
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: Image.network(
                                  _api.getImageUrl(shop.images[index]),
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      color: Colors.grey[100],
                                      alignment: Alignment.center,
                                      child: CircularProgressIndicator(
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                            : null,
                                        color: const Color(0xFF1B5E20),
                                      ),
                                    );
                                  },
                                  errorBuilder: (c, e, s) => Container(
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.broken_image, color: Colors.grey),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 120),
                    ],
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, spreadRadius: 3, offset: const Offset(0, -2))
          ],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                key: const Key('btn_call_merchant'),
                onPressed: _launchCall,
                icon: const Icon(Icons.call, color: Colors.white, size: 20),
                label: const Text('कॉल करा / CALL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  minimumSize: const Size(0, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                key: const Key('btn_whatsapp_merchant'),
                onPressed: _launchWhatsApp,
                icon: const Icon(Icons.chat, color: Colors.white, size: 20),
                label: const Text('व्हॉट्सॲप / WHATSAPP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal[600],
                  minimumSize: const Size(0, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
    );
  }

  Widget _buildMerchantCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.shade200, width: 1.5),
        gradient: LinearGradient(
          colors: [Colors.amber.shade50.withOpacity(0.4), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.amber.shade100,
            child: const Icon(Icons.person, color: Colors.amber, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shop.ownerName != null && shop.ownerName!.isNotEmpty 
                      ? 'मालक: ${shop.ownerName!}' 
                      : 'नोंदणीकृत व्यावसायिक / Merchant Partner',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 4),
                Row(
                  children: const [
                    Icon(Icons.verified, color: Colors.green, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'व्हेरिफाइड शेतकरी व्यावसायिक',
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAddressRow(Icons.location_city, 'शहर / तालुका', shop.city ?? 'Maharashtra'),
          const Divider(height: 20),
          _buildAddressRow(Icons.pin_drop, 'पिनकोड / Pincode', shop.pincode ?? '411001'),
          const Divider(height: 20),
          _buildAddressRow(Icons.map_outlined, 'पत्ता / Full Address', shop.address),
          const SizedBox(height: 16),
          // Google Map Redirect button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              key: const Key('btn_maps_redirect'),
              onPressed: _launchMap,
              icon: const Icon(Icons.directions, color: Color(0xFF1B5E20), size: 18),
              label: const Text('नकाशात पहा / Open in Maps', style: TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold, fontSize: 12.5)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF1B5E20), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF1B5E20), size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        border: Border.all(color: Colors.green.shade200),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}
