import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_ios/in_app_purchase_ios.dart';
import 'package:in_app_purchase_ios/store_kit_wrappers.dart';
import 'consumable_store.dart';

class PurchaseConfig extends StatefulWidget {
  const PurchaseConfig({Key? key}) : super(key: key);

  @override
  _PurchaseConfigState createState() => _PurchaseConfigState();
}

const bool _kAutoConsume = true;

const String _k1SubscriptionId = 'coins100';
const String _k2SubscriptionId = 'coins1000';
const String _k3SubscriptionId = 'coins10000';
const String _k4SubscriptionId = 'coins50000';
const List<String> _kProductIds = <String>[
  _k1SubscriptionId,
  _k2SubscriptionId,
  _k3SubscriptionId,
  _k4SubscriptionId,
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
    _setProductDetails();
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
    print('the products: $_products');
    super.initState();
  }

  _setProductDetails() async {
    _products = [
      ProductDetails(
          id: 'coins_20',
          title: '20',
          description: '20 Coins',
          price: '2',
          rawPrice: 2.0,
          currencyCode: 'CAD'),
      ProductDetails(
          id: 'coins_100',
          title: '100',
          description: '100 Coins',
          price: '9.8',
          rawPrice: 9.8,
          currencyCode: 'CAD'),
      ProductDetails(
          id: 'coins_200',
          title: '200',
          description: '200 Coins',
          price: '20',
          rawPrice: 20.0,
          currencyCode: 'CAD'),
      ProductDetails(
          id: 'coins_500',
          title: '500',
          description: '500 Coins',
          price: '50',
          rawPrice: 50.0,
          currencyCode: 'CAD'),
      ProductDetails(
          id: 'coins_1000',
          title: '1000',
          description: '1000 Coins',
          price: '100',
          rawPrice: 100.0,
          currencyCode: 'CAD'),
      ProductDetails(
          id: 'coins_2000',
          title: '2000',
          description: '2000 Coins',
          price: '200',
          rawPrice: 200.0,
          currencyCode: 'CAD'),
    ];
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
    print('the products: ${productDetailsResponse.productDetails}');
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
    return Container(
      child: Stack(children: stack),
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
    print('loading: $_loading');
    if (_loading) {
      return const Card(
        child: ListTile(
          leading: CircularProgressIndicator(),
          title: Text('Fetching products...'),
        ),
      );
    }
    if (!_isAvailable) {
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
            print('product details: ${productDetails.id}');
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

                        _inAppPurchase.buyNonConsumable(
                            purchaseParam: purchaseParam);
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
    if (_loading) {
      return const Card(
        child: ListTile(
          leading: CircularProgressIndicator(),
          title: Text('Fetching consumables'),
        ),
      );
    }
    if (!_isAvailable) {
      return Card(
        child: Text('Consumable box: Available: $_isAvailable'),
      );
    }
    final ListTile consumableHeader =
        ListTile(title: Text('Purchased consumables'));
    final List<Widget> tokens = _consumables.map((String id) {
      return GridTile(
        child: IconButton(
          icon: const Icon(
            Icons.star,
            size: 40,
            color: Colors.orange,
          ),
          splashColor: Colors.yellowAccent,
          onPressed: () => consume(id),
        ),
      );
    }).toList();

    return Card(
        child: Column(
      children: [
        consumableHeader,
        Divider(),
        GridView.count(
          crossAxisCount: 4,
          children: tokens,
          shrinkWrap: true,
          padding: EdgeInsets.all(12),
        )
      ],
    ));
  }

  Widget _buildRestoreButton() {
    if (_loading) {
      return Container();
    }
    return Padding(
      padding: EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
              onPressed: () => _inAppPurchase.restorePurchases(),
              child: Text('Restore Purhcases'))
        ],
      ),
    );
  }

  Future<void> consume(String id) async {
    await ConsumableStore.consume(id);
    final List<String> consumables = await ConsumableStore.load();
    setState(() {
      _consumables = consumables;
    });
  }

  void showPendingUI() {
    setState(() {
      _purchasePending = true;
    });
  }

  void deliverProduct(PurchaseDetails purchaseDetails) async {
    // IMPORTANT!! Always verify purchase details before delivering the product.
    // if (purchaseDetails.productID == _kConsumableId) {
    //   await ConsumableStore.save(purchaseDetails.purchaseID!);
    //   List<String> consumables = await ConsumableStore.load();
    //   setState(() {
    //     _purchasePending = false;
    //     _consumables = consumables;
    //   });
    // } else {
    setState(() {
      _purchases.add(purchaseDetails);
      _purchasePending = false;
    });
    // }
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) {
    // IMPORTANT!! Always verify a purchase before delivering the product.
    // For the purpose of an example, we directly return true.
    return Future<bool>.value(true);
  }

  void _handleInvalidPurchase(PurchaseDetails purchaseDetails) {
    // handle invalid purchase here if  _verifyPurchase` failed.
  }

  void handleError(IAPError error) {
    setState(() {
      _purchasePending = false;
    });
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    purchaseDetailsList.forEach((PurchaseDetails purchaseDetails) async {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        showPendingUI();
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          handleError(purchaseDetails.error!);
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          bool valid = await _verifyPurchase(purchaseDetails);
          if (valid) {
            deliverProduct(purchaseDetails);
          } else {
            _handleInvalidPurchase(purchaseDetails);
            return;
          }
        }
        if (Platform.isAndroid) {
          if (!_kAutoConsume) {
            final InAppPurchaseAndroidPlatformAddition androidAddition =
                _inAppPurchase.getPlatformAddition<
                    InAppPurchaseAndroidPlatformAddition>();
            await androidAddition.consumePurchase(purchaseDetails);
          }
        }
        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
        }
      }
    });
  }

  Future<void> confirmPriceChange(BuildContext context) async {
    if (Platform.isAndroid) {
      final InAppPurchaseAndroidPlatformAddition androidAddition =
          _inAppPurchase
              .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
      var priceChangeConfirmationResult = await androidAddition
          .launchPriceChangeConfirmationFlow(sku: 'purchaseId');
      if (priceChangeConfirmationResult.responseCode == BillingResponse.ok) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Price change accepted'),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            priceChangeConfirmationResult.debugMessage ??
                "Price change failed with code ${priceChangeConfirmationResult.responseCode}",
          ),
        ));
      }
    }
    if (Platform.isIOS) {
      var iaIosPlatformAddition = _inAppPurchase
          .getPlatformAddition<InAppPurchaseIosPlatformAddition>();
      await iaIosPlatformAddition.showPriceConsentIfNeeded();
    }
  }
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
