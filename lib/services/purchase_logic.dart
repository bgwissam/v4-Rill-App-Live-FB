import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:rillliveapp/models/store_state.dart';

class IAPConnection {
  static InAppPurchase? _instance;
  static set instance(InAppPurchase value) {
    _instance = value;
  }

  static InAppPurchase get instance {
    _instance ??= InAppPurchase.instance;
    return _instance!;
  }
}

class PurchaseLogic extends ChangeNotifier {
  StoreState storeState = StoreState.loading;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  List<PurchasableProducts> products = [];

  final iapPurchases = IAPConnection.instance;

  PurchaseLogic() {
    final purchaseUpdated = iapPurchases.purchaseStream;
    _subscription = purchaseUpdated.listen(
      _onPurchaseUpdate,
      onDone: _updateStreamOnDone,
      onError: _updateStreamOnError,
    );
    loadPurchases();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

//Load purchasable products
  Future<void> loadPurchases() async {
    final available = await iapPurchases.isAvailable();
    if (!available) {
      storeState = StoreState.notAvailable;
      notifyListeners();
      print('Store is not available');
      return;
    }

    const ids = <String>{
      'coins_20',
      'coins_100',
      'coins_200',
      'coins_500',
      'coins_1000',
      'coins_2000'
    };

    final response = await iapPurchases.queryProductDetails(ids);
    products = response.productDetails
        .map((e) => PurchasableProducts(productDetails: e))
        .toList();
    storeState = StoreState.available;
    notifyListeners();
  }

//buying product
  Future<void> buy(PurchasableProducts product) async {
    product.productStatus = ProductStatus.pending;
    notifyListeners();
    await Future<void>.delayed(const Duration(seconds: 5));
    product.productStatus = ProductStatus.purchased;
    notifyListeners();
    await Future<void>.delayed(const Duration(seconds: 5));
    product.productStatus = ProductStatus.pruchasable;
    notifyListeners();
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    // Handle purchases here
  }

  void _updateStreamOnDone() {
    _subscription.cancel();
  }

  void _updateStreamOnError(dynamic error) {
    //Handle error here
  }
}
