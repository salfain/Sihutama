import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/portal_page.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/shared/splash_page.dart';

// Student — CBT shell
import '../features/student/student_cbt_shell_page.dart';
import '../features/student/dashboard/student_cbt_dashboard_page.dart';
import '../features/student/exams/exam_list/student_exams_page.dart';
import '../features/student/results/student_results_page.dart';
import '../features/student/cbt/student_cbt_profil_page.dart';

// Student — BK shell
import '../features/student/student_bk_shell_page.dart';
import '../features/student/bk/student_bk_home_page.dart';
import '../features/student/bk/student_bk_konseling_page.dart';
import '../features/student/bk/student_bk_permohonan_page.dart';
import '../features/student/bk/student_bk_profil_page.dart';

// Student — sub-routes (dipakai oleh kedua shell, di luar shell)
import '../features/student/exams/token_input/token_input_page.dart';
import '../features/student/exams/confirm/exam_confirm_page.dart';
import '../features/student/exams/take_exam/take_exam_page.dart';
import '../features/student/exams/take_exam/exam_locked_page.dart';
import '../features/student/exams/finish/exam_finish_page.dart';
import '../features/student/bk/student_survey_page.dart';

// Teacher
import '../features/teacher/dashboard/teacher_dashboard_page.dart';
import '../features/teacher/questions/questions_page.dart';
import '../features/teacher/exams/teacher_exams_page.dart';
import '../features/teacher/monitoring/monitoring_page.dart';
import '../features/teacher/essay_grading/essay_grading_page.dart';
import '../features/teacher/teacher_shell_page.dart';
import '../features/teacher/profil/teacher_profil_page.dart';

// Piket
import '../features/piket/piket_shell_page.dart';
import '../features/piket/dashboard/piket_dashboard_page.dart';
import '../features/piket/terlambat/piket_terlambat_page.dart';
import '../features/piket/izin/piket_izin_page.dart';
import '../features/piket/guru/piket_guru_page.dart';
import '../features/piket/laporan/piket_laporan_page.dart';
import '../features/piket/profil/piket_profil_page.dart';

