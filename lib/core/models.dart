import 'package:flutter/cupertino.dart';

class DetailReceipt {
  String id;
  String tableId;
  String table;
  num total;
  String author;
  String authorId;
  int date;
  String number;
  String version;
  List<ItemsReceipt>? items = [];
  List<Payments>? payments = [];
  List<ItemsReceipt>? refunds = [];

  DetailReceipt(
      {required this.id,
      required this.tableId,
      required this.table,
      required this.total,
      required this.author,
      required this.authorId,
      required this.date,
      required this.number,
      required this.version,
      // required this.userId,
      this.items,
      this.payments,
      this.refunds});

  factory DetailReceipt.fromJson(Map<String, dynamic> json) {
    return DetailReceipt(
        id: json['id'],
        tableId: json['tableId'],
        table: json['table'],
        total: !(json['total'] == null) ? json['total'] : 0,
        author: json['author'],
        authorId: !(json['authorId'] == null) ? json['authorId'] : '',
        date: json['date'],
        number: json['number'],
        version: json['version'],
        items: !(json['items'] == null)
            ? (ItemsReceipt.toListFromMap(json['items']))
            : [],
        refunds: !(json['refunds'] == null)
            ? (ItemsReceipt.toListFromMap(json['refunds']))
            : [],
        payments: []);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'tableId': tableId,
        'table': table,
        'total': total,
        'author': author,
        'authorId': authorId,
        'products': items,
        'payments': payments,
        'refunds': refunds,
        'version': version
      };

  static List<DetailReceipt> toListFromMap(List<dynamic> json) {
    return json.map((data) => DetailReceipt.fromJson(data)).toList();
  }
}

class ItemsReceipt {
  String id;
  String product;
  num qt;
  num price;
  num total;
  int date;
  String? unit = '';

  ItemsReceipt(
      {required this.id,
      required this.product,
      required this.qt,
      required this.price,
      required this.total,
      required this.date,
      this.unit});

  factory ItemsReceipt.fromJson(Map<String, dynamic> json) {
    return ItemsReceipt(
        id: json['id'],
        product: json['product'],
        qt: !(json['qt'] == null) ? json['qt'] : 0,
        price: !(json['price'] == null) ? json['price'] : 0,
        total: !(json['total'] == null) ? json['total'] : 0,
        date: json['date'] * 1000,
        unit: !(json['unit'] == null) ? json['unit'] : "");
  }
  Map<String, dynamic> toJson() => {
        'id': id,
        'product': product,
        'qt': qt,
        'price': price,
        'total': total,
        'date': date
      };
  static List<ItemsReceipt> toListFromMap(List<dynamic> json) {
    return json.map((data) => ItemsReceipt.fromJson(data)).toList();
  }
}

class Payments {
  String type;
  num total;

  Payments({
    required this.type,
    required this.total,
  });

  factory Payments.fromJson(Map<String, dynamic> json) {
    return Payments(type: json['type'], total: json['total']);
  }
  Map<String, dynamic> toJson() => {'type': type, 'total': total};

  static List<Payments> toListFromMap(List<dynamic> json) {
    return json.map((data) => Payments.fromJson(data)).toList();
  }
}

class Menu {
  String id;
  String product;
  num price;
  String unit;
  TextEditingController controller;

  Menu(
      {required this.id,
      required this.product,
      required this.price,
      required this.unit,
      required this.controller});

  factory Menu.fromJson(Map<String, dynamic> json) {
    return Menu(
        id: json['id'],
        product: json['product'],
        price: !(json['price'] == null) ? json['price'] : 0,
        unit: json['unit'],
        controller: TextEditingController());
  }
  Map<String, dynamic> toJson() => {
        'id': id,
        'product': product,
        'price': price,
      };
  static List<Menu> toListFromMap(List<dynamic> json) {
    return json.map((data) => Menu.fromJson(data)).toList();
  }
}
