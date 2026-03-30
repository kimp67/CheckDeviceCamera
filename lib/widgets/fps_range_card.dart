import 'package:flutter/material.dart';
import '../models/fps_range_model.dart';

class FpsRangeCard extends StatelessWidget {
  final FpsRangeInfo fpsRange;
  final bool showDetails;

  const FpsRangeCard({
    super.key,
    required this.fpsRange,
    this.showDetails = false,
  });

  Color get _cardColor {
    if (!fpsRange.isSupported) return const Color(0xFF1A1A1A);
    final fps = fpsRange.maxFps;
    if (fps >= 240) return const Color(0xFF880E4F);
    if (fps >= 120) return const Color(0xFFBF360C);
    if (fps >= 60) return const Color(0xFF1B5E20);
    if (fps >= 30) return const Color(0xFF0D47A1);
    return const Color(0xFF212121);
  }

  Color get _accentColor {
    if (!fpsRange.isSupported) return Colors.grey;
    final fps = fpsRange.maxFps;
    if (fps >= 240) return const Color(0xFFE91E63);
    if (fps >= 120) return const Color(0xFFFF5722);
    if (fps >= 60) return const Color(0xFF4CAF50);
    if (fps >= 30) return const Color(0xFF2196F3);
    return const Color(0xFF9E9E9E);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _accentColor.withValues(alpha: fpsRange.isSupported ? 0.4 : 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 프리셋 배지
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _accentColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _accentColor.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  fpsRange.resolutionPreset.name,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: _accentColor,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  fpsRange.resolutionPreset.typicalResolution,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white54,
                  ),
                ),
              ),
              // 카테고리 태그
              if (fpsRange.isSupported)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    fpsRange.frameRateCategoryKo,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _accentColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (fpsRange.isSupported) ...[
            _buildFpsDisplay(theme),
            if (showDetails) ...[
              const SizedBox(height: 12),
              _buildFpsProgressBar(theme),
              const SizedBox(height: 8),
              _buildDetailRow(
                  theme, '해상도 레이블', fpsRange.label),
            ],
          ] else
            _buildUnsupportedDisplay(theme),
        ],
      ),
    );
  }

  Widget _buildFpsDisplay(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildFpsValue(
              theme, 'MIN', fpsRange.minFps, Colors.white60),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              Icon(Icons.arrow_forward_rounded,
                  color: _accentColor.withValues(alpha: 0.6), size: 18),
              Text(
                'FPS',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white30,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _buildFpsValue(
              theme, 'MAX', fpsRange.maxFps, _accentColor),
        ),
      ],
    );
  }

  Widget _buildFpsValue(
      ThemeData theme, String label, double fps, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.white38,
            letterSpacing: 1,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: fps.toStringAsFixed(fps == fps.roundToDouble() ? 0 : 1),
                style: theme.textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              TextSpan(
                text: ' fps',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: color.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFpsProgressBar(ThemeData theme) {
    const maxPossibleFps = 240.0;
    final progress = (fpsRange.maxFps / maxPossibleFps).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'FPS 수준',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.white38),
            ),
            Text(
              '${(progress * 100).toStringAsFixed(0)}% (최대 240 기준)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: _accentColor.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(ThemeData theme, String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.white38),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white60,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUnsupportedDisplay(ThemeData theme) {
    return Row(
      children: [
        const Icon(Icons.block_rounded, color: Colors.red, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            fpsRange.errorMessage ?? '이 기기에서 지원되지 않는 해상도',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.red.shade300,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
