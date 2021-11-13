import 'package:flutter/material.dart';
import 'package:rillliveapp/shared/color_styles.dart';
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

  //controller
  PurchaseConfig pConfig = PurchaseConfig();
  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;
    return Container(
      height: size.height,
      width: size.width,
      decoration: const BoxDecoration(
        image: DecorationImage(
            image: AssetImage('assets/images/bg1.png'), fit: BoxFit.cover),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: _buildWalletView(),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _fillCoinOption();
    _getTransactions();
  }

  Widget _buildWalletView() {
    return SizedBox(
      height: size.height,
      child: Padding(
        padding: const EdgeInsets.only(top: 45.0, left: 15, right: 15),
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
            ), //add Coint text
            Text(
              'Add Coins',
              style: Theme.of(context).textTheme.headline6,
            ),
            //Coin purchase options
            SizedBox(
              height: 150,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: coinOption.length,
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
            SizedBox(height: size.height / 2, child: pConfig

                // ListView.builder(
                //     itemCount: transactionCount.length,
                //     itemBuilder: (context, index) {
                //       return Container(
                //         padding:
                //             EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                //         width: double.infinity,
                //         child: Row(
                //           mainAxisAlignment: MainAxisAlignment.start,
                //           children: [
                //             Expanded(
                //               flex: 2,
                //               child: Text(
                //                   '${transactionCount[index]['description']}',
                //                   style: textStyle_15),
                //             ),
                //             Expanded(
                //               flex: 1,
                //               child: Text('${transactionCount[index]['date']}',
                //                   style: textStyle_15),
                //             )
                //           ],
                //         ),
                //       );
                //     }),
                ),
          ],
        ),
      ),
    );
  }

  _fillCoinOption() {
    coinOption = [
      {
        'coins': 100,
        'price': 5,
      },
      {
        'coins': 1000,
        'price': 10,
      },
      {
        'coins': 10000,
        'price': 15,
      },
      {
        'coins': 50000,
        'price': 20,
      },
    ];
  }

  _getTransactions() {
    transactionCount = [
      {'description': 'added 200 coints', 'date': '26.05.2021'},
      {'description': 'unloacked new feature', 'date': '13.09.2021'},
      {'description': 'added 200 coints', 'date': '01.10.2021'},
    ];
  }
}
