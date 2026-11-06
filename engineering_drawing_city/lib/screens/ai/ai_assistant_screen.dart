import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:engineering_drawing_city/models/app_settings_model.dart';
import 'package:engineering_drawing_city/services/firebase_service.dart';
import 'package:engineering_drawing_city/theme/app_theme.dart';

class AIAssistantScreen extends StatefulWidget {
  static const String routeName = '/ai-assistant';
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _aiEnabled = true;
  AppSettingsModel? _appSettings;
  StreamSubscription? _subscriptionUpdates;

  // Quick prompts are sourced from app content (courses, videos, books, papers)
  List<String> _quickPrompts = [];

  @override
  void initState() {
    super.initState();
    final signedInUser = _authService.currentUser;
    if (signedInUser != null && signedInUser.role != 'admin') {
      _subscriptionUpdates = _firestoreService.getSubscription(signedInUser.uid).listen((_) {
        if (mounted) setState(() {});
      });
    }
    _loadAppSettings();
    _buildQuickPrompts();
    _messages.add(
      ChatMessage(
        id: 'welcome_msg',
        text: _buildWelcomeMessage(),
        sender: MessageSender.ai,
        timestamp: DateTime.now(),
      ),
    );
  }

  String _buildWelcomeMessage() {
    final hasSub = _hasActiveSubscription;
    if (!hasSub) {
      return '🔒 **AI Tutor is a Premium Feature**\n\n'
          'You need an active subscription to use the AI Tutor.\n\n'
          'The student subscription is K50 per month. Secure mobile money checkout is being prepared:\n'
          '• Full AI tutoring on all course topics\n'
          '• Instant answers on projections, GD&T, isometric views\n'
          '• Past paper guidance\n\n'
          'Payment collection is not available yet. Please check back when checkout is enabled.';
    }
    return 'Hello! I am your Engineering Drawing & CAD AI Tutor.\n\n'
        'I can only answer questions about topics covered in this app:\n'
        '• Orthographic projections (1st & 3rd angle)\n'
        '• Isometric & axonometric drawing\n'
        '• Sectional views & hatching\n'
        '• Machine drawing, GD&T, limits & fits\n'
        '• Drawing standards, scales, and lettering\n\n'
        'Tap a topic below or type your question!';
  }

  void _buildQuickPrompts() {
    // Build quick prompts from actual app content
    final videos = _firestoreService.getVideosSync();
    final books = _firestoreService.getBooksSync();

    _quickPrompts = [
      '1st vs 3rd Angle Projections',
      'How to draw an Isometric Ellipse?',
      'What are GD&T Datum Symbols?',
      'Hole vs Shaft Basis (Limits & Fits)',
      'Sectional Hatching Angle & Rules',
      'Standard Drawing Sheet Sizes (A0-A4)',
    ];

    // Add topic-based prompts from actual videos
    for (final v in videos.take(3)) {
      final shortTitle = v.title.replaceAll(RegExp(r'^\d+\.\s*'), '');
      if (!_quickPrompts.contains(shortTitle)) {
        _quickPrompts.add(shortTitle);
      }
    }

    // Add book-based prompts
    for (final b in books.take(2)) {
      final prompt = 'Topics covered in "${b.title}"';
      if (!_quickPrompts.contains(prompt)) {
        _quickPrompts.add(prompt);
      }
    }
  }

  Future<void> _loadAppSettings() async {
    _appSettings = await _firestoreService.getAppSettings();
    if (!mounted) return;
    setState(() => _aiEnabled = _appSettings?.aiEnabled ?? true);
  }

