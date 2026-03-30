import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import '../models/fps_range_model.dart';
import '../utils/camera_fps_analyzer.dart';
import '../widgets/fps_range_card.dart';
import '../widgets/fps_bar_chart.dart';

class ResultDetailScreen extends StatelessWidget {
  final CameraDescription camera;
  final List<FpsRangeInfo> fpsRanges;

  const ResultDetailScreen({
    super.key,
    required this.camera,
    required this.fpsRanges,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final directionLabel =
        CameraFpsAnalyzer.lensDirectionToKorean(camera.lensDirection);
    final supportedRanges = fpsRanges.where((r) => r.isSupported).toList();
    final maxFps = supportedRanges.isEmpty
        ? 0.0
        : supportedRanges.map((r) => r.maxFps).reduce((a, b) => a > b ? a : b);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        title: Text('$directionLabel 상세 결과'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_rounded),
            tooltip: '결과 복사',
            onPressed: () => _copyResults(context),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // 헤더 카드
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildHeaderCard(theme, directionLabel, maxFps),
            ),
          ),

          // 차트
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FpsBarChart(fpsRanges: fpsRanges, showTitle: true),
            ),
          ),

          // FPS 카테고리 분포
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildCategoryDistribution(theme, supportedRanges),
            ),
          ),

          // 프리셋별 상세 카드
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                '해상도 프리셋별 상세 정보',
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
                  child: FpsRangeCard(
                    fpsRange: fpsRanges[index],
                    showDetails: true,
                  ),
                );
              },
              childCount: fpsRanges.length,
            ),
          ),

          // 기술 정보
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildTechnicalInfo(theme),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(
      ThemeData theme, String directionLabel, double maxFps) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1565C0).withValues(alpha: 0.5),
            const Color(0xFF0D47A1).withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF42A5F5).withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                camera.lensDirection == CameraLensDirection.back
                    ? Icons.camera_rear_rounded
                    : camera.lensDirection == CameraLensDirection.front
                        ? Icons.camera_front_rounded
                        : Icons.usb_rounded,
                color: const Color(0xFF42A5F5),
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      directionLabel,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${camera.name}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white38,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white10),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetric(theme, '최대 FPS',
                  '${maxFps.toStringAsFixed(1)} fps', const Color(0xFF42A5F5)),
              _buildMetric(theme, '지원 프리셋',
                  '${fpsRanges.where((r) => r.isSupported).length}종', const Color(0xFF66BB6A)),
              _buildMetric(
                  theme,
                  '분석 항목',
                  '${fpsRanges.length}개',
                  const Color(0xFFFFB74D)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(
      ThemeData theme, String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.white38,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDistribution(
      ThemeData theme, List<FpsRangeInfo> supportedRanges) {
    final categories = <String, int>{};
    for (final range in supportedRanges) {
      final cat = range.frameRateCategoryKo;
      categories[cat] = (categories[cat] ?? 0) + 1;
    }

    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.donut_large_rounded,
                  color: Color(0xFF42A5F5), size: 18),
              const SizedBox(width: 8),
              Text(
                'FPS 범주 분포',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...categories.entries.map((e) {
            final color = _categoryColor(e.key);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    e.key,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${e.value}개 프리셋',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTechnicalInfo(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.code_rounded,
                  color: Color(0xFF42A5F5), size: 18),
              const SizedBox(width: 8),
              Text(
                '기술 정보',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTechItem(theme, '패키지', 'camera ^0.12.0+1'),
          _buildTechItem(theme, 'Android', 'CameraX (camera_android_camerax)'),
          _buildTechItem(theme, 'iOS', 'AVFoundation (camera_avfoundation)'),
          _buildTechItem(theme, 'FPS API', 'CameraValue.fps'),
          _buildTechItem(
              theme, '측정 방식', '각 ResolutionPreset 초기화 후 fps 값 수집'),
        ],
      ),
    );
  }

  Widget _buildTechItem(ThemeData theme, String key, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              key,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white38,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white70,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _categoryColor(String category) {
    switch (category) {
      case '초고속 촬영':
        return const Color(0xFFE91E63);
      case '슬로우 모션':
        return const Color(0xFFFF5722);
      case '고프레임률':
        return const Color(0xFF4CAF50);
      case '표준':
        return const Color(0xFF2196F3);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  Future<void> _copyResults(BuildContext context) async {
    final buffer = StringBuffer();
    buffer.writeln('=== Camera FPS Inspector 결과 ===');
    buffer.writeln(
        '카메라: ${CameraFpsAnalyzer.lensDirectionToKorean(camera.lensDirection)}');
    buffer.writeln('분석 시각: ${DateTime.now()}');
    buffer.writeln();

    for (final range in fpsRanges) {
      if (range.isSupported) {
        buffer.writeln(
            '[${range.resolutionPreset.name}] ${range.label}: min=${range.minFps.toStringAsFixed(1)} / max=${range.maxFps.toStringAsFixed(1)} fps | ${range.frameRateCategoryKo}');
      } else {
        buffer.writeln(
            '[${range.resolutionPreset.name}] 지원 안 됨: ${range.errorMessage}');
      }
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('결과가 클립보드에 복사되었습니다'),
          backgroundColor: Color(0xFF1565C0),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
