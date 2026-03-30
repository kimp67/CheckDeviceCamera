import 'package:flutter/material.dart';
import '../models/fps_range_model.dart';

/// FPS 범위를 막대 차트로 시각화하는 위젯
class FpsBarChart extends StatelessWidget {
  final List<FpsRangeInfo> fpsRanges;
  final bool showTitle;

  const FpsBarChart({
    super.key,
    required this.fpsRanges,
    this.showTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final supportedRanges = fpsRanges.where((r) => r.isSupported).toList();

    if (supportedRanges.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxFps = supportedRanges
        .map((r) => r.maxFps)
        .reduce((a, b) => a > b ? a : b);

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
          if (showTitle) ...[
            Row(
              children: [
                const Icon(Icons.bar_chart_rounded,
                    color: Color(0xFF42A5F5), size: 20),
                const SizedBox(width: 8),
                Text(
                  'FPS 비교 차트',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          // 차트 영역
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Y축 레이블
                SizedBox(
                  width: 36,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${maxFps.toStringAsFixed(0)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white38,
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        '${(maxFps * 0.75).toStringAsFixed(0)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white38,
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        '${(maxFps * 0.5).toStringAsFixed(0)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white38,
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        '${(maxFps * 0.25).toStringAsFixed(0)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white38,
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        '0',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white38,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // 차트 바
                Expanded(
                  child: Stack(
                    children: [
                      // 격자선
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(
                          5,
                          (i) => Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    width: 1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // 바 차트
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: fpsRanges.map((range) {
                          return Expanded(
                            child: _buildBar(theme, range, maxFps),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // X축 레이블
          Row(
            children: [
              const SizedBox(width: 44),
              ...fpsRanges.map((range) {
                return Expanded(
                  child: Text(
                    range.resolutionPreset.name,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white38,
                      fontSize: 9,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 12),
          // 범례
          _buildLegend(theme),
        ],
      ),
    );
  }

  Widget _buildBar(ThemeData theme, FpsRangeInfo range, double maxFps) {
    if (!range.isSupported || maxFps == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ),
          ],
        ),
      );
    }

    final barHeight = (range.maxFps / maxFps) * 140;
    final color = _fpsColor(range.maxFps);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // FPS 값 레이블 (바 위)
          if (barHeight > 20)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                range.maxFps.toStringAsFixed(0),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 9,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          // 막대
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            height: barHeight,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color,
                  color.withValues(alpha: 0.5),
                ],
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(4)),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 6,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(ThemeData theme) {
    final legends = [
      ('≥240 초고속', const Color(0xFFE91E63)),
      ('≥120 슬로우Mo', const Color(0xFFFF5722)),
      ('≥60 HFR', const Color(0xFF4CAF50)),
      ('≥30 표준', const Color(0xFF2196F3)),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: legends.map((l) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: l.$2,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              l.$1,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white38,
                fontSize: 10,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Color _fpsColor(double fps) {
    if (fps >= 240) return const Color(0xFFE91E63);
    if (fps >= 120) return const Color(0xFFFF5722);
    if (fps >= 60) return const Color(0xFF4CAF50);
    if (fps >= 30) return const Color(0xFF2196F3);
    return const Color(0xFF9E9E9E);
  }
}
