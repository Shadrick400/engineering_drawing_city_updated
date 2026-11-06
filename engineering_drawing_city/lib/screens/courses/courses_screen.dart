import 'package:flutter/material.dart';

import 'package:engineering_drawing_city/models/book_model.dart';
import 'package:engineering_drawing_city/models/course_model.dart';
import 'package:engineering_drawing_city/models/past_paper_model.dart';
import 'package:engineering_drawing_city/models/video_model.dart';
import 'package:engineering_drawing_city/services/firebase_service.dart';
import 'package:engineering_drawing_city/theme/app_theme.dart';

import 'package:engineering_drawing_city/widgets/in_app_document_viewer.dart';

int _academicNumber(String value) {
  final match = RegExp(r'\d+').firstMatch(value);
  return int.tryParse(match?.group(0) ?? '') ?? 0;
}

int _compareCourseIds(FirestoreService service, String leftId, String rightId) {
  final courses = service.getCoursesSync();
  final leftIndex = courses.indexWhere((course) => course.id == leftId);
  final rightIndex = courses.indexWhere((course) => course.id == rightId);
  if (leftIndex < 0 || rightIndex < 0) return leftId.compareTo(rightId);
  final left = courses[leftIndex];
  final right = courses[rightIndex];
  final programmeOrder = left.programme.compareTo(right.programme);
  if (programmeOrder != 0) return programmeOrder;
  final yearOrder = _academicNumber(left.year).compareTo(_academicNumber(right.year));
  if (yearOrder != 0) return yearOrder;
  final semesterOrder = _academicNumber(left.semester).compareTo(_academicNumber(right.semester));
  if (semesterOrder != 0) return semesterOrder;
  final order = left.order.compareTo(right.order);
  return order != 0 ? order : left.title.compareTo(right.title);
}

String _courseLabelFor(FirestoreService service, String courseId) {
  final matches = service.getCoursesSync().where((course) => course.id == courseId);
  if (matches.isEmpty) return 'Course not assigned';
  final course = matches.first;
  final parts = [
    course.programme,
    course.year,
    course.semester,
    course.title,
  ].where((part) => part.trim().isNotEmpty).toList();
  return parts.join(' • ');
}

