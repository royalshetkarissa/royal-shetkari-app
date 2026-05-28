import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/auth_provider.dart';
import '../models/crop_model.dart';
import '../services/timetable_service.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../localization/app_localizations.dart';

class CropTimelineScreen extends StatefulWidget {
  final CropJourney journey;
  const CropTimelineScreen({super.key, required this.journey});

  @override
  State<CropTimelineScreen> createState() => _CropTimelineScreenState();
}

class _CropTimelineScreenState extends State<CropTimelineScreen> {
  final TimetableService _service = TimetableService();
  bool _isProcessing = false;
  late List<CropTask> _tasks;

  @override
  void initState() {
    super.initState();
    _tasks = List.from(widget.journey.tasks);
  }

  Future<void> _toggleTask(CropTask task) async {
    if (task.isCompleted || _isProcessing) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate =
        DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);

    if (taskDate.isBefore(today)) {
      _showCreativeStatusDialog(status: 'past', task: task);
      return;
    }

    if (taskDate.isAfter(today)) {
      _showCreativeStatusDialog(status: 'future', task: task);
      return;
    }

    setState(() => _isProcessing = true);
    try {
      bool success = await _service.completeTask(task.id);
      if (success) {
        setState(() {
          int index = _tasks.indexWhere((t) => t.id == task.id);
          _tasks[index] = CropTask(
            id: task.id,
            name: task.name,
            nameMarathi: task.nameMarathi,
            dueDate: task.dueDate,
            isCompleted: true,
            coinAwarded: true,
            organicDetails: task.organicDetails,
            chemicalDetails: task.chemicalDetails,
            rationaleEnglish: task.rationaleEnglish,
            rationaleMarathi: task.rationaleMarathi,
            nutrientContent: task.nutrientContent,
          );
        });
        if (mounted) {
          Provider.of<AuthProvider>(context, listen: false).refreshUser();
          _showCreativeStatusDialog(status: 'today', task: task);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showCreativeStatusDialog(
      {required String status, required CropTask task}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) =>
          CreativeCoinStatusDialog(status: status, task: task),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
            context.translate(widget.journey.cropName.toLowerCase(),
                defaultValue: widget.journey.cropMarathi),
            style: const TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _tasks.isEmpty
                ? Center(child: Text(context.translate('no_tasks_scheduled')))
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _tasks.length,
                    itemBuilder: (context, index) {
                      final task = _tasks[index];
                      final isLast = index == _tasks.length - 1;
                      return _buildTimelineItem(task, isLast);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final daysSincePlanting =
        DateTime.now().difference(widget.journey.plantingDate).inDays;
    final minDays = widget.journey.harvestDaysMin ?? 60;
    final maxDays = widget.journey.harvestDaysMax ?? 90;

    // Calculate progress based on completed tasks
    final completedTasks = _tasks.where((t) => t.isCompleted).length;
    final totalTasks = _tasks.length;
    final taskProgress = totalTasks > 0 ? completedTasks / totalTasks : 0.0;

    // Time progress (secondary fallback)
    final timeProgress = (daysSincePlanting / minDays).clamp(0.0, 1.0);

    // Use the higher of the two or a weighted average? User usually prefers task completion.
    final displayProgress = taskProgress;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(35), bottomRight: Radius.circular(35)),
        boxShadow: [
          BoxShadow(
              color: Colors.green.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.translate('growth_progress'),
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(
                    '${context.translate('day')} $daysSincePlanting ($completedTasks/$totalTasks ${context.translate('tasks')})',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(
                  '${(displayProgress * 100).toInt()}%',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: displayProgress,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.timer_outlined, color: Colors.white70, size: 16),
              const SizedBox(width: 8),
              Text(
                '${context.translate('cycle')}: $minDays-$maxDays ${context.translate('days')}',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const Spacer(),
              Text(
                '${context.translate('harvest_est')}: ${DateFormat('dd MMM').format(widget.journey.plantingDate.add(Duration(days: minDays)))}',
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(CropTask task, bool isLast) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate =
        DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);

    final bool isPast = taskDate.isBefore(today);
    final bool isToday = taskDate.isAtSameMomentAs(today);
    final bool isFuture = taskDate.isAfter(today);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: task.isCompleted
                      ? Colors.green
                      : (isToday ? Colors.blue : Colors.grey.shade300),
                  boxShadow: [
                    if (isToday)
                      BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 2)
                  ],
                ),
                child: Icon(
                  task.isCompleted ? Icons.check : Icons.agriculture,
                  size: 16,
                  color: Colors.white,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: Colors.grey.shade200,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: isToday
                          ? Colors.blue.shade100
                          : Colors.grey.shade100),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  Localizations.localeOf(context)
                                              .languageCode ==
                                          'mr'
                                      ? task.nameMarathi
                                      : task.name,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: task.isCompleted
                                        ? Colors.grey
                                        : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.event,
                                        size: 14, color: Colors.grey.shade400),
                                    const SizedBox(width: 4),
                                    Text(
                                      DateFormat('dd MMM yyyy')
                                          .format(task.dueDate),
                                      style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 13),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (task.isCompleted)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(8)),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.check_circle_outline,
                                            size: 12, color: Colors.green),
                                        const SizedBox(width: 4),
                                        Text(context.translate('completed'),
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.green.shade800,
                                                fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  )
                                else if (isToday)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(colors: [
                                        Colors.amber,
                                        Colors.orangeAccent
                                      ]),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.stars,
                                            size: 12, color: Colors.white),
                                        const SizedBox(width: 4),
                                        Text(
                                            context
                                                .translate('earn_coin_today'),
                                            style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  )
                                else if (isPast)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(8)),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.warning_amber,
                                            size: 12,
                                            color: Colors.red.shade600),
                                        const SizedBox(width: 4),
                                        Text(
                                            context.translate(
                                                'date_passed_no_coins'),
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.red.shade800,
                                                fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                        color: Colors.indigo.shade50,
                                        borderRadius: BorderRadius.circular(8)),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.calendar_month,
                                            size: 12,
                                            color: Colors.indigo.shade600),
                                        const SizedBox(width: 4),
                                        Text(context.translate('upcoming_task'),
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.indigo.shade800,
                                                fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  )
                              ],
                            ),
                          ),
                          if (!task.isCompleted)
                            Transform.scale(
                              scale: 1.2,
                              child: Checkbox(
                                value: task.isCompleted,
                                onChanged: (val) => _toggleTask(task),
                                activeColor: Colors.green,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6)),
                              ),
                            )
                          else
                            const Icon(Icons.stars,
                                color: Colors.amber, size: 30),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(20),
                            bottomRight: Radius.circular(20)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (task.rationaleMarathi != null ||
                              task.rationaleEnglish != null)
                            _buildExpertInsight(task),
                          const SizedBox(height: 16),
                          _buildDoseType(context.translate('organic'),
                              task.organicDetails ?? 'N/A', Colors.green),
                          const SizedBox(height: 12),
                          _buildDoseType(context.translate('chemical'),
                              task.chemicalDetails ?? 'N/A', Colors.blueGrey),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpertInsight(CropTask task) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, color: Colors.blue.shade700, size: 18),
              const SizedBox(width: 8),
              Text(
                context.translate('expert_insight'),
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                    letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            Localizations.localeOf(context).languageCode == 'mr'
                ? (task.rationaleMarathi ?? task.rationaleEnglish ?? '')
                : (task.rationaleEnglish ?? task.rationaleMarathi ?? ''),
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87),
          ),
          if (task.nutrientContent != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Text('${context.translate('content')}: ',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900)),
                Expanded(
                  child: Text(
                    task.nutrientContent!,
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade900,
                        fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDoseType(String label, String details, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Text(
            details,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ),
      ],
    );
  }
}

