import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:royal_shetkari/widgets/shimmer_skeleton.dart';
import '../core/providers/auth_provider.dart';
import '../models/crop_model.dart';
import '../models/post_model.dart';
import '../services/api_service.dart';
import '../services/timetable_service.dart';
import '../localization/app_localizations.dart';
import 'post_detail_screen.dart';
import 'crop_timeline_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _api = ApiService();
  final TimetableService _timetableService = TimetableService();

  bool _isLoading = false;
  List<PostModel> _latestPosts = [];
  List<Map<String, dynamic>> _activeTasks = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();

      // 1. Fetch latest feed posts & filter within last 24 hours
      final postsData = await _api.getPosts(category: 'all');
      final parsedPosts =
          postsData.map((json) => PostModel.fromJson(json)).toList();
      _latestPosts = parsedPosts.where((post) {
        return now.difference(post.createdAt).inHours < 24;
      }).toList();

      // 2. Fetch user active crop journeys & extract tasks for today + tomorrow (next day)
      final activeJourneys = await _timetableService.getMyJourneys();
      List<Map<String, dynamic>> taskList = [];

      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      for (var journey in activeJourneys) {
        for (var task in journey.tasks) {
          final taskDate =
              DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);
          final bool isToday = taskDate.isAtSameMomentAs(today);
          final bool isTomorrow = taskDate.isAtSameMomentAs(tomorrow);

          if (isToday || isTomorrow) {
            taskList.add({
              'journey': journey,
              'task': task,
              'isToday': isToday,
            });
          }
        }
      }

      // Sort tasks: put today's tasks first, and uncompleted tasks first
      taskList.sort((a, b) {
        final CropTask taskA = a['task'];
        final CropTask taskB = b['task'];
        if (taskA.isCompleted != taskB.isCompleted) {
          return taskA.isCompleted ? 1 : -1;
        }
        final bool isTodayA = a['isToday'];
        final bool isTodayB = b['isToday'];
        if (isTodayA != isTodayB) {
          return isTodayA ? -1 : 1;
        }
        return taskA.dueDate.compareTo(taskB.dueDate);
      });

      setState(() {
        _activeTasks = taskList;
      });
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _completeTask(CropTask task, CropJourney journey) async {
    if (task.isCompleted) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate =
        DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);

    if (taskDate.isBefore(today)) {
      _showCoinAnimationDialog('past', task);
      return;
    }

    if (taskDate.isAfter(today.add(const Duration(days: 1)))) {
      _showCoinAnimationDialog('future', task);
      return;
    }

    setState(() => _isLoading = true);
    try {
      bool success = await _timetableService.completeTask(task.id);
      if (success) {
        if (mounted) {
          Provider.of<AuthProvider>(context, listen: false).refreshUser();
          _showCoinAnimationDialog('today', task);
          await _loadNotifications();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCoinAnimationDialog(String status, CropTask task) {
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
      backgroundColor: const Color(0xFFF9FBF9),
      appBar: AppBar(
        title: Text(
          context.translate('notifications'),
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amberAccent,
          indicatorWeight: 4,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          tabs: [
            Tab(
              icon: const Icon(Icons.playlist_add_check_circle_outlined),
              text: context.translate('farm_tasks_tab'),
            ),
            Tab(
              icon: const Icon(Icons.feed_outlined),
              text: context.translate('community_tab'),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: ShimmerSkeleton())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTasksTab(),
                _buildCommunityTab(),
              ],
            ),
    );
  }

  Widget _buildTasksTab() {
    if (_activeTasks.isEmpty) {
      return _buildEmptyState(
        context,
        icon: Icons.done_all_rounded,
        titleKey: 'no_tasks_today_tomorrow',
        descKey: 'no_tasks_today_tomorrow_desc',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      color: const Color(0xFF2E7D32),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        itemCount: _activeTasks.length,
        itemBuilder: (context, index) {
          final item = _activeTasks[index];
          final CropJourney journey = item['journey'];
          final CropTask task = item['task'];
          final bool isToday = item['isToday'];

          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: task.isCompleted
                    ? Colors.grey.shade200
                    : (isToday ? Colors.amber.shade200 : Colors.blue.shade200),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ExpansionTile(
              shape: const Border(),
              leading: GestureDetector(
                onTap: () => _completeTask(task, journey),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: task.isCompleted
                        ? Colors.green
                        : (isToday
                            ? Colors.amber.shade50
                            : Colors.blue.shade50),
                    border: Border.all(
                      color: task.isCompleted
                          ? Colors.green
                          : (isToday ? Colors.amber : Colors.blue),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    task.isCompleted ? Icons.check : Icons.agriculture,
                    size: 16,
                    color: task.isCompleted
                        ? Colors.white
                        : (isToday
                            ? Colors.amber.shade800
                            : Colors.blue.shade800),
                  ),
                ),
              ),
              title: Text(
                Localizations.localeOf(context).languageCode == 'mr'
                    ? task.nameMarathi
                    : task.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: task.isCompleted ? Colors.grey : Colors.black87,
                  decoration:
                      task.isCompleted ? TextDecoration.lineThrough : null,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6.0),
                key: ValueKey(task.id),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: journey.cropName.toLowerCase() == 'sugarcane' ||
                                journey.cropMarathi.contains('ऊस')
                            ? Colors.green.shade50
                            : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        context.translate(journey.cropName.toLowerCase(),
                            defaultValue: journey.cropMarathi),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color:
                              journey.cropName.toLowerCase() == 'sugarcane' ||
                                      journey.cropMarathi.contains('ऊस')
                                  ? Colors.green.shade800
                                  : Colors.orange.shade800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isToday
                            ? Colors.amber.shade50
                            : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isToday
                            ? context.translate('today')
                            : context.translate('tomorrow'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isToday
                              ? Colors.amber.shade800
                              : Colors.blue.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              childrenPadding: const EdgeInsets.all(16),
              children: [
                const Divider(height: 1),
                const SizedBox(height: 12),
                if (task.rationaleMarathi != null ||
                    task.rationaleEnglish != null) ...[
                  Container(
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
                            Icon(Icons.psychology,
                                color: Colors.blue.shade700, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              context.translate('expert_advice'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          Localizations.localeOf(context).languageCode == 'mr'
                              ? (task.rationaleMarathi ??
                                  task.rationaleEnglish ??
                                  '')
                              : (task.rationaleEnglish ??
                                  task.rationaleMarathi ??
                                  ''),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                _buildDoseRow(context.translate('organic_dose'),
                    task.organicDetails ?? 'N/A', Colors.green),
                const SizedBox(height: 10),
                _buildDoseRow(context.translate('chemical_dose'),
                    task.chemicalDetails ?? 'N/A', Colors.blueGrey),
                if (!task.isCompleted) ...[
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _completeTask(task, journey),
                    icon: const Icon(Icons.check_circle_outline,
                        size: 18, color: Colors.white),
                    label: Text(
                      context.translate('mark_completed_earn_coin'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDoseRow(String label, String details, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.bold, color: color),
              ),
              const SizedBox(height: 2),
              Text(
                details,
                style: const TextStyle(
                    fontSize: 13, color: Colors.black87, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCommunityTab() {
    if (_latestPosts.isEmpty) {
      return _buildEmptyState(
        context,
        icon: Icons.notifications_off_outlined,
        titleKey: 'no_posts_24h',
        descKey: 'no_posts_24h_desc',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      color: const Color(0xFF2E7D32),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _latestPosts.length,
        itemBuilder: (context, index) {
          final post = _latestPosts[index];
          final timeDifference = DateTime.now().difference(post.createdAt);
          String timeAgoString = '';
          if (timeDifference.inHours > 0) {
            timeAgoString = '${timeDifference.inHours} hrs ago';
          } else {
            timeAgoString = '${timeDifference.inMinutes} mins ago';
          }

          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => PostDetailScreen(post: post)),
            ),
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Row(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      color: Colors.grey.shade100,
                      child: post.imageUrl != null && post.imageUrl!.isNotEmpty
                          ? Image.network(post.imageUrl!, fit: BoxFit.cover)
                          : const Icon(Icons.image, color: Colors.grey),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2E7D32)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    post.category.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2E7D32),
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.access_time,
                                        size: 12, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      timeAgoString,
                                      style: const TextStyle(
                                          fontSize: 11, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              post.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              post.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required IconData icon,
    required String titleKey,
    required String descKey,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 64, color: const Color(0xFF2E7D32)),
            ),
            const SizedBox(height: 24),
            Text(
              context.translate(titleKey),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              context.translate(descKey),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
