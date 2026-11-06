import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:engineering_drawing_city/theme/app_theme.dart';

class InAppDocumentViewer extends StatefulWidget {
  final String title;
  final String subtitle;
  final String documentType; // 'Book' or 'Past Paper'
  final String? fileUrl;
  final String? authorOrYear;
  final String? description;
  final List<String>? sampleTopics;

  const InAppDocumentViewer({
    super.key,
    required this.title,
    required this.subtitle,
    required this.documentType,
    this.fileUrl,
    this.authorOrYear,
    this.description,
    this.sampleTopics,
  });

  static void show(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String documentType,
    String? fileUrl,
    String? authorOrYear,
    String? description,
    List<String>? sampleTopics,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InAppDocumentViewer(
          title: title,
          subtitle: subtitle,
          documentType: documentType,
          fileUrl: fileUrl,
          authorOrYear: authorOrYear,
          description: description,
          sampleTopics: sampleTopics,
        ),
      ),
    );
  }

  @override
  State<InAppDocumentViewer> createState() => _InAppDocumentViewerState();
}

class _InAppDocumentViewerState extends State<InAppDocumentViewer> {
  double _zoomLevel = 1.0;
  final TransformationController _transController = TransformationController();
  int _activePage = 1;
  final int _totalPages = 12;
  PdfControllerPinch? _pdfController;

  bool get _hasRemotePdf {
    final rawUrl = widget.fileUrl;
    if (rawUrl == null || rawUrl.trim().isEmpty) return false;
    final uri = Uri.tryParse(rawUrl.trim());
    if (uri == null || !uri.path.toLowerCase().endsWith('.pdf')) return false;

    final isLegacyFirebaseFile = uri.scheme == 'gs' &&
        uri.host.isNotEmpty &&
        uri.pathSegments.isNotEmpty &&
        uri.pathSegments.first == 'learning_materials';
    final isGitHubRawFile = uri.scheme == 'https' &&
        (uri.host == 'raw.githubusercontent.com' ||
            (uri.host == 'github.com' && uri.pathSegments.contains('raw')));
    return isLegacyFirebaseFile || isGitHubRawFile;
  }

  Future<PdfDocument> _loadPdfDocument() async {
    final url = widget.fileUrl!.trim();
    final uri = Uri.parse(url);
    final Uint8List? bytes;

    if (uri.scheme == 'gs') {
      // Backwards compatibility for documents already stored in Firebase Storage.
      bytes = await FirebaseStorage.instance
          .refFromURL(url)
          .getData(100 * 1024 * 1024);
    } else {
      final response = await http.get(uri).timeout(
        const Duration(seconds: 60),
      );
      if (response.statusCode != 200) {
        throw Exception('The PDF server returned HTTP ${response.statusCode}.');
      }
      if (response.bodyBytes.length > 100 * 1024 * 1024) {
        throw Exception('This PDF is larger than the 100 MB viewing limit.');
      }
      bytes = response.bodyBytes;
    }

    if (bytes == null || bytes.length < 5 ||
        String.fromCharCodes(bytes.take(5)) != '%PDF-') {
      throw Exception(
        'The link did not return a valid PDF. Use the GitHub Raw link, not the normal GitHub file page.',
      );
    }
    return PdfDocument.openData(bytes);
  }

  @override
  void initState() {
    super.initState();
    if (_hasRemotePdf) {
      _pdfController = PdfControllerPinch(
        document: _loadPdfDocument(),
      );
    }
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    _transController.dispose();
    super.dispose();
  }

  void _zoomIn() {
    setState(() {
      _zoomLevel = (_zoomLevel + 0.25).clamp(1.0, 3.0);
      _transController.value = Matrix4.identity()..scale(_zoomLevel);
    });
  }

  void _zoomOut() {
    setState(() {
      _zoomLevel = (_zoomLevel - 0.25).clamp(1.0, 3.0);
      _transController.value = Matrix4.identity()..scale(_zoomLevel);
    });
  }

