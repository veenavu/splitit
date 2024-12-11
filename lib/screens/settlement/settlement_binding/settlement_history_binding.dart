import 'package:get/get.dart';

import '../settleement_controller/settlemnt_history_controller.dart';


class SettlementHistoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => SettlementHistoryController());
  }
}