import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rillliveapp/models/past_purchase_model.dart';
import 'package:rillliveapp/models/user_model.dart';
import 'package:rillliveapp/wallet/wallet_view.dart';

class IAPRepo extends ChangeNotifier {
  late FirebaseFirestore _firestore;
  late FirebaseAuth _auth;

  bool get isLoggedIn => _user != null;
  User? _user;
  bool hasActiveSubscription = false;
  bool hasUpgrade = false;
  List<PastPurchaseModel> purhcases = [];

  late StreamSubscription<User?> _userSubscription;
  StreamSubscription<QuerySnapshot>? _purchaseSubscription;

  // IAPRepo(FirebaseNotifier firebaseNotifier) {
  //   firebaseNotifier.firestore.then((val) {
  //     _auth = FirebaseAuth.instance;
  //     _firestore = val;
  //     updatePurchases();
  //     listenToLogin();
  //   });
  // }

  void listenToLogin() {
    _user = _auth.currentUser;
    _userSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      _user = user;
      updatePurchases();
    });
  }

  void updatePurchases() {
    _purchaseSubscription?.cancel();
    var user = _user;
    if (user == null) {
      purhcases = [];
      hasActiveSubscription = false;
      hasUpgrade = false;
      return;
    }

    var purchaseStream = _firestore
        .collection('purchases')
        .where('userId', isEqualTo: user.uid)
        .snapshots();
    _purchaseSubscription = purchaseStream.listen(
      (snapshot) {
        purhcases = snapshot.docs.map((document) {
          var data = document.data();
          return PastPurchaseModel.fromJson(data);
        }).toList();
      },
    );
  }
}