  void _sendMessage([String? presetText]) {
    final text = (presetText ?? _messageController.text).trim();
    if (text.isEmpty) return;

    // Check subscription gate first
    final hasSub = _hasActiveSubscription;

    if (!hasSub) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              '🔒 Subscribe to unlock the AI Tutor. Go to Profile → Pay Now.'),
          backgroundColor: AppTheme.errorRed,
          action: SnackBarAction(
            label: 'Subscribe',
            textColor: Colors.white,
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    if (!_aiEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('AI Assistant is currently disabled in system settings.')),
      );
      return;
    }

    setState(() {
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: text,
        sender: MessageSender.user,
        timestamp: DateTime.now(),
      ));
      if (presetText == null) _messageController.clear();
      _isLoading = true;
    });

    _scrollToBottom();

    Future.delayed(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      final answer = _generateKnowledgeResponse(text);
      setState(() {
        _messages.add(ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: answer,
          sender: MessageSender.ai,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });
      _scrollToBottom();
    });
  }

  /// Checks if a query is about app content; returns null if out-of-scope.
  bool _isInScope(String q) {
    // Topics available in our courses
    final inScopeKeywords = [
      'draw', 'projection', 'orthographic', 'isometric', 'axonometric',
      'section', 'hatch', 'scale', 'line', 'letter', 'dimension', 'title block',
      'gd&t', 'datum', 'tolerance', 'fit', 'shaft', 'hole', 'thread', 'bolt',
      'nut', 'cad', 'autocad', 'ellipse', 'circle', 'angle', 'view',
      'first angle', 'third angle', '1st angle', '3rd angle', 'front view',
      'top view', 'side view', 'a0', 'a1', 'a2', 'a3', 'a4', 'sheet',
      'instrument', 'compass', 'set square', 't-square', 'pencil',
      'rivet', 'key', 'pin', 'bearing', 'engineering drawing',
      'technical drawing', 'machine drawing', 'book', 'past paper',
      'test', 'sessional', 'exam', 'course', 'lesson', 'video',
      'copperbelt', 'cbu', 'edc', 'beng', 'mining', 'chemical',
    ];
    final lq = q.toLowerCase();
    return inScopeKeywords.any((kw) => lq.contains(kw));
  }

  String _generateKnowledgeResponse(String query) {
    final q = query.toLowerCase();

    // Check if query is about app-available resources
    if (q.contains('book') || q.contains('textbook') || q.contains('reference')) {
      final books = _firestoreService.getBooksSync();
      if (books.isEmpty) {
        return 'No books have been uploaded yet. Please check the Books tab under Courses for updates.';
      }
      final bookList = books.map((b) => '📚 **${b.title}** by ${b.author}\n   ${b.description}').join('\n\n');
      return '**Books Available in Engineering Drawing City:**\n\n$bookList\n\nOpen the Books tab in Courses to read them inside the app (view-only protected mode).';
    }

    if (q.contains('past paper') || q.contains('test 1') || q.contains('test 2') ||
        q.contains('sessional') || q.contains('exam')) {
      final papers = _firestoreService.getPastPapersSync();
      if (papers.isEmpty) {
        return 'No past papers have been uploaded yet. Check the Past Papers tab under Courses for the latest additions.';
      }
      final years = _firestoreService.getAvailablePastPaperYears();
      final paperInfo = years.map((year) {
        final test1 = papers.where((p) => p.year == year && p.type == 'test1').length;
        final test2 = papers.where((p) => p.year == year && p.type == 'test2').length;
        final sess = papers.where((p) => p.year == year && p.type == 'sessional').length;
        return '📅 **$year**: Test 1 ($test1), Test 2 ($test2), Sessional ($sess)';
      }).join('\n');
      return '**Past Papers Available:**\n\n$paperInfo\n\nOpen the Past Papers tab in Courses → filter by year to view them inside the app (downloads disabled).';
    }

    if (q.contains('video') || q.contains('lesson') || q.contains('watch')) {
      final videos = _firestoreService.getVideosSync();
      final courses = _firestoreService.getCoursesSync();
      final courseSummary = courses.map((c) {
        final vids = _firestoreService.getVideosByCourseSync(c.id);
        return '🎬 **${c.title}** — ${vids.length} video${vids.length == 1 ? "" : "s"}';
      }).join('\n');
      return '**Video Lessons in this App:**\n\n$courseSummary\n\n'
          'Total: ${videos.length} lessons across ${courses.length} courses.\n'
          'Open the Videos tab in Courses to watch them.';
    }

    // Check if query is out of scope
    if (!_isInScope(q)) {
      return '⚠️ **Out of Scope**\n\n'
          'I\'m only able to answer questions about topics covered in **Engineering Drawing City**:\n\n'
          '• Orthographic projections\n'
          '• Isometric & axonometric drawing\n'
          '• Sectional views & hatching conventions\n'
          '• Machine drawing, GD&T, limits & fits\n'
          '• Drawing standards, scales, lettering\n'
          '• Books and past papers in this app\n\n'
          'Please rephrase your question to relate to engineering drawing topics.';
    }

    // In-scope responses
    if (q.contains('1st') || q.contains('first angle') || q.contains('third angle') || q.contains('3rd')) {
      return '**First Angle vs Third Angle Projection:**\n\n'
          '• **First Angle Projection (ISO European standard):** The object is placed between the observer and the plane of projection (1st quadrant). Therefore:\n'
          '  - Top View is drawn **below** the Front View.\n'
          '  - Left Side View is drawn on the **right** of Front View.\n\n'
          '• **Third Angle Projection (ASME American standard):** The projection plane is placed between the observer and the object (3rd quadrant). Therefore:\n'
          '  - Top View is drawn **above** the Front View.\n'
          '  - Left Side View is drawn on the **left** of Front View.\n\n'
          'Standard projection symbols on the title block show a truncated cone to identify which system is used.\n\n'
          '📺 *Watch: Course #02 – "First Angle vs Third Angle Projection Concepts"*';
    }

    if (q.contains('ellipse') || q.contains('isometric circle') || q.contains('four-centre') || q.contains('4 center') || q.contains('four center')) {
      return '**Drawing Isometric Ellipses using the Four-Centre Method:**\n\n'
          '1. Draw an isometric rhombus with sides equal to the circle diameter (axes inclined at 30°).\n'
          '2. Locate the midpoints of all four sides of the rhombus.\n'
          '3. From the obtuse angle corners (120° vertices), draw lines to the opposite midpoints.\n'
          '4. The intersections of these lines provide 2 small arc centers (R1).\n'
          '5. The obtuse corners themselves serve as the 2 large arc centers (R2).\n'
          '6. Strike four tangent arcs to form a continuous isometric ellipse.\n\n'
          '📺 *Watch: Course #03 – "Drawing Isometric Circles with the Four-Centre Method"*';
    }

    if (q.contains('gd&t') || q.contains('datum') || q.contains('geometric') || q.contains('feature control')) {
      return '**Geometric Dimensioning and Tolerancing (GD&T):**\n\n'
          '• **Feature Control Frame:** A rectangular box containing:\n'
          '  [ Geometric Symbol | Tolerance Value (e.g. ⌀0.05) | Datum References (A | B | C) ]\n\n'
          '• **Key Categories:**\n'
          '  - Form: Flatness (⏥), Straightness (—), Circularity (○), Cylindricity (⌭)\n'
          '  - Orientation: Perpendicularity (⟂), Parallelism (∥), Angularity (∠)\n'
          '  - Location: True Position (⌖), Concentricity (◎), Symmetry (⌯)\n'
          '  - Runout: Circular Runout (↗), Total Runout (⇗)\n\n'
          'Datums represent mathematically ideal reference planes or axes.\n\n'
          '📺 *Watch: Course #05 – "GD&T Symbols, Datums & Feature Control Frames"*';
    }

    if (q.contains('limits') || q.contains('fits') || q.contains('hole') || q.contains('shaft')) {
      return '**Limits and Fits in Mechanical Drafting:**\n\n'
          '• **Hole Basis System (Preferred):** Basic size is the minimum hole size (tolerance zone H, where lower deviation is zero).\n'
          '• **Shaft Basis System:** Basic size is the maximum shaft size (tolerance zone h, upper deviation is zero).\n\n'
          '• **Three Types of Fits:**\n'
          '  1. **Clearance Fit:** Hole is always larger than shaft (e.g., H7/g6, loose running/sliding).\n'
          '  2. **Transition Fit:** Tolerance zones overlap; may be tight or loose (e.g., H7/k6, location fit).\n'
          '  3. **Interference Fit:** Shaft is always larger than hole; requires press or heat (e.g., H7/p6, permanent press fit).\n\n'
          '📺 *Watch: Course #05 – "Limits, Fits & Tolerances in Machine Drawing"*';
    }

    if (q.contains('hatching') || q.contains('section') || q.contains('cutting plane')) {
      return '**Sectional Views & Hatching Conventions (ISO 128):**\n\n'
          '• Hatching lines are drawn as continuous thin lines (type B) inclined at **45°** to the principal outlines or centerlines.\n'
          '• Spacing between lines should be uniform (1.5mm to 3mm depending on drawing size).\n'
          '• Adjacent parts in an assembly must be hatched in opposite directions (45° left vs 45° right) or staggered pitches.\n'
          '• **Parts NEVER sectioned longitudinally:** Shafts, bolts, nuts, rivets, keys, pins, ribs/webs, and ball bearings.\n\n'
          '📺 *Watch: Course #04 – "Full Sectional Views & Hatching Standards"*';
    }

    if (q.contains('sheet') || q.contains('a0') || q.contains('a1') || q.contains('a2') || q.contains('a3') || q.contains('a4')) {
      return '**Standard ISO 216 Drawing Sheet Sizes:**\n\n'
          '• **A0:** 841 × 1189 mm (Area = 1 m², aspect ratio 1:√2)\n'
          '• **A1:** 594 × 841 mm\n'
          '• **A2:** 420 × 594 mm\n'
          '• **A3:** 297 × 420 mm (Common student manual drafting size)\n'
          '• **A4:** 210 × 297 mm (Standard project reports & CAD printouts)\n\n'
          'Title blocks are conventionally located at the bottom-right corner of the sheet (max width 170mm).\n\n'
          '📺 *Watch: Course #01 – "Drafting Instruments & Drawing Sheet Setup"*';
    }

    if (q.contains('scale') || q.contains('plain scale') || q.contains('diagonal scale')) {
      return '**Engineering Drawing Scales:**\n\n'
          '**Plain Scale:** Represents two units (e.g., metres and decimetres).\n'
          '  Construction: Draw a line of length = (RF × max distance). Divide into main units and subdivide the leftmost unit.\n\n'
          '**Diagonal Scale:** Represents three units by using diagonals to interpolate sub-divisions.\n'
          '  Extra construction: Draw verticals and diagonals within the subdivided leftmost unit.\n\n'
          '**Representative Fraction (RF) = Drawing Size / Actual Size**\n\n'
          '📺 *Watch: Course #01 – "Plain Scales and Diagonal Scales Worked Examples"*';
    }

    if (q.contains('isometric') || q.contains('axonometric') || q.contains('box method')) {
      return '**Isometric Drawing Principles:**\n\n'
          '• Three isometric axes make angles of **120°** to each other (30° to horizontal).\n'
          '• **Box Method:** Enclose the object in a rectangular box aligned to isometric axes, then cut away.\n'
          '• True lengths along isometric axes: use actual dimensions.\n'
          '• Non-isometric lines: locate end points and join — they are NOT measured directly.\n'
          '• Circles become ellipses in isometric views (use Four-Centre Method for accuracy).\n\n'
          '📺 *Watch: Course #03 – "Isometric Projection Principles & The Box Method"*';
    }

    if (q.contains('cad') || q.contains('autocad') || q.contains('computer')) {
      return '**Introduction to 2D CAD Drafting (AutoCAD):**\n\n'
          '• **Layers:** Organize drawing elements (e.g., OBJECT, HIDDEN, CENTER, DIM).\n'
          '• **Object Snaps:** ENDPOINT, MIDPOINT, INTERSECTION, PERPENDICULAR for precision.\n'
          '• **Polar Tracking:** Constrains cursor movement to set angles (30°, 45°, 90°, etc.).\n'
          '• **Dimension Styles:** ANSI, ISO standards; text height and arrow size.\n'
          '• **Plotting:** Scale drawing to paper size; set lineweights per layer.\n\n'
          '📺 *Watch: Course #05 – "Introduction to AutoCAD 2D Drafting for Students"*';
    }

    return 'Thank you for your question on **"$query"**.\n\n'
        'In technical engineering drawing:\n'
        '• Always adhere to ISO 128 drafting standards for line weight, text height (3.5mm for notes, 5mm for titles), and unidirectional dimensioning.\n'
        '• Ensure projection planes (Horizontal Plane, Vertical Plane, Profile Plane) remain aligned with proper folding line references (X-Y datum).\n'
        '• Check out our **Videos**, **Books**, and **Past Papers** tabs in Courses for comprehensive worked examples!\n\n'
        '_Tip: For best results, ask about specific topics like projections, isometric drawing, GD&T, or sections._';
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _subscriptionUpdates?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool get _hasActiveSubscription {
    final userId = _authService.currentUser?.uid ?? '';
    return _authService.isAdmin || _firestoreService.hasActiveSubscription(userId);
  }

  @override
  Widget build(BuildContext context) {
    final hasSubscription = _hasActiveSubscription;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.psychology, color: AppTheme.accentCyan),
            SizedBox(width: 10),
            Flexible(
              child: Text(
                'AI Engineering Drawing Tutor',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          if (hasSubscription) ...[
            Row(
              children: [
                Text(
                  _aiEnabled ? 'AI Active' : 'AI Off',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
                Switch(
                  value: _aiEnabled,
                  activeColor: AppTheme.accentCyan,
                  onChanged: (val) {
                    setState(() => _aiEnabled = val);
                    if (_appSettings != null) {
                      final updated = AppSettingsModel(
                        appName: _appSettings!.appName,
                        logo: _appSettings!.logo,
                        welcomeMessage: _appSettings!.welcomeMessage,
                        subscriptionPrice: _appSettings!.subscriptionPrice,
                        subscriptionDuration: _appSettings!.subscriptionDuration,
                        paymentInstructions: _appSettings!.paymentInstructions,
                        aiEnabled: val,
                        contactInformation: _appSettings!.contactInformation,
                        maintenanceMode: _appSettings!.maintenanceMode,
                      );
                      _firestoreService.updateAppSettings(updated);
                    }
                  },
                ),
              ],
            ),
          ],
          IconButton(
            tooltip: 'Clear Chat',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _messages.clear();
                _messages.add(
                  ChatMessage(
                    id: 'welcome_msg_reset',
                    text: hasSubscription
                        ? 'Chat cleared. Ask me anything about engineering drawing!'
                        : _buildWelcomeMessage(),
                    sender: MessageSender.ai,
                    timestamp: DateTime.now(),
                  ),
                );
              });
            },
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: Column(
            children: [
              // Subscription lock banner
              if (!hasSubscription)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  color: AppTheme.errorRed.withOpacity(0.08),
                  child: Row(
                    children: [
                      const Icon(Icons.lock, color: AppTheme.errorRed, size: 20),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'AI Tutor requires an active subscription. Student access costs K50 per month; secure mobile money checkout is being prepared.',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.errorRed,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/profile'),
                        child: const Text('Subscribe',
                            style: TextStyle(
                                color: AppTheme.primaryBlue,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),

              // Quick Prompt Suggestion Chips (only if subscribed)
              if (hasSubscription)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TOPICS FROM THIS APP (TAP TO ASK):',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _quickPrompts.take(8).map((p) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ActionChip(
                                backgroundColor:
                                    AppTheme.accentCyanLight.withOpacity(0.6),
                                side: const BorderSide(
                                    color: Color(0xFFB2EBF2)),
                                label: Text(
                                  p,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.primaryBlue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                onPressed: () => _sendMessage(p),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),

              // Chat Messages List
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    return _buildMessageBubble(msg);
                  },
                ),
              ),

              if (_isLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'AI Tutor is typing...',
                              style: TextStyle(
                                  fontSize: 12, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // Input Box
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                color: Colors.white,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        enabled: hasSubscription && _aiEnabled,
                        decoration: InputDecoration(
                          hintText: hasSubscription
                              ? 'Ask about orthographic views, GD&T, scales...'
                              : 'Subscribe to unlock AI Tutor',
                          border: const OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasSubscription && _aiEnabled
                            ? AppTheme.primaryBlue
                            : Colors.grey,
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: hasSubscription && _aiEnabled
                          ? () => _sendMessage()
                          : null,
                      child: const Icon(Icons.send, color: Colors.white),
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

  Widget _buildMessageBubble(ChatMessage msg) {
    final isUser = msg.sender == MessageSender.user;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser)
            Container(
              margin: const EdgeInsets.only(right: 10, top: 4),
              child: const CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.primaryBlue,
                child: Icon(Icons.psychology, color: Colors.white, size: 18),
              ),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isUser ? AppTheme.primaryBlue : Colors.white,
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomRight:
                      isUser ? const Radius.circular(0) : const Radius.circular(16),
                  bottomLeft:
                      !isUser ? const Radius.circular(0) : const Radius.circular(16),
                ),
                border: isUser ? null : Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    msg.text,
                    style: TextStyle(
                      color: isUser ? Colors.white : AppTheme.darkNavy,
                      fontSize: 13.5,
                      height: 1.45,
                    ),
                  ),
                  if (!isUser) ...[
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: msg.text));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Response copied to clipboard')),
                        );
                      },
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.copy, size: 12, color: AppTheme.textMuted),
                          SizedBox(width: 4),
                          Text('Copy',
                              style: TextStyle(
                                  fontSize: 11, color: AppTheme.textMuted)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isUser)
            Container(
              margin: const EdgeInsets.only(left: 10, top: 4),
              child: const CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.accentCyan,
                child: Icon(Icons.person, color: AppTheme.darkNavy, size: 18),
              ),
            ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String id;
  final String text;
  final MessageSender sender;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
  });
}

enum MessageSender { user, ai }