import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_ios/in_app_purchase_ios.dart';
import 'package:in_app_purchase_ios/store_kit_wrappers.dart';
import 'package:rillliveapp/shared/color_styles.dart';
import 'consumable_store.dart';

class PurchaseConfig extends StatefulWidget {
  const PurchaseConfig({Key? key}) : super(key: key);

  @override
  _PurchaseConfigState createState() => _PurchaseConfigState();
}

const bool _kAutoConsume = true;

const String _kConsumableId = 'purchase';
const String _kUpgradeId = 'upgrade';
const String _k1SubscriptionId = '1000_coins';
const String _k2SubscriptionId = '10000_coins';
const String _k3SubscriptionId = '20000_coins';
const List<String> _kProductIds = <String>[
  _kConsumableId,
  _kUpgradeId,
  _k1SubscriptionId,
  _k2SubscriptionId,
  _k3SubscriptionId,
];

class _PurchaseConfigState extends State<PurchaseConfig> {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  List<String> _notFoundIds = [];
  List<ProductDetails> _products = [];
  List<PurchaseDetails> _purchases = [];
  List<String> _consumables = [];
  bool _isAvailable = false;
  bool _purchasePending = false;
  bool _loading = true;
  String? _queryProductError;

  @override
  void initState() {
    final Stream<List<PurchaseDetails>> purchaseUpdated =
        _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      _subscription.cancel();
    }, onError: (err) {
      print('Error in updating purchase list: $err');
    });
    initStoreInfo();
    super.initState();
  }

  //Initiate the store
  Future<void> initStoreInfo() async {
    final bool isAvailable = await _inAppPurchase.isAvailable();
    if (!isAvailable) {
      setState(() {
        _isAvailable = isAvailable;
        _products = [];
        _purchases = [];
        _notFoundIds = [];
        _consumables = [];
        _purchasePending = false;
        _loading = false;
      });
      return;
    }

    if (Platform.isIOS) {
      var iosPlatformAddition = _inAppPurchase
          .getPlatformAddition<InAppPurchaseIosPlatformAddition>();
      await iosPlatformAddition.setDelegate(PaymentQueueDelegate());
    }

    ProductDetailsResponse productDetailsResponse =
        await _inAppPurchase.queryProductDetails(
      _kProductIds.toSet(),
    );
    //if product list confornted an error
    if (productDetailsResponse.error != null) {
      setState(() {
        _queryProductError = productDetailsResponse.error!.message;
        _isAvailable = isAvailable;
        _products = productDetailsResponse.productDetails;
        _purchases = [];
        _notFoundIds = productDetailsResponse.notFoundIDs;
        _consumables = [];
        _purchasePending = false;
        _loading = false;
      });
      return;
    }
    //if product list is empty
    if (productDetailsResponse.productDetails.isEmpty) {
      setState(() {
        _queryProductError = null;
        _isAvailable = isAvailable;
        _products = productDetailsResponse.productDetails;
        _purchases = [];
        _notFoundIds = productDetailsResponse.notFoundIDs;
        _consumables = [];
        _purchasePending = false;
        _loading = false;
      });
      return;
    }
    //will load the store
    List<String> consumables = await ConsumableStore.load();
    setState(() {
      _isAvailable = isAvailable;
      _products = productDetailsResponse.productDetails;
      _notFoundIds = productDetailsResponse.notFoundIDs;
      _consumables = consumables;
      _purchasePending = false;
      _loading = false;
    });
  }

  @override
  void dispose() {
    if (Platform.isIOS) {
      var iosPlatformAddition = _inAppPurchase
          .getPlatformAddition<InAppPurchaseIosPlatformAddition>();
      iosPlatformAddition.setDelegate(null);
    }
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> stack = [];
    //will be the widget required for commensing a purchase
    if (_queryProductError == null) {
      stack.add(ListView(
        children: [
          _buildConnectionCheckTile(),
          _buildProductList(),
          _buildConsumableBox(),
          _buildRestoreButton(),
        ],
      ));
    } else {
      stack.add(Center(
        child: Text(_queryProductError!),
      ));
    }
    //will check for pending purchases
    if (_purchasePending) {
      stack.add(
        Stack(children: const [
          Opacity(
            opacity: 0.3,
            child: ModalBarrier(dismissible: false, color: Colors.grey),
          ),
          Center(
            child: CircularProgressIndicator(),
          )
        ]),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Coin Store',
          style: textStyle_4,
        ),
      ),
      body: Stack(children: stack),
    );
  }

  //Build the stack widgets
  Card _buildConnectionCheckTile() {
    if (_loading) {
      return const Card(
        child: ListTile(
          title: Text('Trying to connect...'),
        ),
      );
    }
    final Widget storeHeader = ListTile(
      leading: Icon(_isAvailable ? Icons.check : Icons.block,
          color: _isAvailable ? Colors.green : Colors.grey),
      title: Text('The store is ${_isAvailable ? 'available' : 'unavailable'}'),
    );
    final List<Widget> children = <Widget>[storeHeader];
    if (!_isAvailable) {
      children.addAll(
        [
          const Divider(),
          const ListTile(
            title: Text('Not connected'),
            subtitle: Text('Unable to connect to payment processor'),
          ),
        ],
      );
    }
    return Card(
      child: Column(children: children),
    );
  }

  //will build the list of avialable products
  Card _buildProductList() {
    if (_loading) {
      return const Card(
        child: ListTile(
          leading: CircularProgressIndicator(),
          title: Text('Fetching products...'),
        ),
      );
    }
    if (_isAvailable) {
      return Card();
    }
    final ListTile productsHeader = ListTile(
      title: Text('Products for sale'),
    );
    List<ListTile> productList = <ListTile>[];
    if (_notFoundIds.isNotEmpty) {
      productList.add(
        ListTile(
          title: Text('[${_notFoundIds.join(', ')}] not found'),
          subtitle: Text('This app need special configuration to run'),
        ),
      );

      //will map all purchases
      Map<String, PurchaseDetails> purchases = Map.fromEntries(
        _purchases.map(
          (PurchaseDetails purchaseDetails) {
            if (purchaseDetails.pendingCompletePurchase) {
              _inAppPurchase.completePurchase(purchaseDetails);
            }
            return MapEntry<String, PurchaseDetails>(
                purchaseDetails.productID, purchaseDetails);
          },
        ),
      );
      productList.addAll(
        _products.map(
          (ProductDetails productDetails) {
            PurchaseDetails? previousPurchases = purchases[productDetails.id];
            return ListTile(
              title: Text(productDetails.title),
              subtitle: Text(productDetails.description),
              trailing: previousPurchases != null
                  ? IconButton(
                      onPressed: () => confirmPriceChange(context),
                      icon: Icon(Icons.upgrade),
                    )
                  : TextButton(
                      child: Text(productDetails.price),
                      onPressed: () {
                        //set purchase parameter depending on platform
                        late PurchaseParam purchaseParam;
                        if (Platform.isAndroid) {
                          purchaseParam = GooglePlayPurchaseParam(
                              productDetails: productDetails,
                              applicationUserName: null);
                        } else {
                          purchaseParam = PurchaseParam(
                              productDetails: productDetails,
                              applicationUserName: null);
                        }

                        if (productDetails.id == _kConsumableId) {
                          _inAppPurchase.buyConsumable(
                              purchaseParam: purchaseParam,
                              autoConsume: _kAutoConsume || Platform.isIOS);
                        } else {
                          _inAppPurchase.buyNonConsumable(
                              purchaseParam: purchaseParam);
                        }
                      }),
            );
          },
        ),
      );
    }
    return Card(
      child: Column(
        children: <Widget>[productsHeader, const Divider()] + productList,
      ),
    );
  }

  Card _buildConsumableBox() {
    return Card();
  }

  Widget _buildRestoreButton() {
    return Padding(
      padding: EdgeInsets.all(4),
      child: Container(),
    );
  }

  Future<void> confirmPriceChange(BuildContext context) async {}

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {}
}

//Queue delegate as needed for IOS
class PaymentQueueDelegate implements SKPaymentQueueDelegateWrapper {
  @override
  bool shouldContinueTransaction(
      SKPaymentTransactionWrapper transaction, SKStorefrontWrapper storefront) {
    return true;
  }

  @override
  bool shouldShowPriceConsent() {
    return false;
  }
}