class CoursesScreen extends StatefulWidget {
  static const String routeName = '/courses';
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen>
    with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text('Courses & Resources'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/home');
            }
          },
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.accentCyan,
          unselectedLabelColor: Colors.white60,
          indicatorColor: AppTheme.accentCyan,
          indicatorWeight: 3,
          tabs: const [
            Tab(
              icon: Icon(Icons.ondemand_video, size: 20),
              text: 'Videos',
            ),
            Tab(
              icon: Icon(Icons.menu_book, size: 20),
              text: 'Books',
            ),
            Tab(
              icon: Icon(Icons.assignment, size: 20),
              text: 'Past Papers',
            ),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 950),
          child: Column(
            children: [
              // Search bar
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search videos, books, past papers...',
                    prefixIcon: const Icon(Icons.search, color: AppTheme.primaryBlue),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () =>
                                setState(() => _searchQuery = ''),
                          )
                        : null,
                  ),
                  onChanged: (val) =>
                      setState(() => _searchQuery = val.trim().toLowerCase()),
                ),
              ),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _VideosTab(
                      firestoreService: _firestoreService,
                      searchQuery: _searchQuery,
                    ),
                    _BooksTab(
                      firestoreService: _firestoreService,
                      searchQuery: _searchQuery,
                      userId: _authService.currentUser?.uid,
                      isAdmin: _authService.isAdmin,
                    ),
                    _PastPapersTab(
                      firestoreService: _firestoreService,
                      searchQuery: _searchQuery,
                      userId: _authService.currentUser?.uid,
                      isAdmin: _authService.isAdmin,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LockedMaterialsNotice extends StatelessWidget {
  final String title;
  final String message;

  const _LockedMaterialsNotice({
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 54, color: AppTheme.primaryBlue),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkNavy),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(message, style: const TextStyle(color: AppTheme.textMuted), textAlign: TextAlign.center),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/profile'),
              icon: const Icon(Icons.workspace_premium),
              label: const Text('View Subscription'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────── VIDEOS TAB ───────────────────
class _VideosTab extends StatefulWidget {
  final FirestoreService firestoreService;
  final String searchQuery;

  const _VideosTab({
    required this.firestoreService,
    required this.searchQuery,
  });

  @override
  State<_VideosTab> createState() => _VideosTabState();
}

class _VideosTabState extends State<_VideosTab> {
  String? _selectedCourseId;

  Widget _courseTag(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.primaryBlue),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.primaryBlue)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CourseModel>>(
      stream: widget.firestoreService.getCourses(),
      builder: (context, snapshot) {
        final allCourses = snapshot.data ?? widget.firestoreService.getCoursesSync();
        final filtered = allCourses.where((c) {
          if (widget.searchQuery.isEmpty) return true;
          return c.title.toLowerCase().contains(widget.searchQuery) ||
              c.description.toLowerCase().contains(widget.searchQuery) ||
              c.programme.toLowerCase().contains(widget.searchQuery) ||
              c.year.toLowerCase().contains(widget.searchQuery) ||
              c.semester.toLowerCase().contains(widget.searchQuery);
        }).toList()
          ..sort((a, b) {
            final programmeOrder = a.programme.compareTo(b.programme);
            if (programmeOrder != 0) return programmeOrder;
            final yearOrder = _academicNumber(a.year).compareTo(_academicNumber(b.year));
            if (yearOrder != 0) return yearOrder;
            final semesterOrder = _academicNumber(a.semester).compareTo(_academicNumber(b.semester));
            if (semesterOrder != 0) return semesterOrder;
            return a.order.compareTo(b.order);
          });

        if (filtered.isEmpty) {
          return const Center(
            child: Text(
              'No courses matched your search',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 16),
            ),
          );
        }

        return StreamBuilder<List<VideoModel>>(
          stream: widget.firestoreService.getVideos(),
          builder: (context, videoSnapshot) {
            final allVideos =
                videoSnapshot.data ?? widget.firestoreService.getVideosSync();

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final course = filtered[index];
                final videos = allVideos
                    .where((video) =>
                        video.courseId == course.id &&
                        video.isPublished &&
                        video.youtubeVideoId.trim().isNotEmpty)
                    .toList()
                  ..sort((a, b) => a.order.compareTo(b.order));
                final isExpanded = _selectedCourseId == course.id;

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isExpanded ? AppTheme.primaryBlue : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      setState(() {
                        _selectedCourseId = isExpanded ? null : course.id;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Text(
                                '0${course.order}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryBlue,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  course.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.darkNavy,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  course.description,
                                  style: const TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 13,
                                    height: 1.35,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    if (course.programme.isNotEmpty)
                                      _courseTag(Icons.school, course.programme),
                                    if (course.year.isNotEmpty)
                                      _courseTag(Icons.calendar_today, course.year),
                                    if (course.semester.isNotEmpty)
                                      _courseTag(Icons.date_range, course.semester),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Icon(Icons.play_circle_outline,
                                        size: 16, color: AppTheme.primaryBlue),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        '${videos.length} Video Lessons',
                                        style: const TextStyle(
                                          color: AppTheme.primaryBlue,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isExpanded ? 'Hide' : 'View Lessons',
                                      style: const TextStyle(
                                        color: AppTheme.primaryBlue,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Icon(
                                      isExpanded
                                          ? Icons.keyboard_arrow_up
                                          : Icons.keyboard_arrow_down,
                                      color: AppTheme.primaryBlue,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (isExpanded)
                    Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(16),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4.0),
                            child: Text(
                              'CURRICULUM LESSONS:',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textMuted,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (videos.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: Text('No lessons uploaded yet for this course.'),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: videos.length,
                              separatorBuilder: (c, i) => const Divider(height: 12),
                              itemBuilder: (ctx, vIndex) {
                                final video = videos[vIndex];
                                return ListTile(
                                  contentPadding:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: SizedBox(
                                      width: 56,
                                      height: 44,
                                      child: video.thumbnailUrl.trim().isNotEmpty
                                          ? Image.network(
                                              video.thumbnailUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) =>
                                                  Container(
                                                color: AppTheme.primaryBlue,
                                                child: const Icon(Icons.play_arrow, color: Colors.white),
                                              ),
                                            )
                                          : Container(
                                              color: AppTheme.primaryBlue,
                                              child: const Icon(Icons.play_arrow, color: Colors.white),
                                            ),
                                    ),
                                  ),
                                  title: Text(
                                    video.title,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.darkNavy,
                                    ),
                                  ),
                                  subtitle: Text(
                                    video.description,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                  trailing: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryBlue,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                      textStyle: const TextStyle(fontSize: 12),
                                    ),
                                    onPressed: () {
                                      Navigator.pushNamed(
                                        context,
                                        '/video-player',
                                        arguments: {
                                          'video': video,
                                          'course': course,
                                        },
                                      );
                                    },
                                    child: const Text('Play'),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            );
              },
            );
          },
        );
      },
    );
  }
}

// ─────────────────── BOOKS TAB ───────────────────
class _BooksTab extends StatelessWidget {
  final FirestoreService firestoreService;
  final String searchQuery;
  final String? userId;
  final bool isAdmin;

  const _BooksTab({
    required this.firestoreService,
    required this.searchQuery,
    required this.userId,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    if (isAdmin) return _buildBookList();
    if (userId == null) {
      return const _LockedMaterialsNotice(
        title: 'Reference Books',
        message: 'Please sign in to access the library.',
      );
    }
    return StreamBuilder(
      stream: firestoreService.getSubscription(userId!),
      builder: (context, subscriptionSnapshot) {
        final subscription = subscriptionSnapshot.data;
        final hasAccess = subscription != null &&
            subscription.status == 'active' &&
            subscription.expiryDate.isAfter(DateTime.now());
        if (!hasAccess) {
          return const _LockedMaterialsNotice(
            title: 'Reference Books',
            message: 'An active subscription is required to read the full library.',
          );
        }
        return _buildBookList();
      },
    );
  }

  Widget _buildBookList() {
    return StreamBuilder<List<BookModel>>(
      stream: firestoreService.getBooks(),
      builder: (context, snapshot) {
        final allBooks = snapshot.data ?? firestoreService.getBooksSync();
        final filtered = allBooks.where((b) {
          if (!b.isPublished || b.fileUrl.trim().isEmpty) return false;
          if (searchQuery.isEmpty) return true;
          return b.title.toLowerCase().contains(searchQuery) ||
              b.author.toLowerCase().contains(searchQuery) ||
              b.description.toLowerCase().contains(searchQuery);
        }).toList()
          ..sort((a, b) {
            final courseOrder = _compareCourseIds(
              firestoreService,
              a.courseId,
              b.courseId,
            );
            return courseOrder != 0 ? courseOrder : a.title.compareTo(b.title);
          });

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.menu_book_outlined,
                    size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                const Text(
                  'No books available yet',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Books will be uploaded by the admin',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(18),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final book = filtered[index];
            return _BookCard(
              book: book,
              courseLabel: _courseLabelFor(firestoreService, book.courseId),
            );
          },
        );
      },
    );
  }
}

class _BookCard extends StatelessWidget {
  final BookModel book;
  final String courseLabel;
  const _BookCard({required this.book, required this.courseLabel});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 64,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryBlue, AppTheme.darkNavy],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.menu_book, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkNavy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.person_outline,
                          size: 14, color: AppTheme.textMuted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          book.author,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    courseLabel,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    book.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.menu_book, size: 16,
                        color: Colors.white),
                    label: const Text('Read Inside App',
                        style: TextStyle(fontSize: 12, color: Colors.white)),
                    onPressed: () {
                      InAppDocumentViewer.show(
                        context,
                        title: book.title,
                        subtitle: book.author,
                        documentType: 'Book',
                        fileUrl: book.fileUrl,
                        authorOrYear: 'Author: ${book.author}',
                        description: book.description,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────── PAST PAPERS TAB ───────────────────
class _PastPapersTab extends StatefulWidget {
  final FirestoreService firestoreService;
  final String searchQuery;
  final String? userId;
  final bool isAdmin;

  const _PastPapersTab({
    required this.firestoreService,
    required this.searchQuery,
    required this.userId,
    required this.isAdmin,
  });

  @override
  State<_PastPapersTab> createState() => _PastPapersTabState();
}

class _PastPapersTabState extends State<_PastPapersTab> {
  String? _selectedYear;

  @override
  Widget build(BuildContext context) {
    if (widget.isAdmin) return _buildPastPapers();
    if (widget.userId == null) {
      return const _LockedMaterialsNotice(
        title: 'Past Examination Papers',
        message: 'Please sign in to access past papers.',
      );
    }
    return StreamBuilder(
      stream: widget.firestoreService.getSubscription(widget.userId!),
      builder: (context, subscriptionSnapshot) {
        final subscription = subscriptionSnapshot.data;
        final hasAccess = subscription != null &&
            subscription.status == 'active' &&
            subscription.expiryDate.isAfter(DateTime.now());
        if (!hasAccess) {
          return const _LockedMaterialsNotice(
            title: 'Past Examination Papers',
            message: 'An active subscription is required to view past papers.',
          );
        }
        return _buildPastPapers();
      },
    );
  }

  Widget _buildPastPapers() {
    return StreamBuilder<List<PastPaperModel>>(
      stream: widget.firestoreService.getPastPapers(),
      builder: (context, snapshot) {
        final allPapers =
            snapshot.data ?? widget.firestoreService.getPastPapersSync();
        final availableYears =
            allPapers.map((paper) => paper.year).toSet().toList()
              ..sort((a, b) => b.compareTo(a));
        if (_selectedYear == null && availableYears.isNotEmpty) {
          _selectedYear = availableYears.first;
        }

        final filtered = allPapers.where((pp) {
          if (!pp.isPublished || pp.fileUrl.trim().isEmpty) return false;
      if (widget.searchQuery.isNotEmpty) {
        return pp.title.toLowerCase().contains(widget.searchQuery) ||
            pp.description.toLowerCase().contains(widget.searchQuery) ||
            pp.year.contains(widget.searchQuery);
      }
      return _selectedYear == null || pp.year == _selectedYear;
    }).toList();

    return Column(
      children: [
        // Year Filter Strip
        if (availableYears.isNotEmpty)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Text(
                  'Year:',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppTheme.darkNavy),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: availableYears.map((year) {
                        final isSelected = _selectedYear == year;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(year),
                            selected: isSelected,
                            onSelected: (_) =>
                                setState(() => _selectedYear = year),
                            selectedColor:
                                AppTheme.primaryBlue.withOpacity(0.15),
                            checkmarkColor: AppTheme.primaryBlue,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? AppTheme.primaryBlue
                                  : AppTheme.textMuted,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Past Papers grouped by type
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.assignment_outlined,
                          size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        availableYears.isEmpty
                            ? 'No past papers uploaded yet'
                            : 'No papers found for ${_selectedYear ?? "selected year"}',
                        style: const TextStyle(
                            color: AppTheme.textMuted, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(18),
                  children: [
                    if (widget.searchQuery.isEmpty && _selectedYear != null)
                      _buildYearHeader(_selectedYear!),
                    _buildPaperSection(
                        'Test 1', 'test1', Icons.looks_one, filtered),
                    _buildPaperSection(
                        'Test 2', 'test2', Icons.looks_two, filtered),
                    _buildPaperSection('Sessional Exam', 'sessional',
                        Icons.school, filtered),
                  ],
                ),
        ),
      ],
    );
      },
    );
  }

  Widget _buildYearHeader(String year) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryBlue, AppTheme.darkNavy],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_month, color: Colors.white, size: 28),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Academic Year $year',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Test 1 • Test 2 • Sessional Exam',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaperSection(String label, String type, IconData icon,
      List<PastPaperModel> allFiltered) {
    final papers = allFiltered.where((pp) => pp.type == type).toList()
      ..sort((a, b) => _compareCourseIds(
            widget.firestoreService,
            a.courseId,
            b.courseId,
          ));
    if (papers.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10, top: 6),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _typeColor(type).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: _typeColor(type), size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkNavy,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _typeColor(type).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${papers.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _typeColor(type),
                  ),
                ),
              ),
            ],
          ),
        ),
        ...papers.map((pp) => _PastPaperCard(
              paper: pp,
              typeColor: _typeColor(type),
              courseLabel: _courseLabelFor(widget.firestoreService, pp.courseId),
            )),
        const SizedBox(height: 12),
      ],
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'test1':
        return const Color(0xFF2563EB);
      case 'test2':
        return const Color(0xFF7C3AED);
      case 'sessional':
        return const Color(0xFF059669);
      default:
        return AppTheme.primaryBlue;
    }
  }
}

class _PastPaperCard extends StatelessWidget {
  final PastPaperModel paper;
  final Color typeColor;
  final String courseLabel;

  const _PastPaperCard({
    required this.paper,
    required this.typeColor,
    required this.courseLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: typeColor.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 52,
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.picture_as_pdf, color: typeColor, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    paper.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkNavy,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    courseLabel,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    paper.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          paper.typeLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: typeColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          paper.year,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: typeColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.visibility, size: 15, color: Colors.white),
              label: const Text('View Inside',
                  style: TextStyle(fontSize: 12, color: Colors.white)),
              onPressed: () {
                InAppDocumentViewer.show(
                  context,
                  title: paper.title,
                  subtitle: '${paper.year} • ${paper.typeLabel}',
                  documentType: 'Past Paper',
                  fileUrl: paper.fileUrl,
                  authorOrYear: 'Examination: ${paper.year} (${paper.typeLabel})',
                  description: paper.description.isNotEmpty
                      ? paper.description
                      : 'Past technical drawing examination paper. Viewing is strictly inside the app.',
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}