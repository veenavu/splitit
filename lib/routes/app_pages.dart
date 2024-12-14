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

import '../DatabaseHelper/hive_services.dart';
import '../screens/dashboard/controller/activityPage_controller.dart';
import '../screens/dashboard/pages/activity_page.dart';
import '../screens/dashboard/pages/friends_page.dart';
import '../screens/expense/editExpense_page.dart';
import '../screens/expense/expenseDisply_page.dart';
import '../screens/profiles/bindings/account_seeings_binding.dart';
import '../screens/profiles/bindings/statistics_binding.dart';
import '../screens/profiles/pages/account_settings_page.dart';
import '../screens/profiles/pages/statictics.dart';
import '../screens/settlement/settlement_binding/settlement_binding.dart';
import '../screens/settlement/settlement_binding/settlement_history_binding.dart';
import '../screens/settlement/settlement_page.dart';
import '../screens/settlement/settlemnt_history.dart';

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
    GetPage(name: Routes.login, page: () => const LoginPage(), binding: AuthBinding()),
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
      page: () {
        final args = Get.arguments;
        // final expense = args['expense'] as Expense;
        return const ExpenseDisplayPage();
      },
    ),
    GetPage(
      name: Routes.ediitExpense,
      page: () {
        final args = Get.arguments;
        // final expense = args['expense'] as Expense;
        // final group = args['group'] as Group;
        return EditExpensePage(/*expense: expense, group: group,*/);
      },
    ),
    GetPage(
      name: '/settlement/:groupId',
      page: () {
        final groupId = int.parse(Get.parameters['groupId']!);
        final group = ExpenseManagerService.getGroupById(groupId);
        return SettlementPage(group: group!);
      },
      binding: SettlementBinding(),
    ),
    GetPage(
      name: Routes.activity,
      page: () => const ActivitiesPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => ActivityController());
      }),
    ),

    GetPage(
        name: Routes.settlementhistory,
        page: () => const SettlementHistoryPage(),
        binding: SettlementHistoryBinding(),
    ),


    GetPage(
        name: Routes.accountSettings,
        page: () => const AccountSettingsPage(),
      binding: AccountSettingsBinding(),
    ),

    GetPage(
        name: Routes.statistics,
        page: () => const StatisticsPage(),
       binding: StatisticsBinding(),
    ),





  ];
}
