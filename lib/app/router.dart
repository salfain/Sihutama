import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/shared/splash_page.dart';
import '../features/student/dashboard/student_dashboard_page.dart';
import '../features/student/exams/exam_list/student_exams_page.dart';
import '../features/student/exams/token_input/token_input_page.dart';
import '../features/student/exams/confirm/exam_confirm_page.dart';
import '../features/student/exams/take_exam/take_exam_page.dart';
import '../features/student/exams/take_exam/exam_locked_page.dart';
import '../features/student/exams/finish/exam_finish_page.dart';
import '../features/student/results/student_results_page.dart';
import '../features/student/bk/student_bk_page.dart';
import '../features/teacher/dashboard/teacher_dashboard_page.dart';
import '../features/teacher/questions/questions_page.dart';
import '../features/teacher/exams/teacher_exams_page.dart';
import '../features/teacher/monitoring/monitoring_page.dart';
import '../features/teacher/essay_grading/essay_grading_page.dart';
import '../features/counselor/dashboard/counselor_dashboard_page.dart';
import '../features/counselor/counseling/counselor_counseling_page.dart';
import '../features/counselor/students/counselor_students_page.dart';
import '../features/counselor/students/counselor_student_detail_page.dart';
import '../features/counselor/surveys/counselor_surveys_page.dart';
import '../features/counselor/counselor_shell_page.dart';
import '../features/student/bk/student_survey_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashPage()),
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      // Student
      GoRoute(path: '/student', builder: (_, __) => const StudentDashboardPage()),
      GoRoute(path: '/student/exams', builder: (_, __) => const StudentExamsPage()),
      GoRoute(path: '/student/exams/:id/token', builder: (_, state) =>
        TokenInputPage(examId: state.pathParameters['id']!)),
      GoRoute(path: '/student/exams/:id/confirm', builder: (_, state) =>
        ExamConfirmPage(examId: state.pathParameters['id']!)),
      GoRoute(path: '/student/exams/:id/test', builder: (_, state) =>
        TakeExamPage(examId: state.pathParameters['id']!)),
      GoRoute(path: '/student/exams/:id/locked', builder: (_, state) =>
        ExamLockedPage(examId: state.pathParameters['id']!, reason: state.uri.queryParameters['reason'])),
      GoRoute(path: '/student/exams/:id/finish', builder: (_, state) =>
        ExamFinishPage(examId: state.pathParameters['id']!)),
      GoRoute(path: '/student/results', builder: (_, __) => const StudentResultsPage()),
      GoRoute(path: '/student/bk', builder: (_, __) => const StudentBkPage()),
      GoRoute(path: '/student/bk/survey/:id', builder: (_, state) =>
        StudentSurveyPage(surveyId: state.pathParameters['id']!)),
      // Teacher
      GoRoute(path: '/teacher', builder: (_, __) => const TeacherDashboardPage()),
      GoRoute(path: '/teacher/questions', builder: (_, __) => const QuestionsPage()),
      GoRoute(path: '/teacher/exams', builder: (_, __) => const TeacherExamsPage()),
      GoRoute(path: '/teacher/essay-grading', builder: (_, __) => const EssayGradingPage()),
      GoRoute(path: '/teacher/monitoring/:examId', builder: (_, state) =>
        MonitoringPage(examId: state.pathParameters['examId']!)),
      // Counselor (Guru BK)
      ShellRoute(
        builder: (context, state, child) {
          return CounselorShellPage(child: child);
        },
        routes: [
          GoRoute(path: '/counselor', builder: (_, __) => const CounselorDashboardPage()),
          GoRoute(path: '/counselor/counseling', builder: (_, __) => const CounselorCounselingPage()),
          GoRoute(path: '/counselor/students', builder: (_, __) => const CounselorStudentsPage()),
          GoRoute(path: '/counselor/students/:id', builder: (_, state) => CounselorStudentDetailPage(id: state.pathParameters['id']!)),
          GoRoute(path: '/counselor/surveys', builder: (_, __) => const CounselorSurveysPage()),
        ],
      ),
    ],
  );
});
