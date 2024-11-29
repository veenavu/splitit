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
import 'package:splitit/screens/dashboard/binding/friendsPage_binding.dart';

import '../modelClass/models.dart';
import '../screens/dashboard/pages/friends_page.dart';
import '../screens/expense/editExpense_page.dart';
import '../screens/expense/expenseDisply_page.dart';

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

    GetPage(
        name: Routes.friends,
        page: () => const FriendsPage(),
        binding: FriendsBinding(),
    ),
    
    GetPage(
        name: Routes.displayExpense,
        page:  () {
          final args = Get.arguments;
          final expense = args['expense'] as Expense;
          return ExpenseDisplayPage(expense: expense);
        },
    ),
    GetPage(
      name: Routes.ediitExpense,
      page: () {
        final args = Get.arguments;
        final expense = args['expense'] as Expense;
        final group = args['group'] as Group;
        return EditExpensePage(expense: expense, group: group,);
      },
    ),

  ];
}