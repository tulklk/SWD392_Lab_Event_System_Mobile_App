import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'auth_controller.dart';
import '../../domain/enums/role.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final authController = ref.read(authControllerProvider.notifier);
    
    final result = await authController.login(
      username: _usernameController.text.trim(),
      password: _passwordController.text.trim(),
    );

    setState(() {
      _isLoading = false;
    });

    if (result.isSuccess) {
      if (mounted) {
        // Redirect based on user role
        final user = result.data;
        if (user != null) {
          debugPrint('🚀 LoginScreen: Redirecting user after login');
          debugPrint('   Email: ${user.email}');
          debugPrint('   Role: ${user.role.name}');
          debugPrint('   Redirect to: ${user.role == Role.admin ? "/admin" : user.role == Role.lecturer ? "/lecturer" : "/home"}');
          
          // Redirect directly to appropriate page
          switch (user.role) {
            case Role.admin:
              context.go('/admin');
              break;
            case Role.lecturer:
              context.go('/lecturer');
              break;
            case Role.student:
            default:
              context.go('/home');
              break;
          }
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error!),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isGoogleLoading = true;
    });

    final authController = ref.read(authControllerProvider.notifier);
    
    final result = await authController.signInWithGoogle();

    setState(() {
      _isGoogleLoading = false;
    });

    if (result.isSuccess) {
      if (mounted) {
        // Redirect based on user role
        final user = result.data;
        if (user != null) {
          debugPrint('🚀 LoginScreen: Redirecting user after Google Sign-In');
          debugPrint('   Email: ${user.email}');
          debugPrint('   Role: ${user.role.name}');
          debugPrint('   Redirect to: ${user.role == Role.admin ? "/admin" : user.role == Role.lecturer ? "/lecturer" : "/home"}');
          
          // Redirect directly to appropriate page
          switch (user.role) {
            case Role.admin:
              context.go('/admin');
              break;
            case Role.lecturer:
              context.go('/lecturer');
              break;
            case Role.student:
            default:
              context.go('/home');
              break;
          }
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error!),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  
                  // FPT Logo
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6600).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        'assets/images/fpt_logo.png',
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.school,
                            size: 60,
                            color: Color(0xFFFF6600),
                          );
                        },
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Title
                  const Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                      letterSpacing: -0.5,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Subtitle
                  Text(
                    'Welcome to FPT Lab Events System',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Username field
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Username',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _usernameController,
                        keyboardType: TextInputType.text,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter your username',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 15,
                            fontWeight: FontWeight.normal,
                          ),
                          prefixIcon: Icon(
                            Icons.person_outline,
                            color: Colors.grey[500],
                            size: 22,
                          ),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
                            borderRadius: const BorderRadius.all(Radius.circular(12)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
                            borderRadius: const BorderRadius.all(Radius.circular(12)),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFFFF6600), width: 2),
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.red[400]!, width: 1.5),
                            borderRadius: const BorderRadius.all(Radius.circular(12)),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.red[400]!, width: 2),
                            borderRadius: const BorderRadius.all(Radius.circular(12)),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your username';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Password field
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Password',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter your password',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 15,
                            fontWeight: FontWeight.normal,
                          ),
                          prefixIcon: Icon(
                            Icons.lock_outline,
                            color: Colors.grey[500],
                            size: 22,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: Colors.grey[500],
                              size: 22,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
                            borderRadius: const BorderRadius.all(Radius.circular(12)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
                            borderRadius: const BorderRadius.all(Radius.circular(12)),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFFFF6600), width: 2),
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.red[400]!, width: 1.5),
                            borderRadius: const BorderRadius.all(Radius.circular(12)),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.red[400]!, width: 2),
                            borderRadius: const BorderRadius.all(Radius.circular(12)),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Forgot password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // TODO: Implement forgot password
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Forgot password feature coming soon!'),
                            backgroundColor: Color(0xFFFF6600),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: Color(0xFFFF6600),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6600),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[300],
                        disabledForegroundColor: Colors.grey[500],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                        shadowColor: const Color(0xFFFF6600).withOpacity(0.3),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'Log In',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Divider with OR
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: Colors.grey[300],
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: Colors.grey[300],
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Google Sign In Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: _isGoogleLoading
                        ? Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey[300]!, width: 1.5),
                            ),
                            child: const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Color(0xFFFF6600),
                                ),
                              ),
                            ),
                          )
                        : OutlinedButton(
                            onPressed: _handleGoogleSignIn,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF1E293B),
                              side: BorderSide(color: Colors.grey[300]!, width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Google Icon - Using image asset
                                SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: Image.asset(
                                    'assets/images/google_icon.png',
                                    width: 28,
                                    height: 28,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      // Fallback: Try with space in filename
                                      return Image.asset(
                                        'assets/images/google icon.png',
                                        width: 28,
                                        height: 28,
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error2, stackTrace2) {
                                          // Last fallback to custom painted icon
                                          return CustomPaint(
                                            size: const Size(28, 28),
                                            painter: GoogleIconPainter(),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'Continue with Google',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

// Custom painter to draw Google "G" icon exactly like the official logo
class GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;
    final innerRadius = size.width / 3.2;
    
    final paint = Paint()..style = PaintingStyle.fill;

    // Helper function to draw an arc segment
    void drawSegment(Color color, double startAngle, double sweepAngle) {
      paint.color = color;
      final path = Path();
      
      // Outer arc
      path.arcTo(
        Rect.fromCircle(center: center, radius: outerRadius),
        startAngle,
        sweepAngle,
        false,
      );
      
      // Connect to inner arc
      final endAngle = startAngle + sweepAngle;
      path.lineTo(
        center.dx + innerRadius * cos(endAngle),
        center.dy + innerRadius * sin(endAngle),
      );
      
      // Inner arc (reverse direction)
      path.arcTo(
        Rect.fromCircle(center: center, radius: innerRadius),
        endAngle,
        -sweepAngle,
        false,
      );
      
      path.close();
      canvas.drawPath(path, paint);
    }

    // Convert degrees to radians
    double toRadians(double degrees) => degrees * pi / 180;

    // 1. Blue segment (right side) - from -45° to 135° (180 degrees)
    drawSegment(
      const Color(0xFF4285F4),
      toRadians(-45),
      toRadians(180),
    );

    // 2. Red segment (top) - from 135° to 225° (90 degrees)
    drawSegment(
      const Color(0xFFEA4335),
      toRadians(135),
      toRadians(90),
    );

    // 3. Yellow segment (left) - from 225° to 315° (90 degrees)
    drawSegment(
      const Color(0xFFFBBC05),
      toRadians(225),
      toRadians(90),
    );

    // 4. Green segment (bottom) - from 315° to 405° (90 degrees)
    drawSegment(
      const Color(0xFF34A853),
      toRadians(315),
      toRadians(90),
    );

    // 5. Draw the blue horizontal bar (makes the "G" shape)
    paint.color = const Color(0xFF4285F4);
    final barHeight = (outerRadius - innerRadius) * 0.95;
    final barWidth = outerRadius * 0.8;
    final barPath = Path();
    
    // Start from center right
    barPath.moveTo(center.dx, center.dy - barHeight / 2);
    barPath.lineTo(center.dx + barWidth, center.dy - barHeight / 2);
    barPath.lineTo(center.dx + barWidth, center.dy + barHeight / 2);
    barPath.lineTo(center.dx, center.dy + barHeight / 2);
    barPath.close();
    
    canvas.drawPath(barPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}