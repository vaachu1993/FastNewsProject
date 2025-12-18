import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../../services/otp_service.dart';
import '../../services/auth_service.dart';
import '../../providers/theme_provider.dart';
import '../profile/topics_selection_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final String password;
  final String name;

  const OtpVerificationScreen({
    super.key,
    required this.email,
    required this.password,
    required this.name,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpService = OtpService();
  final _authService = AuthService();
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  bool _isLoading = false;
  bool _isResending = false;
  int _remainingSeconds = 300; // 5 minutes
  Timer? _timer;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _startTimer();
    _checkRemainingTime();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();

    // ✅ KHÔNG hardcode 300, sẽ được set từ _checkRemainingTime()

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
        // Hiển thị thông báo khi hết hạn
        if (mounted) {
          setState(() {
            _errorMessage = 'Mã OTP đã hết hạn. Vui lòng gửi lại mã mới.';
          });
        }
      }
    });
  }

  Future<void> _checkRemainingTime() async {
    final duration = await _otpService.getRemainingTime(widget.email);
    if (duration != null && mounted) {
      setState(() {
        _remainingSeconds = duration.inSeconds;
      });
    } else {
      // Nếu không lấy được hoặc đã hết hạn, set về 0
      if (mounted) {
        setState(() {
          _remainingSeconds = 0;
          _errorMessage = 'Mã OTP đã hết hạn. Vui lòng gửi lại mã mới.';
        });
      }
    }
  }

  String get _timerText {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _verifyOtp() async {
    final otp = _controllers.map((c) => c.text).join();

    if (otp.length != 6) {
      setState(() => _errorMessage = 'Vui lòng nhập đầy đủ 6 số');
      return;
    }

    // ✅ Kiểm tra timer đã hết chưa trước khi verify
    if (_remainingSeconds <= 0) {
      setState(() => _errorMessage = 'Mã OTP đã hết hạn. Vui lòng gửi lại mã mới.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Verify OTP
      final result = await _otpService.verifyOtp(widget.email, otp);

      if (!mounted) return;

      if (result['success']) {
        // OTP correct, create Firebase account
        String? error = await _authService.signUpWithEmail(
          email: widget.email,
          password: widget.password,
          name: widget.name,
        );

        if (!mounted) return;

        if (error == null) {
          // Send welcome email
          _otpService.sendWelcomeEmail(widget.email, widget.name);

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Xác thực thành công! Chào mừng đến với FastNews'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          // Navigate to topics selection
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const TopicsSelectionScreen(),
            ),
            (route) => false,
          );
        } else {
          setState(() => _errorMessage = error);
        }
      } else {
        setState(() => _errorMessage = result['message']);
        _shakeAnimation();
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resendOtp() async {
    if (_isResending) return;

    setState(() {
      _isResending = true;
      _errorMessage = '';
    });

    try {
      final result = await _otpService.resendOtp(widget.email);

      if (!mounted) return;

      if (result['success']) {
        // ✅ Check thời gian thực tế từ backend trước khi start timer
        await _checkRemainingTime();
        _startTimer();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Mã OTP mới đã được gửi đến email của bạn'),
            backgroundColor: Colors.green,
          ),
        );

        // Clear all inputs
        for (var controller in _controllers) {
          controller.clear();
        }
        _focusNodes[0].requestFocus();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  void _shakeAnimation() {
    // Simple shake effect by clearing inputs
    for (var controller in _controllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDarkMode ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.blue.shade900.withOpacity(0.3) : Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mail_outline,
                  size: 50,
                  color: isDarkMode ? Colors.blue.shade300 : Colors.blue.shade600,
                ),
              ),

              const SizedBox(height: 30),

              // Title
              Text(
                'Xác Thực Email',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),

              const SizedBox(height: 12),

              // Description
              Text(
                'Chúng tôi đã gửi mã OTP gồm 6 chữ số đến',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.email,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.blue.shade300 : Colors.blue,
                ),
              ),

              const SizedBox(height: 40),

              // OTP Input Fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 50,
                    height: 60,
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDarkMode ? Colors.blue.shade300 : Colors.blue,
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.red, width: 2),
                        ),
                        filled: true,
                        fillColor: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 5) {
                          _focusNodes[index + 1].requestFocus();
                        } else if (value.isEmpty && index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        }

                        // Auto verify when all filled
                        if (index == 5 && value.isNotEmpty) {
                          _verifyOtp();
                        }

                        setState(() => _errorMessage = '');
                      },
                    ),
                  );
                }),
              ),

              const SizedBox(height: 20),

              // Error message
              if (_errorMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.red.shade900.withOpacity(0.3) : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDarkMode ? Colors.red.shade700 : Colors.red.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: isDarkMode ? Colors.red.shade300 : Colors.red.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage,
                          style: TextStyle(
                            color: isDarkMode ? Colors.red.shade300 : Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // Timer
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _remainingSeconds > 0
                      ? (isDarkMode ? Colors.blue.shade900.withOpacity(0.3) : Colors.blue.shade50)
                      : (isDarkMode ? Colors.red.shade900.withOpacity(0.3) : Colors.red.shade50),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 18,
                      color: _remainingSeconds > 0
                          ? (isDarkMode ? Colors.blue.shade300 : Colors.blue)
                          : (isDarkMode ? Colors.red.shade300 : Colors.red),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _remainingSeconds > 0
                          ? 'Mã hết hạn sau $_timerText'
                          : 'Mã đã hết hạn',
                      style: TextStyle(
                        color: _remainingSeconds > 0
                            ? (isDarkMode ? Colors.blue.shade300 : Colors.blue)
                            : (isDarkMode ? Colors.red.shade300 : Colors.red),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Verify Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Xác Thực',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              // Resend OTP
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Không nhận được mã? ',
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                  TextButton(
                    onPressed: _isResending ? null : _resendOtp,
                    child: _isResending
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Gửi lại',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Help text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                      size: 20,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Kiểm tra cả thư mục Spam nếu không thấy email',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                        fontSize: 13,
                      ),
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

