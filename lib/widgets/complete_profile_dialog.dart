// ignore_for_file: deprecated_member_use

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pinput/pinput.dart';

import '../constants/app_colors.dart';
import '../features/profile/models/api_response_model.dart';
import '../features/profile/repositories/profile_repository.dart';
import '../firebase/explicit_firebase_options.dart';
import 'app_snackbar.dart';
import 'custom_elevated_button.dart';

class CompleteProfileDialog extends StatefulWidget {
  const CompleteProfileDialog({
    super.key,
    this.onCompleted,
  });

  final VoidCallback? onCompleted;

  @override
  State<CompleteProfileDialog> createState() => _CompleteProfileDialogState();
}

enum _ProfileStep { details, otp, done }

class _CompleteProfileDialogState extends State<CompleteProfileDialog> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();

  final _emailFocus = FocusNode();
  final _otpFocus = FocusNode();

  _ProfileStep _step = _ProfileStep.details;
  bool _isSubmitting = false;
  bool _otpVerified = false;
  bool _googleInitialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _otpController.dispose();
    _emailFocus.dispose();
    _otpFocus.dispose();
    super.dispose();
  }

  bool _isValidEmail(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return false;
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(trimmed);
  }

  Future<void> _ensureFirebaseInitialized() async {
    if (Firebase.apps.isNotEmpty) return;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await Firebase.initializeApp(
        options: ExplicitFirebaseOptions.androidErupiya,
      );
      return;
    }
    await Firebase.initializeApp();
  }

  Future<void> _continueWithGoogle() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await _ensureFirebaseInitialized();
      if (!mounted) return;
      if (!_googleInitialized) {
        await GoogleSignIn.instance.initialize();
        _googleInitialized = true;
      }

      final googleUser = await GoogleSignIn.instance.authenticate(
        scopeHint: const ['email'],
      );
      if (!mounted) return;

      final idToken = googleUser.authentication.idToken;
      if (idToken == null || idToken.trim().isEmpty) {
        AppSnackbar.show('Unable to fetch Google idToken. Please try again.');
        return;
      }
      final authz = await googleUser.authorizationClient.authorizeScopes(
        const ['email'],
      );
      if (!mounted) return;
      final credential = GoogleAuthProvider.credential(
        accessToken: authz.accessToken,
        idToken: idToken,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      if (!mounted) return;
      final user = userCredential.user;
      final name = (user?.displayName ?? '').trim();
      final email = (user?.email ?? '').trim();
      final firebaseIdToken = await user?.getIdToken(true);
      if (!mounted) return;

      if (name.isEmpty || email.isEmpty) {
        AppSnackbar.show(
          'Unable to fetch name/email from Google. Please try again.',
        );
        return;
      }
      if (firebaseIdToken == null || firebaseIdToken.trim().isEmpty) {
        AppSnackbar.show('Unable to fetch idToken. Please try again.');
        return;
      }

      _nameController.text = name;
      _emailController.text = email;

      final repo = ProfileRepository();
      final ApiResponse resp = await repo.completeProfile(
        name: name,
        email: email,
        type: 'google',
        googleToken: firebaseIdToken,
      );
      if (!mounted) return;
      if (!resp.success) {
        AppSnackbar.show(
          resp.message.isNotEmpty ? resp.message : 'Google sign-in failed',
        );
        return;
      }

      setState(() => _step = _ProfileStep.done);
      AppSnackbar.show(
        resp.message.isNotEmpty
            ? resp.message
            : 'Profile completed successfully',
        backgroundColor: AppColors.primary,
        textColor: Colors.white,
      );
    } catch (e) {
      final message = _friendlyGoogleErrorMessage(e);
      if (message != null && message.trim().isNotEmpty) {
        AppSnackbar.show(message);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String? _friendlyGoogleErrorMessage(Object error) {
    if (error is FirebaseAuthException) {
      return (error.message ?? '').trim().isNotEmpty
          ? error.message
          : 'Google sign-in failed. Please try again.';
    }

    if (error is PlatformException) {
      // Common cases: user cancellation / in-progress sign-in.
      final code = (error.code).toLowerCase();
      if (code.contains('canceled') || code.contains('cancelled')) {
        return null; // user backed out: don't show as an error
      }
      if (code.contains('sign_in_canceled') ||
          code.contains('sign_in_cancel')) {
        return null;
      }
      if (code.contains('network') || code.contains('network_error')) {
        return 'Network error during Google sign-in. Please try again.';
      }
      if ((error.message ?? '').trim().isNotEmpty) return error.message;
    }

    return 'Google sign-in failed. Please try again.';
  }

  Future<void> _sendOtp() async {
    if (_isSubmitting) return;
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    if (name.isEmpty) {
      AppSnackbar.show('Please enter your name');
      return;
    }
    if (!_isValidEmail(email)) {
      AppSnackbar.show('Please enter a valid email');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _otpVerified = false;
    });
    try {
      final repo = ProfileRepository();
      final ApiResponse resp = await repo.completeProfile(
        name: name,
        email: email,
        type: 'manual',
      );
      if (!mounted) return;
      if (!resp.success) {
        AppSnackbar.show(
          resp.message.isNotEmpty ? resp.message : 'Failed to send OTP',
        );
        return;
      }
      setState(() => _step = _ProfileStep.otp);
      _otpController.clear();
      _otpFocus.requestFocus();
      AppSnackbar.show(
        resp.message.isNotEmpty ? resp.message : 'OTP sent to $email',
        backgroundColor: AppColors.primary,
        textColor: Colors.white,
      );
    } catch (e) {
      AppSnackbar.show('Failed to send OTP. Please try again.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (_isSubmitting) return;
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      AppSnackbar.show('Please enter the 6-digit OTP');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final repo = ProfileRepository();
      final ApiResponse resp = await repo.verifyCompleteProfileOtp(otp: otp);
      if (!mounted) return;
      if (!resp.success) {
        AppSnackbar.show(
          resp.message.isNotEmpty ? resp.message : 'OTP verification failed',
        );
        return;
      }
      setState(() => _otpVerified = true);

      setState(() => _step = _ProfileStep.done);
    } catch (_) {
      AppSnackbar.show('OTP verification failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _headerIcon() {
    switch (_step) {
      case _ProfileStep.details:
        return Container(
          width: 54.r,
          height: 54.r,
          decoration: const BoxDecoration(
            color: Color(0xFF0B8F3A),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person, color: Colors.white, size: 30),
        );
      case _ProfileStep.otp:
        return Container(
          width: 54.r,
          height: 54.r,
          decoration: BoxDecoration(
            color: const Color(0xFF0B8F3A).withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF0B8F3A), width: 2),
          ),
          child: const Icon(Icons.shield, color: Color(0xFF0B8F3A), size: 28),
        );
      case _ProfileStep.done:
        return Container(
          width: 70.r,
          height: 70.r,
          decoration: const BoxDecoration(
            color: Color(0xFF0B8F3A),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, color: Colors.white, size: 40),
        );
    }
  }

  Widget _dividerOr() {
    return Row(
      children: [
        Expanded(
            child: Divider(color: AppColors.textPrimary.withOpacity(0.18))),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Text(
            'or',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary.withOpacity(0.55),
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Expanded(
            child: Divider(color: AppColors.textPrimary.withOpacity(0.18))),
      ],
    );
  }

  Widget _googleButton() {
    return SizedBox(
      width: double.infinity,
      height: 44.h,
      child: OutlinedButton(
        onPressed: _isSubmitting ? null : _continueWithGoogle,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.textPrimary.withOpacity(0.12)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Simple "G" mark without extra assets.
            Text(
              'G',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w900,
                color: Colors.blue.shade700,
              ),
            ),
            SizedBox(width: 10.w),
            Text(
              'Continue with Google',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary.withOpacity(0.7),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Complete Your Profile',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
        ),
        SizedBox(height: 8.h),
        Text(
          'Please enter your name and\nemail ID to continue.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary.withOpacity(0.8),
                height: 1.25,
              ),
        ),
        SizedBox(height: 18.h),
        Text(
          'Enter Your Name',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
        ),
        SizedBox(height: 8.h),
        _InputBox(
          controller: _nameController,
          enabled: !_isSubmitting,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => _emailFocus.requestFocus(),
          hintText: 'Name',
        ),
        SizedBox(height: 16.h),
        Text(
          'Enter Your Email',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
        ),
        SizedBox(height: 8.h),
        _InputBox(
          controller: _emailController,
          focusNode: _emailFocus,
          enabled: !_isSubmitting,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _sendOtp(),
          hintText: 'email@example.com',
        ),
        SizedBox(height: 18.h),
        CustomElevatedButton(
          onPressed: _isSubmitting ? null : _sendOtp,
          label: _isSubmitting ? 'Please wait...' : 'Continue',
          uppercaseLabel: false,
          height: 44.h,
        ),
        SizedBox(height: 14.h),
        _dividerOr(),
        SizedBox(height: 14.h),
        _googleButton(),
      ],
    );
  }

  Widget _otpStep() {
    final email = _emailController.text.trim();
    final pinTheme = PinTheme(
      width: 58.w,
      height: 52.w,
      textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFF0B8F3A)),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verify OTP',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
        ),
        SizedBox(height: 8.h),
        Text(
          'Enter the 6-digit OTP sent to $email\nemail ID.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary.withOpacity(0.8),
                height: 1.25,
              ),
        ),
        SizedBox(height: 18.h),
        Pinput(
          controller: _otpController,
          focusNode: _otpFocus,
          length: 6,
          enabled: !_isSubmitting,
          keyboardType: TextInputType.number,
          defaultPinTheme: pinTheme,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onCompleted: (_) => _verifyOtp(),
        ),
        SizedBox(height: 12.h),
        if (_otpVerified)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
            decoration: BoxDecoration(
              color: const Color(0xFF0B8F3A).withOpacity(0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified, color: Color(0xFF0B8F3A), size: 18),
                SizedBox(width: 6.w),
                Text(
                  'OTP Verified',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF0B8F3A),
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
          ),
        SizedBox(height: 18.h),
        CustomElevatedButton(
          onPressed: _isSubmitting ? null : _verifyOtp,
          label: _isSubmitting ? 'Verifying...' : 'Verify OTP',
          uppercaseLabel: false,
          height: 44.h,
        ),
      ],
    );
  }

  Widget _doneStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Profile setup is\ncompleted',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
        ),
        SizedBox(height: 10.h),
        Text(
          'Your details have been verified successfully.\nYou can now continue using the app.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary.withOpacity(0.7),
                height: 1.25,
              ),
        ),
        SizedBox(height: 18.h),
        CustomElevatedButton(
          onPressed: () {
            widget.onCompleted?.call();
            Navigator.of(context).pop();
          },
          label: 'Continue',
          uppercaseLabel: false,
          height: 44.h,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget content;
    switch (_step) {
      case _ProfileStep.details:
        content = _detailsStep();
        break;
      case _ProfileStep.otp:
        content = _otpStep();
        break;
      case _ProfileStep.done:
        content = _doneStep();
        break;
    }

    return WillPopScope(
      onWillPop: () async => false,
      child: Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: 18.w),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(22.r)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22.r),
          child: Container(
            padding: EdgeInsets.fromLTRB(22.w, 18.h, 22.w, 18.h),
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: _step == _ProfileStep.done
                      ? Alignment.center
                      : Alignment.centerLeft,
                  child: _headerIcon(),
                ),
                SizedBox(height: 12.h),
                content,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InputBox extends StatelessWidget {
  const _InputBox({
    required this.controller,
    this.focusNode,
    required this.enabled,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.hintText,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool enabled;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: AppColors.textPrimary.withOpacity(0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: AppColors.textPrimary.withOpacity(0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
        ),
      ),
    );
  }
}
