import 'package:get/get.dart';
import '../settleement_controller/settlement_controller.dart';
import '../settlement_services.dart';

class SettlementBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => SettlementController());
  }
}