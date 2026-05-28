import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../models/shop_model.dart';
import '../services/api_service.dart';
import '../localization/app_localizations.dart';
import '../core/providers/auth_provider.dart';

class ShopDetailsScreen extends StatefulWidget {
  final ShopModel shop;
  final String? categoryKey;

  const ShopDetailsScreen({super.key, required this.shop, this.categoryKey});

  @override
  State<ShopDetailsScreen> createState() => _ShopDetailsScreenState();
}

class _ShopDetailsScreenState extends State<ShopDetailsScreen> {
  final ApiService _api = ApiService();
  bool _isRedeeming = false;

  String _getPrefilledMessage(BuildContext context) {
    switch (widget.categoryKey?.toLowerCase()) {
      case 'fertilizers':
        return context.translate('whatsapp_msg_fertilizers');
      case 'crop':
        return context.translate('whatsapp_msg_crop');
      case 'equipment_repair':
        return context.translate('whatsapp_msg_repair');
      case 'hardware':
        return context.translate('whatsapp_msg_hardware');
      case 'organic_farming':
        return context.translate('whatsapp_msg_organic');
      default:
        return context.translate('whatsapp_msg_default');
    }
  }

  String _formatWhatsAppNumber(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10) {
      return '91$digits';
    }
    return digits;
  }

  Future<void> _launchWhatsApp(BuildContext context) async {
    final rawNumber = widget.shop.whatsappNumber ?? widget.shop.contactMobile;
    final number = _formatWhatsAppNumber(rawNumber);
    final message = Uri.encodeComponent(_getPrefilledMessage(context));
    final url = "whatsapp://send?phone=$number&text=$message";
    
    await _api.trackShopClick(widget.shop.id, 'whatsapp');
    
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      final webUrl = "https://wa.me/$number?text=$message";
      await launchUrl(Uri.parse(webUrl), mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchCall() async {
    final url = "tel:${widget.shop.contactMobile}";
    await _api.trackShopClick(widget.shop.id, 'call');
    await launchUrl(Uri.parse(url));
  }

  Future<void> _launchMap() async {
    final url = "https://www.google.com/maps/search/?api=1&query=${widget.shop.latitude},${widget.shop.longitude}";
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Future<void> _handleRedeem(BuildContext context, AuthProvider authProvider) async {
    final bool confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirm Redemption', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to redeem 50 coins for a 5% discount coupon at ${widget.shop.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('REDEEM', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    setState(() => _isRedeeming = true);
    try {
      final response = await _api.redeemShopCoins(widget.shop.id);
      await authProvider.refreshUser();
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: const [
                Icon(Icons.stars, color: Colors.amber, size: 28),
                SizedBox(width: 8),
                Text('Redeemed! 🎉', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Your 5% discount coupon has been claimed successfully.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amber.shade300, width: 1.5),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'SHOW CODE AT SHOP:',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber),
                      ),
                      const SizedBox(height: 6),
                      SelectableText(
                        response['claim']['claim_code'] ?? 'RS-CLAIM-CODE',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Note: Show this claim code to the merchant to redeem your 5% discount.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    minimumSize: const Size(120, 44),
                  ),
                  child: const Text('OKAY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to redeem: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRedeeming = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDeleted = widget.shop.status.toLowerCase() == 'deleted';
    final isInactive = widget.shop.status.toLowerCase() == 'inactive';
    final authProvider = Provider.of<AuthProvider>(context);
    final bool isLoggedIn = authProvider.isAuthenticated;
    final int userCoins = authProvider.user != null ? (authProvider.user!['coins'] ?? 0) : 0;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            leading: IconButton(
              key: const Key('btn_back_shop_details'),
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
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
                widget.shop.name,
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
                    _api.getImageUrl(widget.shop.profilePhoto),
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
                              ? context.translate('deleted_shop') 
                              : context.translate('inactive_shop'),
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
                    _buildMerchantCard(context),
                    const SizedBox(height: 20),

                    // Coin redemption panel
                    _buildCoinRedemptionCard(context, isLoggedIn, userCoins, authProvider),
                    const SizedBox(height: 24),
                    
                    // Services Section
                    _buildSectionHeader(context.translate('services_info')),
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
                        widget.shop.services != null && widget.shop.services!.isNotEmpty
                            ? widget.shop.services!
                            : context.translate('default_services_desc'),
                        style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Available categories
                    _buildSectionHeader(context.translate('shop_category')),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.shop.categories.map((cat) => _buildCategoryTag(cat)).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Contact & Pincode Card
                    _buildSectionHeader(context.translate('location_address')),
                    const SizedBox(height: 12),
                    _buildAddressCard(context),
                    const SizedBox(height: 24),

                    // Dynamic Product Slider (Gallery)
                    if (widget.shop.images.isNotEmpty) ...[
                      _buildSectionHeader(context.translate('product_gallery')),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 160,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: widget.shop.images.length,
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
                                  _api.getImageUrl(widget.shop.images[index]),
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
                label: Text(context.translate('call').toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
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
                onPressed: () => _launchWhatsApp(context),
                icon: const Icon(Icons.chat, color: Colors.white, size: 20),
                label: Text(context.translate('whatsapp').toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
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

  Widget _buildMerchantCard(BuildContext context) {
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
                  widget.shop.ownerName != null && widget.shop.ownerName!.isNotEmpty 
                      ? '${context.translate('owner')}: ${widget.shop.ownerName!}' 
                      : context.translate('merchant_partner'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.verified, color: Colors.green, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      context.translate('verified_merchant'),
                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11),
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

  Widget _buildCoinRedemptionCard(BuildContext context, bool isLoggedIn, int userCoins, AuthProvider authProvider) {
    if (!isLoggedIn) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: const [
            Icon(Icons.info_outline, color: Colors.grey),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Login to claim 5% coin discount offers!',
                style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    final bool canRedeem = userCoins >= 50;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.shade300, width: 1.5),
        gradient: LinearGradient(
          colors: [Colors.amber.shade50.withOpacity(0.3), Colors.white],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.amber.shade100,
                child: const Icon(Icons.card_membership, color: Colors.amber, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      '5% Coins Discount Offer',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Redeem 50 coins to claim 5% discount at this shop',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.stars, color: Colors.amber, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Your Balance: $userCoins Coins',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Colors.black87),
                  ),
                ],
              ),
              _isRedeeming
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1B5E20)),
                    )
                  : ElevatedButton(
                      onPressed: canRedeem ? () => _handleRedeem(context, authProvider) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B5E20),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        disabledForegroundColor: Colors.grey.shade500,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: Text(
                        canRedeem ? 'REDEEM' : 'NEED ${50 - userCoins} MORE',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(BuildContext context) {
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
          _buildAddressRow(Icons.location_city, context.translate('city_taluka'), widget.shop.city ?? 'Maharashtra'),
          const Divider(height: 20),
          _buildAddressRow(Icons.pin_drop, 'Pincode', widget.shop.pincode ?? '411001'),
          const Divider(height: 20),
          _buildAddressRow(Icons.map_outlined, context.translate('full_address'), widget.shop.address),
          const SizedBox(height: 16),
          // Google Map Redirect button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              key: const Key('btn_maps_redirect'),
              onPressed: _launchMap,
              icon: const Icon(Icons.directions, color: Color(0xFF1B5E20), size: 18),
              label: Text(context.translate('open_in_maps'), style: const TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold, fontSize: 12.5)),
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