  void _resetZoom() {
    setState(() {
      _zoomLevel = 1.0;
      _transController.value = Matrix4.identity();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_pdfController != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          backgroundColor: AppTheme.darkNavy,
        ),
        body: PdfViewPinch(controller: _pdfController!),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGold.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.documentType.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentGold,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Flexible(
                  child: Text(
                    '🔒 In-App Viewing Only',
                    style: TextStyle(fontSize: 11, color: AppTheme.accentCyan),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Zoom Out',
            icon: const Icon(Icons.zoom_out, color: Colors.white70),
            onPressed: _zoomOut,
          ),
          IconButton(
            tooltip: 'Zoom In',
            icon: const Icon(Icons.zoom_in, color: Colors.white70),
            onPressed: _zoomIn,
          ),
          IconButton(
            tooltip: 'Fit to Screen',
            icon: const Icon(Icons.fit_screen, color: Colors.white70),
            onPressed: _resetZoom,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Prominent Security & Terms Notice (No Download Policy)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFF1E1B4B),
                border: Border(
                  bottom: BorderSide(color: Color(0xFF4338CA), width: 1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGold.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      color: AppTheme.accentGold,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Course Material • In-App Reader',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'The app checks your access before opening this document. Public GitHub links can still be shared outside the app.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 11,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.file_download_off, size: 14, color: Colors.redAccent),
                        SizedBox(width: 4),
                        Text(
                          'View Only',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Document Reader Canvas
            Expanded(
              child: Stack(
                children: [
                  // Watermark Background
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: 0.04,
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 2.0,
                          ),
                          itemCount: 20,
                          itemBuilder: (context, index) => Center(
                            child: Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.rotationZ(-0.35),
                              child: Text(
                                'ENGINEERING DRAWING CITY\nVIEW ONLY • PROTECTED',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Interactive Reader Area
                  InteractiveViewer(
                    transformationController: _transController,
                    minScale: 1.0,
                    maxScale: 3.5,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 820),
                          child: Card(
                            color: Colors.white,
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Sheet Header Box
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Icon(
                                            widget.documentType == 'Book'
                                                ? Icons.menu_book
                                                : Icons.assignment_outlined,
                                            size: 32,
                                            color: AppTheme.primaryBlue,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                widget.title,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.darkNavy,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                widget.subtitle,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AppTheme.textMuted,
                                                ),
                                              ),
                                              if (widget.authorOrYear != null) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  widget.authorOrYear!,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: AppTheme.primaryBlue,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Academic Description Box
                                  if (widget.description != null &&
                                      widget.description!.isNotEmpty) ...[
                                    Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: const Color(0xFFBFDBFE)),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Icon(
                                            Icons.info_outline,
                                            size: 18,
                                            color: AppTheme.primaryBlue,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              widget.description!,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Color(0xFF1E3A8A),
                                                height: 1.4,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                  ],

                                  // Simulated Drafting Plate / Technical Drawing Display
                                  Container(
                                    height: 260,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F172A),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppTheme.accentCyan.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          CustomPaint(
                                            size: Size.infinite,
                                            painter: _TechnicalDrawingPainter(),
                                          ),
                                          Positioned(
                                            top: 12,
                                            left: 12,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.black87,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'FIGURE ${_activePage}.1 • ORTHOGRAPHIC & ISOMETRIC PROJECTION',
                                                style: const TextStyle(
                                                  color: AppTheme.accentCyan,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 12,
                                            right: 12,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.black87,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: const Text(
                                                'SCALE 1:1 • ALL DIMENSIONS IN MM',
                                                style: TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 9,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Chapter / Section Contents
                                  const Text(
                                    'Curriculum Units & Drawing Guidelines:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.darkNavy,
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  ...((widget.sampleTopics ?? [
                                    'Standard Drawing Sheet Layouts (A0, A1, A2, A3, A4)',
                                    'Types of Lines & Lettering Conventions per BS 8888',
                                    'Geometrical Constructions: Ellipses, Parabolas & Involutes',
                                    'First-Angle & Third-Angle Orthographic Projections',
                                    'Sectional Views: Full, Half, Offset and Revolved Sections',
                                    'Isometric and Oblique Pictorial Drawing Principles',
                                    'Dimensioning Rules, Tolerances and Surface Texture Symbols',
                                    'Fasteners, Screw Threads, Keys and Machine Assembly',
                                  ]).map((topic) => Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Icon(
                                              Icons.check_circle_outline,
                                              size: 16,
                                              color: AppTheme.primaryBlue,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                topic,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Color(0xFF334155),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ))),

                                  const SizedBox(height: 24),


                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Navigation Bar (Page controls)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                border: Border(
                  top: BorderSide(color: Color(0xFF334155), width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white30),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    icon: const Icon(Icons.chevron_left, size: 18),
                    label: const Text('Prev Page', style: TextStyle(fontSize: 12)),
                    onPressed: _activePage > 1
                        ? () => setState(() => _activePage--)
                        : null,
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.menu_book, color: AppTheme.accentGold, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Page $_activePage of $_totalPages',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white30),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    icon: const Icon(Icons.chevron_right, size: 18),
                    label: const Text('Next Page', style: TextStyle(fontSize: 12)),
                    onPressed: _activePage < _totalPages
                        ? () => setState(() => _activePage++)
                        : null,
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

class _TechnicalDrawingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.cyan.withValues(alpha: 0.12)
      ..strokeWidth = 1.0;

    const step = 20.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final linePaint = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.8)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final cx = size.width / 2;
    final cy = size.height / 2;

    // Draw isometric cube / drafting shape
    final path = Path();
    path.moveTo(cx, cy - 60);
    path.lineTo(cx + 70, cy - 20);
    path.lineTo(cx + 70, cy + 60);
    path.lineTo(cx, cy + 100);
    path.lineTo(cx - 70, cy + 60);
    path.lineTo(cx - 70, cy - 20);
    path.close();

    // Center internal edges
    path.moveTo(cx, cy - 60);
    path.lineTo(cx, cy + 20);
    path.lineTo(cx + 70, cy - 20);
    path.moveTo(cx, cy + 20);
    path.lineTo(cx - 70, cy - 20);

    canvas.drawPath(path, linePaint);

    // Dimension lines
    final dimPaint = Paint()
      ..color = Colors.amberAccent.withValues(alpha: 0.7)
      ..strokeWidth = 1.0;

    canvas.drawLine(Offset(cx - 70, cy + 70), Offset(cx + 70, cy + 70), dimPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
