import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/app_theme.dart';

// Splash & Onboarding
import 'features/splash/splash_screen.dart';
import 'features/splash/onboarding_screen.dart';

// Authentication
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/otp_screen.dart';
import 'features/auth/screens/signup_screen.dart';
import 'features/auth/screens/forgot_password_screen.dart';

// Home & Common
import 'features/home/screens/home_screen.dart';
import 'features/common/screens/my_trips_screen.dart';
import 'features/common/screens/profile_screen.dart';
import 'features/common/screens/chat_screen.dart';
import 'features/common/screens/support_screen.dart';
import 'features/common/screens/subscription_screen.dart';
import 'features/common/screens/legal_content_screen.dart';
import 'features/common/screens/wallet_screen.dart';

// Rider Flow
import 'features/rides/screens/search_ride_screen.dart';
import 'features/rides/screens/ride_results_screen.dart';
import 'features/rides/screens/ride_detail_screen.dart';
import 'features/rides/screens/payment_screen.dart';
import 'features/rides/screens/booking_success_screen.dart';
import 'features/rides/screens/track_ride_screen.dart';
import 'features/rides/screens/rating_screen.dart';

// Driver Flow
import 'features/driver/screens/driver_hub.dart';
import 'features/driver/screens/driver_request_screen.dart';
import 'features/driver/screens/active_trip_screen.dart';
import 'features/driver/screens/driver_registration_screen.dart';
import 'features/driver/screens/driver_registration_form_screen.dart';
import 'features/driver/screens/create_ride_screen.dart';
import 'features/driver/screens/ride_bookings_screen.dart';

// ✅ NEW SCREENS (add these files)
import 'features/driver/screens/start_ride_screen.dart';
import 'features/driver/screens/ride_map_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "assets/.env");
  runApp(const DriveOnApp());
}

class DriveOnApp extends StatelessWidget {
  const DriveOnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ryndo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/forgot_password': (context) => const ForgotPasswordScreen(),
        '/otp_verify': (context) => const OtpScreen(),

        '/home': (context) => const HomeScreen(),
        '/my_trips': (context) => const MyTripsScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/chat': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final bookingId = (args is Map ? args['bookingId']?.toString() : null) ?? '';
          final name = (args is Map ? args['otherPersonName']?.toString() : null) ?? 'User';
          final role = (args is Map ? args['otherPersonRole']?.toString() : null) ?? '';
          return ChatScreen(bookingId: bookingId, otherPersonName: name, otherPersonRole: role);
        },
        '/support': (context) => const SupportScreen(),
        '/subscription': (context) => const SubscriptionScreen(),
        '/wallet': (context) => const WalletScreen(),
        '/privacy_policy': (context) => const LegalContentScreen(type: 'PRIVACY_POLICY', title: 'Privacy Policy'),
        '/terms_and_conditions': (context) => const LegalContentScreen(type: 'TERMS_AND_CONDITIONS', title: 'Terms & Conditions'),

        '/search_ride': (context) => const SearchRideScreen(),
        '/ride_results': (context) => const RideResultsScreen(),
        '/ride_detail': (context) => const RideDetailScreen(),
        '/payment': (context) => const PaymentScreen(),
        '/booking_success': (context) => const BookingSuccessScreen(),
        '/track_ride': (context) => const TrackRideScreen(),
        '/rating': (context) => const RatingScreen(),

        '/driver_home': (context) => const DriverHub(),
        '/driver_request': (context) => const DriverRequestScreen(),
        '/driver_active_trip': (context) => const ActiveTripScreen(),
        '/driver_registration': (context) => const DriverRegistrationScreen(),
        '/driver_registration_form': (context) => const DriverRegistrationFormScreen(),
        '/create_ride': (context) => const CreateRideScreen(),
        '/ride_bookings': (context) => const RideBookingsScreen(),

        // ✅ NEW
        '/start_ride': (context) => const StartRideScreen(),
        '/ride_map': (context) => const RideMapScreen(),
      },
    );
  }
}
