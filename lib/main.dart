import 'package:flutter/material.dart';
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

// Rider Flow
import 'features/rides/screens/search_ride_screen.dart';
import 'features/rides/screens/ride_results_screen.dart';
import 'features/rides/screens/ride_detail_screen.dart';
import 'features/rides/screens/payment_screen.dart';
import 'features/rides/screens/booking_success_screen.dart';
import 'features/rides/screens/track_ride_screen.dart';
import 'features/rides/screens/rating_screen.dart';

// Parcel Flow
import 'features/parcels/screens/send_parcel_screen.dart';
import 'features/parcels/screens/parcel_tracking_screen.dart';

// Driver Flow
import 'features/driver/screens/driver_home_screen.dart';
import 'features/driver/screens/driver_request_screen.dart';
import 'features/driver/screens/active_trip_screen.dart';
import 'features/driver/screens/driver_registration_screen.dart'; // The "Start Journey" screen
import 'features/driver/screens/driver_registration_form_screen.dart'; // The Form screen
import 'features/driver/screens/create_ride_screen.dart'; // NEW: Create Ride Screen

void main() {
  runApp(const DriveOnApp());
}

class DriveOnApp extends StatelessWidget {
  const DriveOnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DriveOn',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,

      // Start at Splash Screen
      initialRoute: '/',

      // Application Routes
      routes: {
        // --- Core & Auth ---
        '/': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/forgot_password': (context) => const ForgotPasswordScreen(),
        '/otp_verify': (context) => const OtpScreen(),

        // --- Home & Common ---
        '/home': (context) => const HomeScreen(),
        '/my_trips': (context) => const MyTripsScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/chat': (context) => const ChatScreen(),
        '/support': (context) => const SupportScreen(),
        '/subscription': (context) => const SubscriptionScreen(),

        // --- Rider Flow ---
        '/search_ride': (context) => const SearchRideScreen(),
        '/ride_results': (context) => const RideResultsScreen(),
        '/ride_detail': (context) => const RideDetailScreen(),
        '/payment': (context) => const PaymentScreen(),
        '/booking_success': (context) => const BookingSuccessScreen(),
        '/track_ride': (context) => const TrackRideScreen(),
        '/rating': (context) => const RatingScreen(),

        // --- Parcel Flow ---
        '/send_parcel': (context) => const SendParcelScreen(),
        '/parcel_tracking': (context) => const ParcelTrackingScreen(),

        // --- Driver Flow ---
        '/driver_home': (context) => const DriverHomeScreen(),
        '/driver_request': (context) => const DriverRequestScreen(),
        '/driver_active_trip': (context) => const ActiveTripScreen(),
        '/driver_registration': (context) => const DriverRegistrationScreen(),
        '/driver_registration_form': (context) =>
            const DriverRegistrationFormScreen(),
        // NEW ROUTE ADDED HERE:
        '/create_ride': (context) => const CreateRideScreen(),
      },
    );
  }
}
