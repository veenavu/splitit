import 'package:get/get.dart';
import 'package:splitit/routes/app_routes.dart';
import 'package:splitit/screens/auth/binding/auth_binding.dart';
import 'package:splitit/screens/auth/login_page.dart';
import 'package:splitit/screens/auth/sign_up.dart';
import 'package:splitit/screens/dashboard/binding/dashboard_binding.dart';
import 'package:splitit/screens/dashboard/dashboard.dart';
import 'package:splitit/screens/expense/add_expense_page.dart';
import 'package:splitit/screens/group/add_group.dart';
import 'package:splitit/screens/group/gruop_binding/group_binding.dart';
import 'package:splitit/screens/welcome/get_started.dart';
import 'package:splitit/screens/welcome/splash.dart';

class AppPages {
  static final pages = [
    GetPage(
      name: Routes.initial,
      page: () => const SplashPage(),
    ),
    GetPage(
      name: Routes.getStarted,
      page: () => const GetStartedPage(),
    ),
    GetPage(
        name: Routes.login,
        page: () => const LoginPage(),
        binding: AuthBinding()

    ),
    GetPage(
        name: Routes.signup,
        page: () => const SignUpPage(),
    ),
    GetPage(
      name: Routes.dashboard,
      page: () => const Dashboard(),
      binding: DashboardBinding(),
    ),
    GetPage(
      name: Routes.addNewGroup,
      page: () => const AddNewGroupPage(),
      binding: AddNewGroupBinding(),
    ),

    GetPage(
      name: Routes.addExpense,
      page: () => AddExpensePage(),

    ),

  ];
}