// ----------------------------------------------------
// 🌟 CREATIVE ANIMATED DIALOG FOR COIN STATUS VALIDATION
// ----------------------------------------------------
class CreativeCoinStatusDialog extends StatefulWidget {
  final String status;
  final CropTask task;

  const CreativeCoinStatusDialog({
    super.key,
    required this.status,
    required this.task,
  });

  @override
  State<CreativeCoinStatusDialog> createState() =>
      _CreativeCoinStatusDialogState();
}

class _CreativeCoinStatusDialogState extends State<CreativeCoinStatusDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _growthAnimation;
  late Animation<double> _coinSpinAnimation;
  late Animation<double> _burstAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.bounceOut),
      ),
    );

    _growthAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.7, curve: Curves.elasticOut),
      ),
    );

    _coinSpinAnimation = Tween<double>(begin: -150.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 0.9, curve: Curves.bounceOut),
      ),
    );

    _burstAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.8, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color primaryColor;
    String titleKey;
    String descKey;
    String buttonTextKey;
    List<Color> gradientColors;

    if (widget.status == 'today') {
      primaryColor = const Color(0xFFFFB300);
      titleKey = 'congrats_coin';
      descKey = 'congrats_coin_desc';
      buttonTextKey = 'awesome';
      gradientColors = [const Color(0xFFFF8F00), const Color(0xFFFFC107)];
    } else if (widget.status == 'past') {
      primaryColor = const Color(0xFFE53935);
      titleKey = 'date_passed_title';
      descKey = 'date_passed_desc';
      buttonTextKey = 'ok';
      gradientColors = [const Color(0xFFD32F2F), const Color(0xFFEF5350)];
    } else {
      primaryColor = const Color(0xFF3F51B5);
      titleKey = 'upcoming_task_title';
      descKey = 'upcoming_task_desc';
      buttonTextKey = 'wait';
      gradientColors = [const Color(0xFF303F9F), const Color(0xFF5C6BC0)];
    }

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 16,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: widget.status == 'today'
                      ? const Color(0xFFE8F5E9)
                      : (widget.status == 'past'
                          ? const Color(0xFFFFEBEE)
                          : const Color(0xFFE8EAF6)),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.15),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (widget.status == 'today') ...[
                        AnimatedBuilder(
                          animation: _growthAnimation,
                          builder: (context, child) {
                            return CustomPaint(
                              size: const Size(120, 120),
                              painter: SproutPainter(_growthAnimation.value),
                            );
                          },
                        ),
                        AnimatedBuilder(
                          animation: _coinSpinAnimation,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, _coinSpinAnimation.value),
                              child: Transform.rotate(
                                angle: _controller.value * 4 * math.pi,
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: const BoxDecoration(
                                    color: Colors.amber,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 5,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.monetization_on,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        AnimatedBuilder(
                          animation: _burstAnimation,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _burstAnimation.value,
                              child: CustomPaint(
                                size: const Size(160, 160),
                                painter: SparklePainter(_burstAnimation.value),
                              ),
                            );
                          },
                        ),
                      ],
                      if (widget.status == 'past') ...[
                        AnimatedBuilder(
                          animation: _controller,
                          builder: (context, child) {
                            return CustomPaint(
                              size: const Size(100, 100),
                              painter: WitheredLeafPainter(_controller.value),
                            );
                          },
                        ),
                        const Positioned(
                          top: 25,
                          right: 25,
                          child: Icon(Icons.cancel,
                              color: Colors.redAccent, size: 24),
                        ),
                      ],
                      if (widget.status == 'future') ...[
                        AnimatedBuilder(
                          animation: _controller,
                          builder: (context, child) {
                            return CustomPaint(
                              size: const Size(110, 110),
                              painter: SleepingSeedPainter(_controller.value),
                            );
                          },
                        ),
                        AnimatedBuilder(
                          animation: _controller,
                          builder: (context, child) {
                            final float =
                                math.sin(_controller.value * math.pi * 2) * 6;
                            return Transform.translate(
                              offset: Offset(float, -35),
                              child: Icon(
                                Icons.cloud,
                                color: Colors.blue.shade300,
                                size: 40,
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                context.translate(titleKey),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                context.translate(descKey),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                  child: Text(
                    context.translate(buttonTextKey),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// 🌿 CUSTOM PAINTERS FOR LUXURIOUS MICRO-ANIMATIONS
// ----------------------------------------------------
class SproutPainter extends CustomPainter {
  final double growth;

  SproutPainter(this.growth);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8B5A2B) // Soil brown
      ..style = PaintingStyle.fill;

    final soilPath = Path()
      ..moveTo(0, size.height)
      ..quadraticBezierTo(
          size.width / 2, size.height - 20, size.width, size.height)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(soilPath, paint);

    if (growth <= 0) return;

    paint.color = const Color(0xFF4CAF50); // Stem green
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 4;
    paint.strokeCap = StrokeCap.round;

    final stemPath = Path()..moveTo(size.width / 2, size.height - 10);
    final currentHeight = (size.height - 40) * growth;
    stemPath.quadraticBezierTo(
      size.width / 2 - 10 * growth,
      size.height - 10 - currentHeight / 2,
      size.width / 2,
      size.height - 10 - currentHeight,
    );
    canvas.drawPath(stemPath, paint);

    if (growth > 0.4) {
      paint.style = PaintingStyle.fill;
      final leafGrowth = (growth - 0.4) / 0.6;

      final leftLeafPath = Path()
        ..moveTo(size.width / 2, size.height - 10 - (size.height - 40) * 0.6)
        ..quadraticBezierTo(
          size.width / 2 - 20 * leafGrowth,
          size.height - 10 - (size.height - 40) * 0.7,
          size.width / 2 - 25 * leafGrowth,
          size.height - 10 - (size.height - 40) * 0.6,
        )
        ..quadraticBezierTo(
          size.width / 2 - 10 * leafGrowth,
          size.height - 10 - (size.height - 40) * 0.5,
          size.width / 2,
          size.height - 10 - (size.height - 40) * 0.6,
        );
      canvas.drawPath(leftLeafPath, paint);

      final rightLeafPath = Path()
        ..moveTo(size.width / 2, size.height - 10 - (size.height - 40) * 0.7)
        ..quadraticBezierTo(
          size.width / 2 + 20 * leafGrowth,
          size.height - 10 - (size.height - 40) * 0.8,
          size.width / 2 + 25 * leafGrowth,
          size.height - 10 - (size.height - 40) * 0.7,
        )
        ..quadraticBezierTo(
          size.width / 2 + 10 * leafGrowth,
          size.height - 10 - (size.height - 40) * 0.6,
          size.width / 2,
          size.height - 10 - (size.height - 40) * 0.7,
        );
      canvas.drawPath(rightLeafPath, paint);
    }
  }

  @override
  bool shouldRepaint(covariant SproutPainter oldDelegate) {
    return oldDelegate.growth != growth;
  }
}

class WitheredLeafPainter extends CustomPainter {
  final double progress;

  WitheredLeafPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD84315) // Orange-brown withered
      ..style = PaintingStyle.fill;

    final leafCenter = Offset(size.width / 2, size.height / 2);
    canvas.save();

    final double angle = math.sin(progress * math.pi * 6) * 0.15;
    canvas.translate(leafCenter.dx, leafCenter.dy);
    canvas.rotate(angle);
    canvas.translate(-leafCenter.dx, -leafCenter.dy);

    final leafPath = Path()
      ..moveTo(size.width / 2 - 30, size.height / 2 + 10)
      ..quadraticBezierTo(size.width / 2 - 10, size.height / 2 - 20,
          size.width / 2 + 30, size.height / 2 - 10)
      ..quadraticBezierTo(size.width / 2 + 10, size.height / 2 + 20,
          size.width / 2 - 30, size.height / 2 + 10)
      ..close();
    canvas.drawPath(leafPath, paint);

    paint.color = const Color(0xFF5D4037);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 3;
    canvas.drawLine(
      Offset(size.width / 2 - 38, size.height / 2 + 15),
      Offset(size.width / 2 - 25, size.height / 2 + 8),
      paint,
    );

    paint.color = const Color(0xFFBF360C);
    paint.strokeWidth = 1.5;
    canvas.drawLine(
      Offset(size.width / 2 - 25, size.height / 2 + 8),
      Offset(size.width / 2 + 25, size.height / 2 - 8),
      paint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant WitheredLeafPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class SleepingSeedPainter extends CustomPainter {
  final double progress;

  SleepingSeedPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8B5A2B) // Soil
      ..style = PaintingStyle.fill;

    final soilPath = Path()
      ..moveTo(0, size.height)
      ..quadraticBezierTo(
          size.width / 2, size.height - 15, size.width, size.height)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(soilPath, paint);

    paint.color = const Color(0xFFD7CCC8); // Seed coat
    final seedCenter = Offset(size.width / 2,
        size.height - 25 + math.sin(progress * math.pi * 2) * 2);
    canvas.drawOval(
      Rect.fromCenter(center: seedCenter, width: 22, height: 14),
      paint,
    );

    paint.color = const Color(0xFF5D4037);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1.5;

    canvas.drawArc(
      Rect.fromCenter(
          center: Offset(seedCenter.dx - 4, seedCenter.dy - 1),
          width: 5,
          height: 4),
      0,
      math.pi,
      false,
      paint,
    );

    canvas.drawArc(
      Rect.fromCenter(
          center: Offset(seedCenter.dx + 4, seedCenter.dy - 1),
          width: 5,
          height: 4),
      0,
      math.pi,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant SleepingSeedPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class SparklePainter extends CustomPainter {
  final double progress;

  SparklePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFD54F)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final double radius = 40 + progress * 35;

    for (int i = 0; i < 8; i++) {
      final double angle = i * math.pi / 4;
      final sparklePos = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      final double sizeVal = 6 * (1.0 - progress);
      canvas.drawCircle(sparklePos, sizeVal, paint);
    }
  }

  @override
  bool shouldRepaint(covariant SparklePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
