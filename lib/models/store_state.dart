import 'package:in_app_purchase/in_app_purchase.dart';

enum StoreState { loading, available, notAvailable }

enum ProductStatus { pruchasable, purchased, pending }

class PurchasableProducts {
  String? get id => productDetails?.id;
  String? get title => productDetails?.title;
  String? get description => productDetails?.description;
  String? get price => productDetails?.price;
  ProductStatus productStatus;
  ProductDetails? productDetails;

  PurchasableProducts({this.productDetails})
      : productStatus = ProductStatus.pruchasable;
}
