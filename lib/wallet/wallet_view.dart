import 'package:flutter/material.dart';
import 'package:provider/src/provider.dart';
import 'package:rillliveapp/IAP/iap_repo.dart';
import 'package:rillliveapp/models/store_state.dart';
import 'package:rillliveapp/services/purchase_logic.dart';
import 'package:rillliveapp/shared/color_styles.dart';
import 'package:rillliveapp/shared/loading_animation.dart';
import 'package:rillliveapp/wallet/purchases_config.dart';

class WalletView extends StatefulWidget {
  const WalletView({Key? key}) : super(key: key);

  @override
  _WalletViewState createState() => _WalletViewState();
}

class _WalletViewState extends State<WalletView> {
  var size;
  String? currentBalance;
  List<Map<String, dynamic>> coinOption = [];
  List<Map<String, dynamic>> transactionCount = [];
  late PurchaseLogic purchaces;

  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;
    purchaces = context.watch<PurchaseLogic>();
    Widget storeWidget;
    switch (purchaces.storeState) {
      case StoreState.loading:
        storeWidget = _PurchasesLoading();
        break;
      case StoreState.notAvailable:
        storeWidget = _PurchasesNotAvailable();
        break;
      case StoreState.available:
        storeWidget = _PurchasesAvailable();
        break;
    }

    return Container(
      height: size.height,
      width: size.width,
      decoration: const BoxDecoration(
        image: DecorationImage(
            image: AssetImage('assets/images/bg1.png'), fit: BoxFit.cover),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Padding(
          padding: const EdgeInsets.only(left: 10, top: 45),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //Top text wallet
                Text(
                  'Wallet',
                  style: Theme.of(context).textTheme.headline6,
                ),
                //current balance view
                Container(
                  height: 75,
                  margin: EdgeInsets.only(top: 10, bottom: 15),
                  decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 1,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: ImageIcon(
                            AssetImage('assets/icons/money_rill_icon.png'),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${currentBalance ?? 0}',
                                style: textStyle_3,
                              ),
                              Text('Rill Coins', style: textStyle_15)
                            ]),
                      ),
                      Expanded(
                        flex: 3,
                        child: Container(
                          padding: EdgeInsets.all(5),
                          margin: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            'Rill Coint lets you unlock the features made for you to enjoy on the App',
                            style: textStyle_9,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: storeWidget,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
  }
}

class _PurchasesAvailable extends StatelessWidget {
  final List<Map<String, dynamic>> coinOption = [];
  final List<Map<String, dynamic>> transactionCount = [];
  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    var purchases = context.watch<PurchaseLogic>();
    var products = purchases.products;
    print('purchases available: $products');
    return SizedBox(
      height: size.height,
      child: Padding(
        padding: const EdgeInsets.only(top: 45.0, left: 15, right: 15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //add Coint text
            Text(
              'Add Coins',
              style: Theme.of(context).textTheme.headline6,
            ),
            //Coin purchase options
            SizedBox(
              height: 150,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: products.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                    width: size.width / 3,
                    decoration: BoxDecoration(
                      border: Border.all(),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[100],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 2,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: ImageIcon(
                              AssetImage('assets/icons/money_rill_icon.png'),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            '${coinOption[index]['coins']} coins',
                            style: textStyle_15,
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Container(
                            width: double.infinity,
                            margin: EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              color: color_4,
                            ),
                            child: Center(
                              child: Text('\$${coinOption[index]['price']}',
                                  textAlign: TextAlign.center,
                                  style: textStyle_4),
                            ),
                          ),
                        )
                      ],
                    ),
                  );
                },
              ),
            ),
            //Transaction text
            Text(
              'Transactions',
              style: Theme.of(context).textTheme.headline6,
            ),
            //List of transactions
          ],
        ),
      ),
    );
  }
}

class _PurchasesNotAvailable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Store is not available.', style: textStyle_1),
    );
  }
}

class _PurchasesLoading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(children: [
        const LoadingAmination(
          animationType: 'ThreeInOut',
        ),
        Text('Store is Loading', style: textStyle_1),
      ]),
    );
  }
}

class PastPurchases extends StatelessWidget {
  const PastPurchases({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var purchases = context.watch<IAPRepo>().purhcases;
    return ListView.separated(
        shrinkWrap: true,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(purchases[index].productId),
            subtitle: Text(purchases[index].status.toString()),
          );
        },
        separatorBuilder: (context, index) => const Divider(),
        itemCount: purchases.length);
  }
}
