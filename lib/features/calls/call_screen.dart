// lib/features/calls/call_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/neon_widgets.dart';

enum CallType { voice, video }
enum CallState { ringing, connected, ended }

class CallScreen extends StatefulWidget {
  final String otherUserName;
  final String? otherUserAvatar;
  final CallType callType;
  final bool isIncoming;

  const CallScreen({
    super.key,
    required this.otherUserName,
    this.otherUserAvatar,
    this.callType = CallType.voice,
    this.isIncoming = false,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen>
    with SingleTickerProviderStateMixin {
  CallState _state = CallState.ringing;
  bool _muted = false;
  bool _speakerOn = false;
  bool _cameraOn = true;
  Duration _duration = Duration.zero;
  Timer? _timer;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    if (!widget.isIncoming) _simulateConnect();
  }

  void _simulateConnect() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _state = CallState.connected);
        _startTimer();
        HapticFeedback.mediumImpact();
      }
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _duration += const Duration(seconds: 1));
    });
  }

  void _accept() {
    setState(() => _state = CallState.connected);
    _startTimer();
    HapticFeedback.mediumImpact();
  }

  void _endCall() {
    _timer?.cancel();
    setState(() => _state = CallState.ended);
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  String get _durationStr {
    final m = _duration.inMinutes.toString().padLeft(2, '0');
    final s = (_duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Animated background
          _buildBackground(),
          // Content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 40),
                _buildCallerInfo(),
                const Spacer(),
                _buildCallStatus(),
                const Spacer(),
                _buildControls(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topCenter,
          radius: 1.5,
          colors: [
            _state == CallState.connected
                ? const Color(0xFF001A08)
                : const Color(0xFF1A0008),
            AppColors.background,
          ],
        ),
      ),
    );
  }

  Widget _buildCallerInfo() {
    return Column(
      children: [
        // Avatar with pulse ring
        AnimatedBuilder(
          animation: _pulse,
          builder: (ctx, child) {
            return Transform.scale(
              scale: _state == CallState.ringing ? _pulse.value : 1.0,
              child: child,
            );
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_state == CallState.ringing)
                ...List.generate(3, (i) {
                  return Container(
                    width: 90.0 + i * 30,
                    height: 90.0 + i * 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.neonRed.withOpacity(0.3 - i * 0.08),
                        width: 1.5,
                      ),
                    ),
                  );
                }),
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _state == CallState.connected
                        ? AppColors.online
                        : AppColors.neonRed,
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_state == CallState.connected
                              ? AppColors.online
                              : AppColors.neonRed)
                          .withOpacity(0.3),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Container(
                    color: AppColors.surfaceLight,
                    child: Center(
                      child: Text(
                        widget.otherUserName.isNotEmpty
                            ? widget.otherUserName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: AppColors.silver,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          widget.otherUserName,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.callType == CallType.video
              ? 'مكالمة فيديو'
              : 'مكالمة صوتية',
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildCallStatus() {
    String statusText;
    Color statusColor;

    switch (_state) {
      case CallState.ringing:
        statusText = widget.isIncoming ? 'مكالمة واردة...' : 'جاري الاتصال...';
        statusColor = AppColors.silver;
        break;
      case CallState.connected:
        statusText = _durationStr;
        statusColor = AppColors.online;
        break;
      case CallState.ended:
        statusText = 'انتهت المكالمة';
        statusColor = AppColors.neonRed;
        break;
    }

    return Text(
      statusText,
      style: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: statusColor,
        shadows: [
          Shadow(blurRadius: 8, color: statusColor.withOpacity(0.5)),
        ],
      ),
    );
  }

  Widget _buildControls() {
    if (_state == CallState.ringing && widget.isIncoming) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _CallBtn(
            icon: Icons.call_end_rounded,
            color: AppColors.neonRed,
            label: 'رفض',
            onTap: _endCall,
          ),
          _CallBtn(
            icon: Icons.call_rounded,
            color: AppColors.online,
            label: 'قبول',
            onTap: _accept,
          ),
        ],
      );
    }

    return Column(
      children: [
        // Top row controls
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _SmallBtn(
              icon: _muted ? Icons.mic_off_rounded : Icons.mic_rounded,
              label: _muted ? 'كتم' : 'ميكروفون',
              active: _muted,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _muted = !_muted);
              },
            ),
            _SmallBtn(
              icon: _speakerOn ? Icons.volume_up_rounded : Icons.volume_down_rounded,
              label: 'سماعة',
              active: _speakerOn,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _speakerOn = !_speakerOn);
              },
            ),
            if (widget.callType == CallType.video)
              _SmallBtn(
                icon: _cameraOn ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                label: 'كاميرا',
                active: !_cameraOn,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _cameraOn = !_cameraOn);
                },
              ),
            _SmallBtn(
              icon: Icons.flip_camera_ios_rounded,
              label: 'تبديل',
              active: false,
              onTap: () => HapticFeedback.selectionClick(),
            ),
          ],
        ),
        const SizedBox(height: 30),
        // End call
        _CallBtn(
          icon: Icons.call_end_rounded,
          color: AppColors.neonRed,
          label: 'إنهاء',
          onTap: _endCall,
          size: 70,
        ),
      ],
    );
  }
}

class _CallBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;
  final double size;

  const _CallBtn({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
    this.size = 65,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: size * 0.42),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _SmallBtn({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active
                  ? AppColors.neonRed.withOpacity(0.15)
                  : AppColors.glassFill,
              border: Border.all(
                color: active
                    ? AppColors.neonRed.withOpacity(0.5)
                    : AppColors.glassBorder,
              ),
            ),
            child: Icon(
              icon,
              color: active ? AppColors.neonRed : AppColors.silver,
              size: 22,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 10,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
