import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/post_provider.dart';
import 'core/providers/booking_provider.dart';
import 'core/providers/language_provider.dart';
import 'localization/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'models/post_model.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/otp_screen.dart';
import 'screens/home_screen.dart';
import 'screens/community_screen.dart';
import 'screens/market_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/create_post_screen.dart';
import 'screens/post_detail_screen.dart';
import 'widgets/session_timeout_listener.dart';

void main() {
  runApp(const RoyalShetkariApp());
}

class RoyalShetkariApp extends StatelessWidget {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  const RoyalShetkariApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PostProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            locale: languageProvider.currentLocale,
            supportedLocales: const [
              Locale('en', ''),
              Locale('hi', ''),
              Locale('mr', ''),
              Locale('ta', ''),
              Locale('gu', ''),
            ],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            title: 'Royal Shetkari',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primaryColor: const Color(0xFF2E7D32),
              hintColor: const Color(0xFFFF9800),
              scaffoldBackgroundColor: Colors.white,
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                elevation: 0,
                centerTitle: true,
              ),
            ),
            initialRoute: '/',
            routes: {
              '/': (context) => const WelcomeScreen(),
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/otp': (context) => const OtpScreen(),
              '/home': (context) => const HomeScreen(),
              '/community': (context) => const CommunityScreen(),
              '/market': (context) => const MarketScreen(),
              '/profile': (context) => const ProfileScreen(),
              '/create-post': (context) => const CreatePostScreen(),
            },
            onGenerateRoute: (settings) {
              if (settings.name == '/post-detail') {
                final post = settings.arguments as PostModel;
                return MaterialPageRoute(
                  builder: (context) => PostDetailScreen(post: post),
                );
              }
              return null;
            },
            builder: (context, child) {
              return SessionTimeoutListener(
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}