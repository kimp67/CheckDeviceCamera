import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../models/fps_range_model.dart';
import '../utils/camera_fps_analyzer.dart';
import '../widgets/fps_range_card.dart';
import '../widgets/fps_bar_chart.dart';
import '../widgets/camera_preview_widget.dart';
import 'result_detail_screen.dart';

class CameraInspectorScreen extends StatefulWidget {
  final CameraDescription camera;

  const CameraInspectorScreen({super.key, required this.camera});

  @override
  State<CameraInspectorScreen> createState() => _CameraInspectorScreenState();
}

class _CameraInspectorScreenState extends State<CameraInspectorScreen>
    with TickerProviderStateMixin {
  List<FpsRangeInfo>? _fpsRanges;
  bool _isAnalyzing = false;
  String _progressMessage = '';
  int _progressStep = 0;
  String? _errorMessage;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // 라이브 프리뷰용 컨트롤러
  CameraController? _previewController;
  bool _showPreview = false;
  double _currentLiveFps = 0;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _previewController?.dispose();
    super.dispose();
  }

  Future<void> _startAnalysis() async {
    if (_isAnalyzing) return;

    setState(() {
      _isAnalyzing = true;
      _fpsRanges = null;
      _errorMessage = null;
      _progressStep = 0;
      _progressMessage = '분석을 시작합니다...';
    });

    try {
      final ranges = await CameraFpsAnalyzer.analyzeFpsRanges(
        widget.camera,
        onProgress: (message) {
          if (mounted) {
            setState(() {
              _progressMessage = message;
              _progressStep++;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _fpsRanges = ranges;
          _isAnalyzing = false;
        });
        _fadeController.forward(from: 0);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isAnalyzing = false;
        });
      }
    }
  }

  Future<void> _toggleLivePreview() async {
    if (_showPreview) {
      await _previewController?.dispose();
      setState(() {
        _previewController = null;
        _showPreview = false;
        _currentLiveFps = 0;
      });
    } else {
      final controller = CameraController(
        widget.camera,
        ResolutionPreset.high,
        enableAudio: false,
      );
      try {
        await controller.initialize();
        if (mounted) {
          setState(() {
            _previewController = controller;
            _showPreview = true;
          });
          // FPS 측정
          _measureLiveFps(controller);
        }
      } catch (e) {
        await controller.dispose();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('프리뷰 시작 실패: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _measureLiveFps(CameraController controller) {
    // CameraValue.fps 값을 주기적으로 읽어 라이브 FPS 표시
    Future.doWhile(() async {
      if (!mounted || !_showPreview) return false;
      if (controller.value.isInitialized) {
        setState(() {
          _currentLiveFps = controller.value.fps;
        });
      }
      await Future.delayed(const Duration(milliseconds: 500));
      return mounted && _showPreview;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final directionLabel = CameraFpsAnalyzer.lensDirectionToKorean(
      widget.camera.lensDirection,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        title: Text(directionLabel),
        actions: [
          if (_fpsRanges != null)
            IconButton(
              icon: const Icon(Icons.info_outline_rounded),
              tooltip: '상세 보기',
              onPressed: () => _navigateToDetail(),
            ),
        ],
      ),
      body: Column(
        children: [
          // 라이브 프리뷰 섹션
          if (_showPreview && _previewController != null)
            CameraPreviewWidget(
              controller: _previewController!,
              liveFps: _currentLiveFps,
              onClose: _toggleLivePreview,
            ),

          Expanded(
            child: _buildBody(theme, directionLabel),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'preview_fab',
            onPressed: _toggleLivePreview,
            tooltip: _showPreview ? '프리뷰 닫기' : '라이브 프리뷰',
            backgroundColor: _showPreview
                ? Colors.red.withValues(alpha: 0.8)
                : const Color(0xFF1565C0),
            child: Icon(
              _showPreview ? Icons.videocam_off_rounded : Icons.videocam_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'analyze_fab',
            onPressed: _isAnalyzing ? null : _startAnalysis,
            backgroundColor: _isAnalyzing
                ? Colors.grey.shade800
                : const Color(0xFF1565C0),
            icon: _isAnalyzing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.analytics_rounded, color: Colors.white),
            label: Text(
              _isAnalyzing ? '분석 중...' : 'FPS 분석 시작',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeData theme, String directionLabel) {
    if (_errorMessage != null) {
      return _buildErrorState(theme);
    }

    if (_isAnalyzing) {
      return _buildAnalyzingState(theme);
    }

    if (_fpsRanges == null) {
      return _buildIdleState(theme, directionLabel);
    }

    return _buildResultState(theme);
  }

  Widget _buildIdleState(ThemeData theme, String directionLabel) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0).withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF1565C0).withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.analytics_outlined,
                color: Color(0xFF42A5F5),
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '$directionLabel\nFPS 범위 분석',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              '아래 버튼을 눌러 이 카메라가 지원하는\n모든 해상도 프리셋의 FPS 범위를 분석합니다.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white54,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildFeatureList(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureList(ThemeData theme) {
    final features = [
      (Icons.speed_rounded, '6가지 해상도 프리셋 분석'),
      (Icons.video_settings_rounded, '실시간 FPS 측정'),
      (Icons.bar_chart_rounded, '시각적 FPS 비교 차트'),
      (Icons.info_rounded, '프레임률 카테고리 분류'),
    ];

    return Column(
      children: features.map((f) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(f.$1, color: const Color(0xFF42A5F5), size: 18),
              const SizedBox(width: 8),
              Text(
                f.$2,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAnalyzingState(ThemeData theme) {
    final totalSteps = CameraFpsAnalyzer.presetPairs.length;
    final progress = totalSteps > 0 ? _progressStep / totalSteps : 0.0;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                strokeWidth: 6,
                backgroundColor: Colors.white10,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF42A5F5),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '카메라 분석 중',
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _progressMessage,
                key: ValueKey(_progressMessage),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF42A5F5),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF42A5F5),
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Text(
              '$_progressStep / $totalSteps',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white38,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultState(ThemeData theme) {
    final ranges = _fpsRanges!;
    final supportedRanges = ranges.where((r) => r.isSupported).toList();
    final maxFps = supportedRanges.isEmpty
        ? 0.0
        : supportedRanges.map((r) => r.maxFps).reduce((a, b) => a > b ? a : b);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _buildSummaryCard(theme, supportedRanges, maxFps),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: FpsBarChart(fpsRanges: ranges),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                '해상도 프리셋별 FPS 범위',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: Colors.white54,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: FpsRangeCard(fpsRange: ranges[index]),
                );
              },
              childCount: ranges.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      ThemeData theme, List<FpsRangeInfo> supportedRanges, double maxFps) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1565C0).withValues(alpha: 0.4),
            const Color(0xFF0D47A1).withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF1565C0).withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.summarize_rounded,
                  color: Color(0xFF42A5F5), size: 20),
              const SizedBox(width: 8),
              Text(
                '분석 요약',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatItem(theme, '최대 FPS', '${maxFps.toStringAsFixed(0)} fps',
                  const Color(0xFF42A5F5)),
              const SizedBox(width: 16),
              _buildStatItem(
                  theme,
                  '지원 프리셋',
                  '${supportedRanges.length} / ${_fpsRanges!.length}',
                  const Color(0xFF66BB6A)),
              const SizedBox(width: 16),
              _buildStatItem(
                  theme,
                  '카테고리',
                  _getMaxCategory(maxFps),
                  _getCategoryColor(maxFps)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      ThemeData theme, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Colors.redAccent, size: 64),
            const SizedBox(height: 16),
            Text(
              '오류 발생',
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? '알 수 없는 오류',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.white54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _startAnalysis,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }

  String _getMaxCategory(double maxFps) {
    if (maxFps >= 240) return '초고속';
    if (maxFps >= 120) return '슬로우-Mo';
    if (maxFps >= 60) return 'HFR';
    if (maxFps >= 30) return '표준';
    return '저속';
  }

  Color _getCategoryColor(double maxFps) {
    if (maxFps >= 240) return const Color(0xFFE91E63);
    if (maxFps >= 120) return const Color(0xFFFF5722);
    if (maxFps >= 60) return const Color(0xFF4CAF50);
    if (maxFps >= 30) return const Color(0xFF2196F3);
    return const Color(0xFF9E9E9E);
  }

  void _navigateToDetail() {
    if (_fpsRanges == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ResultDetailScreen(
          camera: widget.camera,
          fpsRanges: _fpsRanges!,
        ),
      ),
    );
  }
}
