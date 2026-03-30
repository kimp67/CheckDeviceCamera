import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'camera_inspector_screen.dart';

class HomeScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const HomeScreen({super.key, required this.cameras});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A0A0F),
              Color(0xFF0D1B3E),
              Color(0xFF0A0A0F),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                _buildHeader(theme),
                const SizedBox(height: 48),
                _buildCameraList(theme),
                const SizedBox(height: 32),
                _buildInfoSection(theme),
                const Spacer(),
                _buildFooter(theme),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF42A5F5).withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.camera_enhance_rounded,
                      color: Color(0xFF42A5F5),
                      size: 28,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Camera FPS',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    'Inspector',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: const Color(0xFF42A5F5),
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                      height: 0.9,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1A237E).withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF3949AB).withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.speed_rounded,
                color: Color(0xFF7986CB),
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                '기기 카메라의 FPS 범위를 분석합니다',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF9FA8DA),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCameraList(ThemeData theme) {
    if (widget.cameras.isEmpty) {
      return _buildNoCameraCard(theme);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '감지된 카메라',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${widget.cameras.length}개',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...widget.cameras.asMap().entries.map((entry) {
          final index = entry.key;
          final camera = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildCameraCard(theme, camera, index),
          );
        }),
      ],
    );
  }

  Widget _buildCameraCard(
      ThemeData theme, CameraDescription camera, int index) {
    final isBack = camera.lensDirection == CameraLensDirection.back;
    final isFront = camera.lensDirection == CameraLensDirection.front;
    final icon = isBack
        ? Icons.camera_rear_rounded
        : isFront
            ? Icons.camera_front_rounded
            : Icons.usb_rounded;

    final gradientColors = isBack
        ? [const Color(0xFF1565C0), const Color(0xFF0D47A1)]
        : isFront
            ? [const Color(0xFF6A1B9A), const Color(0xFF4A148C)]
            : [const Color(0xFF2E7D32), const Color(0xFF1B5E20)];

    final directionLabel = isBack
        ? '후면 카메라'
        : isFront
            ? '전면 카메라'
            : '외부 카메라';

    return InkWell(
      onTap: () => _navigateToInspector(camera),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              gradientColors[0].withValues(alpha: 0.3),
              gradientColors[1].withValues(alpha: 0.2),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: gradientColors[0].withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: gradientColors[0].withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    directionLabel,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Camera ${index + 1}  •  ${camera.name}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white54,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white70,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoCameraCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.no_photography_rounded,
              color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(
            '카메라를 찾을 수 없습니다',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '기기에 카메라가 없거나 카메라 권한이 거부되었습니다.',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white54),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FPS 범주 안내',
          style: theme.textTheme.titleSmall?.copyWith(
            color: Colors.white54,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildFpsChip(theme, '≥240', '초고속', const Color(0xFFE91E63)),
            const SizedBox(width: 8),
            _buildFpsChip(theme, '≥120', '슬로우모션', const Color(0xFFFF5722)),
            const SizedBox(width: 8),
            _buildFpsChip(theme, '≥60', '고프레임률', const Color(0xFF4CAF50)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildFpsChip(theme, '≥30', '표준', const Color(0xFF2196F3)),
            const SizedBox(width: 8),
            _buildFpsChip(theme, '<30', '저프레임률', const Color(0xFF9E9E9E)),
          ],
        ),
      ],
    );
  }

  Widget _buildFpsChip(
      ThemeData theme, String fps, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$fps fps  $label',
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(ThemeData theme) {
    return Center(
      child: Text(
        'camera ^0.12.0+1 | Flutter',
        style: theme.textTheme.bodySmall?.copyWith(
          color: Colors.white24,
        ),
      ),
    );
  }

  void _navigateToInspector(CameraDescription camera) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CameraInspectorScreen(camera: camera),
      ),
    );
  }
}
