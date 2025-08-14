import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/tutors/presentation/tutor_list_screen.dart';
import '../features/tutors/presentation/tutor_detail_screen.dart';
import '../features/tutors/presentation/tutor_profile_edit_screen.dart';
import '../features/lesson_requests/presentation/lesson_request_form_screen.dart';
import '../features/lesson_requests/presentation/lesson_requests_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const TutorListScreen(),
      ),
      GoRoute(
        path: '/tutors/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          return TutorDetailScreen(tutorId: id ?? 0);
        },
      ),
      GoRoute(
        path: '/tutor-profile-edit',
        builder: (context, state) => const TutorProfileEditScreen(),
      ),
      GoRoute(
        path: '/lesson-requests/new',
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>?;
          return LessonRequestFormScreen(
            tutorId: extras?['tutorId'] as int?,
          );
        },
      ),
      GoRoute(
        path: '/lesson-requests',
        builder: (context, state) => const LessonRequestsScreen(),
      ),
    ],
  );
});