// Counselor
import '../features/counselor/dashboard/counselor_dashboard_page.dart';
import '../features/counselor/counseling/counselor_counseling_page.dart';
import '../features/counselor/students/counselor_students_page.dart';
import '../features/counselor/students/counselor_student_detail_page.dart';
import '../features/counselor/cases/counselor_case_detail_page.dart';
import '../features/counselor/surveys/counselor_surveys_page.dart';
import '../features/counselor/counselor_shell_page.dart';
import '../features/counselor/profil/counselor_profil_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      // ── Splash & Portal ──────────────────────────────────────────────────
      GoRoute(path: '/', builder: (_, __) => const SplashPage()),
      GoRoute(path: '/portal', builder: (_, __) => const PortalPage()),

      // ── Login bercabang (parameter system: CBT | BK) ────────────────────
      GoRoute(
        path: '/login',
        builder: (_, state) {
          final system = state.uri.queryParameters['system'] ?? 'CBT';
          return LoginPage(system: system);
        },
      ),

      // ── Student — CBT Shell ──────────────────────────────────────────────
      // Siswa yang masuk lewat portal CBT mendapat shell dengan tab Ujian+Nilai
      ShellRoute(
        builder: (context, state, child) => StudentCbtShellPage(child: child),
        routes: [
          GoRoute(path: '/student/cbt', builder: (_, __) => const StudentCbtDashboardPage()),
          GoRoute(path: '/student/cbt/exams', builder: (_, __) => const StudentExamsPage()),
          GoRoute(path: '/student/cbt/results', builder: (_, __) => const StudentResultsPage()),
          GoRoute(path: '/student/cbt/profil', builder: (_, __) => const StudentCbtProfilPage()),
        ],
      ),

      // ── Student — BK Shell ───────────────────────────────────────────────
      // Siswa yang masuk lewat portal BK hanya melihat fitur konseling
      ShellRoute(
        builder: (context, state, child) => StudentBkShellPage(child: child),
        routes: [
          GoRoute(path: '/student/bk-portal', builder: (_, __) => const StudentBkHomePage()),
          GoRoute(path: '/student/bk-portal/konseling', builder: (_, __) => const StudentBkKonselingPage()),
          GoRoute(path: '/student/bk-portal/permohonan', builder: (_, __) => const StudentBkPermohonanPage()),
          GoRoute(path: '/student/bk-portal/profil', builder: (_, __) => const StudentBkProfilPage()),
        ],
      ),

      // ── Student sub-routes (di luar shell, dipakai oleh CBT maupun BK) ──
      GoRoute(path: '/student/exams/:id/token', builder: (_, state) =>
        TokenInputPage(examId: state.pathParameters['id']!)),
      GoRoute(path: '/student/exams/:id/confirm', builder: (_, state) =>
        ExamConfirmPage(
          examId: state.pathParameters['id']!,
          token: state.uri.queryParameters['token'],
        )),
      GoRoute(path: '/student/exams/:id/test', builder: (_, state) =>
        TakeExamPage(examId: state.pathParameters['id']!)),
      GoRoute(path: '/student/exams/:id/locked', builder: (_, state) =>
        ExamLockedPage(
          examId: state.pathParameters['id']!,
          reason: state.uri.queryParameters['reason'])),
      GoRoute(path: '/student/exams/:id/finish', builder: (_, state) =>
        ExamFinishPage(examId: state.pathParameters['id']!)),
      GoRoute(path: '/student/bk/survey/:id', builder: (_, state) =>
        StudentSurveyPage(surveyId: state.pathParameters['id']!)),

      // ── Teacher ──────────────────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => TeacherShellPage(child: child),
        routes: [
          GoRoute(path: '/teacher', builder: (_, __) => const TeacherDashboardPage()),
          GoRoute(path: '/teacher/questions', builder: (_, __) => const QuestionsPage()),
          GoRoute(path: '/teacher/exams', builder: (_, __) => const TeacherExamsPage()),
          GoRoute(path: '/teacher/essay-grading', builder: (_, __) => const EssayGradingPage()),
          GoRoute(path: '/teacher/profil', builder: (_, __) => const TeacherProfilPage()),
        ],
      ),
      GoRoute(path: '/teacher/monitoring/:examId', builder: (_, state) =>
        MonitoringPage(examId: state.pathParameters['examId']!)),

      // ── Counselor (Guru BK) ──────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => CounselorShellPage(child: child),
        routes: [
          GoRoute(path: '/counselor', builder: (_, __) => const CounselorDashboardPage()),
          GoRoute(path: '/counselor/counseling', builder: (_, __) => const CounselorCounselingPage()),
          GoRoute(path: '/counselor/students', builder: (_, __) => const CounselorStudentsPage()),
          GoRoute(
            path: '/counselor/students/:id',
            builder: (_, state) => CounselorStudentDetailPage(id: state.pathParameters['id']!)),
          GoRoute(path: '/counselor/surveys', builder: (_, __) => const CounselorSurveysPage()),
          GoRoute(path: '/counselor/profil', builder: (_, __) => const CounselorProfilPage()),
        ],
      ),
      // Counselor sub-routes (di luar shell)
      GoRoute(path: '/counselor/cases/:id', builder: (_, state) =>
        CounselorCaseDetailPage(id: state.pathParameters['id']!)),

      // ── Guru Piket ───────────────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => PiketShellPage(child: child),
        routes: [
          GoRoute(path: '/piket', builder: (_, __) => const PiketDashboardPage()),
          GoRoute(path: '/piket/terlambat', builder: (_, __) => const PiketTerlambatPage()),
          GoRoute(path: '/piket/izin', builder: (_, __) => const PiketIzinPage()),
          GoRoute(path: '/piket/guru', builder: (_, __) => const PiketGuruPage()),
          GoRoute(path: '/piket/laporan', builder: (_, __) => const PiketLaporanPage()),
          GoRoute(path: '/piket/profil', builder: (_, __) => const PiketProfilPage()),
        ],
      ),
    ],
  );
});
