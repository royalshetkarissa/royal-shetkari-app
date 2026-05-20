import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/booking_provider.dart';
import '../widgets/animated_button.dart';

class BookCallScreen extends StatefulWidget {
  const BookCallScreen({super.key});

  @override
  State<BookCallScreen> createState() => _BookCallScreenState();
}

class _BookCallScreenState extends State<BookCallScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  String? _selectedTime;
  String _selectedHelpType = 'Farm help';
  bool _isSuccess = false;
  bool _isFlying = false;
  
  late AnimationController _successController;
  late AnimationController _flyController;
  late Animation<Offset> _flyAnimation;
  late Animation<double> _checkScale;
  late Animation<double> _opacityAnimation;

  final List<String> _helpOptions = ['Farm help', 'Market sell help', 'Your problem'];
  final List<String> _timeSlots = [
    '10:00:00', '11:00:00', '12:00:00', '13:00:00', 
    '14:00:00', '15:00:00', '16:00:00', '17:00:00'
  ];

  @override
  void initState() {
    super.initState();
    _successController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _checkScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: const Interval(0.4, 1.0, curve: Curves.elasticOut)),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: const Interval(0.0, 0.4, curve: Curves.easeIn)),
    );

    _flyController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _flyAnimation = Tween<Offset>(
      begin: const Offset(0, 0.8), // Start at button position
      end: const Offset(0, -0.8),  // End at expert header position
    ).animate(CurvedAnimation(parent: _flyController, curve: Curves.easeInOutBack));
  }

  @override
  void dispose() {
    _successController.dispose();
    _flyController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedTime = null;
      });
      final dateStr = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      Provider.of<BookingProvider>(context, listen: false).fetchBookedSlots(dateStr);
    }
  }

  void _showPreview() {
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select date and time first!')));
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildPreviewSheet(),
    );
  }

  Widget _buildPreviewSheet() {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          const Text('Confirm Booking', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          _buildPreviewRow(Icons.calendar_month, 'Date', "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}"),
          _buildPreviewRow(Icons.access_time_filled, 'Time', _selectedTime!.substring(0, 5)),
          _buildPreviewRow(Icons.help_center, 'Topic', _selectedHelpType),
          const SizedBox(height: 40),
          AnimatedButton(
            text: 'CONFIRM & BOOK',
            color: const Color(0xFF2E7D32),
            onPressed: () {
              Navigator.pop(context);
              _startBookingSequence();
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPreviewRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFF2E7D32).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: const Color(0xFF2E7D32), size: 20),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          )
        ],
      ),
    );
  }

  void _startBookingSequence() async {
    setState(() => _isFlying = true);
    await _flyController.forward();
    
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final booking = Provider.of<BookingProvider>(context, listen: false);

    try {
      final dateStr = "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}";
      await booking.bookCall(
        date: dateStr,
        time: _selectedTime!,
        helpType: _selectedHelpType,
        mobile: auth.user?['mobile'] ?? '',
      );

      setState(() { _isSuccess = true; _isFlying = false; });
      _successController.forward();
      Future.delayed(const Duration(seconds: 3), () => Navigator.pop(context));
    } catch (e) {
      setState(() => _isFlying = false);
      _flyController.reset();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = Provider.of<BookingProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Book Expert Call', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 32),
                _buildSelectionCard(
                  label: 'Choose Date',
                  icon: Icons.calendar_today,
                  value: _selectedDate == null ? 'Select Date' : "${_selectedDate!.day} ${_getMonth(_selectedDate!.month)}",
                  onTap: () => _selectDate(context),
                  isSelected: _selectedDate != null,
                ),
                const SizedBox(height: 32),
                if (_selectedDate != null) ...[
                  const Text('Available Slots', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 16),
                  _buildTimeGrid(booking),
                ],
                const SizedBox(height: 32),
                const Text('What help do you need?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 12),
                _buildHelpSelector(),
                const SizedBox(height: 60),
                booking.isLoading 
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32))) 
                  : AnimatedButton(text: 'BOOK NOW', color: const Color(0xFF2E7D32), onPressed: _showPreview),
              ],
            ),
          ),
          
          // ZEPTRO-STYLE FLYING ANIMATION
          if (_isFlying)
            Center(
              child: SlideTransition(
                position: _flyAnimation,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(color: Color(0xFFFF9800), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.orange, blurRadius: 10)]),
                  child: const Icon(Icons.phone_in_talk, color: Colors.white, size: 30),
                ),
              ),
            ),

          if (_isSuccess) _buildSuccessOverlay(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF43A047)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFF2E7D32).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 1.0, end: _isFlying ? 1.2 : 1.0),
            duration: const Duration(milliseconds: 300),
            builder: (context, value, child) => Transform.scale(scale: value, child: child),
            child: const CircleAvatar(radius: 30, backgroundColor: Colors.white24, child: Icon(Icons.support_agent, color: Colors.white, size: 30)),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Agricultural Expert', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                Text('Get professional advice for your farm', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSelectionCard({required String label, required IconData icon, required String value, required VoidCallback onTap, required bool isSelected}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2E7D32).withOpacity(0.05) : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? const Color(0xFF2E7D32) : Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF2E7D32) : Colors.grey),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isSelected ? Colors.black : Colors.grey)),
              ],
            ),
            const Spacer(),
            const Icon(Icons.keyboard_arrow_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeGrid(BookingProvider booking) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 2.2, crossAxisSpacing: 10, mainAxisSpacing: 10),
      itemCount: _timeSlots.length,
      itemBuilder: (context, i) {
        String time = _timeSlots[i];
        bool isBooked = booking.bookedSlots.contains(time);
        bool isSelected = _selectedTime == time;
        return InkWell(
          onTap: isBooked ? null : () => setState(() => _selectedTime = time),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF2E7D32) : (isBooked ? Colors.grey[100] : Colors.white),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? const Color(0xFF2E7D32) : Colors.grey[300]!),
            ),
            child: Text(time.substring(0, 5), style: TextStyle(color: isSelected ? Colors.white : (isBooked ? Colors.grey[400] : Colors.black))),
          ),
        );
      },
    );
  }

  Widget _buildHelpSelector() {
    return Wrap(
      spacing: 12,
      children: _helpOptions.map((opt) {
        bool isSel = _selectedHelpType == opt;
        return ChoiceChip(
          label: Text(opt),
          selected: isSel,
          onSelected: (s) => setState(() => _selectedHelpType = opt),
          selectedColor: const Color(0xFF2E7D32),
          labelStyle: TextStyle(color: isSel ? Colors.white : Colors.black),
          backgroundColor: Colors.grey[100],
        );
      }).toList(),
    );
  }

  Widget _buildSuccessOverlay() {
    return AnimatedBuilder(
      animation: _successController,
      builder: (context, child) => Container(
        color: Colors.black.withOpacity(0.85 * _opacityAnimation.value),
        child: Center(
          child: ScaleTransition(
            scale: _checkScale,
            child: Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 40, spreadRadius: 10)]),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 120),
                  SizedBox(height: 16),
                  Text('BOOKED!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF2E7D32), letterSpacing: 2)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getMonth(int m) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[m - 1];
  }
}
