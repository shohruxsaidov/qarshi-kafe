import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:qarshi_kafe/core/constants.dart';
import 'package:qarshi_kafe/core/models.dart';
import 'package:qarshi_kafe/screens/dialogs.dart';

Future<bool> getMenu(context) async {
  var client = http.Client();
  bool result = false;
  try {
    bool isOnline = await hasNetwork();

    if (!isOnline) {
      ShowNoInternet(context);
      return result;
    }

    Map<String, dynamic> row = {
      'userId': userId,
      'method': 'get',
    };

    String data = jsonEncode(row);

    await client
        .post(Uri.parse('http://$srvAddress/$srvBase/hs/$srvCatalog/menu'),
            headers: <String, String>{'authorization': basicAuth}, body: data)
        .timeout(
          const Duration(seconds: 60),
        )
        .then((response) async {
      if (response.statusCode == 200) {
        var jsonData = jsonDecode(utf8.decode(response.bodyBytes));
        if (jsonData['ok']) {
          menu = Menu.toListFromMap(jsonData['result'] as List<dynamic>);
          result = true;
        } else {
          ShowDialog(context, jsonData["message"], Colors.red);
        }
      } else {
        ShowDialog(context, 'Ошибка ${response.statusCode}: ${response.body}',
            Colors.red);
      }
    });
  } catch (e) {
    ShowDialog(context, "Упс! Что-то пошло нет так. ($e)", Colors.red);
    return result;
  } finally {
    client.close();
  }
  return result;
}

Future getReceipt(context, sale, {String id = ''}) async {
  var client = http.Client();
  Object? result;
  try {
    bool isOnline = await hasNetwork();

    if (!isOnline) {
      ShowNoInternet(context);
      return result;
    }

    Map<String, dynamic> row = {
      'userId': userId,
      'method': 'get',
      'id': id,
    };

    String query = !(sale) ? 'receipt' : 'sale';

    String data = jsonEncode(row);

    await client
        .post(Uri.parse('http://$srvAddress/$srvBase/hs/$srvCatalog/$query'),
            headers: <String, String>{'authorization': basicAuth}, body: data)
        .timeout(
          const Duration(seconds: 60),
        )
        .then((response) async {
      if (response.statusCode == 200) {
        var jsonData = jsonDecode(utf8.decode(response.bodyBytes));
        if (jsonData['ok']) {
          //id незаполнено -  для получения список чеков в массиве
          if (id.isEmpty) {
            result = DetailReceipt.toListFromMap(
                jsonData['result'] as List<dynamic>);
          } else {
            //id заполнено - для получения конкретного чека по ИД
            result = DetailReceipt.fromJson(jsonData['result']);
          }
        } else {
          ShowDialog(context, jsonData["message"], Colors.red);
        }
      } else {
        ShowDialog(context, 'Ошибка ${response.statusCode}: ${response.body}',
            Colors.red);
      }
    });
  } catch (e) {
    ShowDialog(context, "Упс! Что-то пошло нет так. ($e)", Colors.red);
    return result;
  } finally {
    client.close();
  }
  return result;
}

Future<Map> postReceipt(context, DetailReceipt receipt, sale) async {
  var client = http.Client();
  Map<String, dynamic> result = {'success': false, 'hasOrder': false};
  try {
    bool isOnline = await hasNetwork();

    if (!isOnline) {
      ShowNoInternet(context);
      return result;
    }

    Map<String, dynamic> row = {
      'userId': userId,
      'method': 'post',
      'data': receipt.toJson(),
    };

    String data = jsonEncode(row);
    String query = !(sale) ? 'receipt' : 'sale';

    await client
        .post(Uri.parse('http://$srvAddress/$srvBase/hs/$srvCatalog/$query'),
            headers: <String, String>{'authorization': basicAuth}, body: data)
        .timeout(
          const Duration(seconds: 60),
        )
        .then((response) async {
      if (response.statusCode == 200) {
        var jsonData = jsonDecode(utf8.decode(response.bodyBytes));
        if (jsonData['ok']) {
          if (jsonData['result']) {
            result['hasOrder'] = jsonData['result'];
          }
          result['success'] = true;
        } else {
          ShowDialog(context, jsonData["message"], Colors.red);
        }
      } else {
        ShowDialog(context, 'Ошибка ${response.statusCode}: ${response.body}',
            Colors.red);
      }
    });
  } catch (e) {
    ShowDialog(context, "Упс! Что-то пошло нет так. ($e)", Colors.red);
    return result;
  } finally {
    client.close();
  }
  return result;
}

Future<Map> postPayment(context, DetailReceipt receipt, sale) async {
  var client = http.Client();
  Map<String, dynamic> result = {'success:': false, 'path': ''};
  try {
    bool isOnline = await hasNetwork();

    if (!isOnline) {
      ShowNoInternet(context);
      return result;
    }

    Map<String, dynamic> row = {
      'userId': userId,
      'sale': sale,
      'data': receipt.toJson(),
    };

    String data = jsonEncode(row);

    await client
        .post(Uri.parse('http://$srvAddress/$srvBase/hs/$srvCatalog/payment'),
            headers: <String, String>{'authorization': basicAuth}, body: data)
        .timeout(
          const Duration(seconds: 60),
        )
        .then((response) async {
      if (response.statusCode == 200) {
        var ok = response.headers['ok'];
        if (ok == "0" || ok == null) {
          ShowDialog(context, '${jsonDecode(utf8.decode(response.bodyBytes))}',
              Colors.red);
        } else {
          result['success'] = true;
          var bytes = response.bodyBytes;
          var dir = await getApplicationDocumentsDirectory();
          final filename = response.headers['filename'];
          if (filename != null) {
            File file = File("${dir.path}/$filename.pdf");
            await file.writeAsBytes(bytes).then((value) {
              result['path'] = value.path;
            });
          }
        }
        // var jsonData = jsonDecode(utf8.decode(response.bodyBytes));
        // if (jsonData['ok']) {
        //   result = true;
        // } else {
        //   ShowDialog(context, jsonData["message"], Colors.red);
        // }
      } else {
        ShowDialog(context, 'Ошибка ${response.statusCode}: ${response.body}',
            Colors.red);
      }
    });
  } catch (e) {
    ShowDialog(context, "Упс! Что-то пошло нет так. ($e)", Colors.red);
    return result;
  } finally {
    client.close();
  }
  return result;
}

Future<String> getPreschet(context, String id, bool sale) async {
  var client = http.Client();
  String result = '';
  try {
    bool isOnline = await hasNetwork();

    if (!isOnline) {
      ShowNoInternet(context);
      return result;
    }

    Map<String, dynamic> row = {
      'userId': userId,
      'sale': sale,
      'id': id,
    };

    String data = jsonEncode(row);

    await client
        .post(Uri.parse('http://$srvAddress/$srvBase/hs/$srvCatalog/preschet'),
            headers: <String, String>{'authorization': basicAuth}, body: data)
        .timeout(
          const Duration(seconds: 60),
        )
        .then((response) async {
      if (response.statusCode == 200) {
        var ok = response.headers['ok'];
        if (ok == "0" || ok == null) {
          ShowDialog(context, '${jsonDecode(utf8.decode(response.bodyBytes))}',
              Colors.red);
        } else {
          var bytes = response.bodyBytes;
          var dir = await getApplicationDocumentsDirectory();
          final filename = response.headers['filename'];
          if (filename != null) {
            File file = File("${dir.path}/$filename.pdf");
            await file.writeAsBytes(bytes).then((value) {
              result = value.path;
            });
          }
        }
        // var jsonData = jsonDecode(utf8.decode(response.bodyBytes));
        // if (jsonData['ok']) {
        //   result = true;
        // } else {
        //   ShowDialog(context, jsonData["message"], Colors.red);
        // }
      } else {
        ShowDialog(context, 'Ошибка ${response.statusCode}: ${response.body}',
            Colors.red);
      }
    });
  } catch (e) {
    ShowDialog(context, "Упс! Что-то пошло нет так. ($e)", Colors.red);
    return result;
  } finally {
    client.close();
  }
  return result;
}

Future<String> getReportSales(context, DateTime date) async {
  var client = http.Client();
  String result = '';
  try {
    bool isOnline = await hasNetwork();

    if (!isOnline) {
      ShowNoInternet(context);
      return result;
    }

    Map<String, dynamic> row = {
      'userId': userId,
      'type': 'sales',
      'date': date.millisecondsSinceEpoch
    };

    String data = jsonEncode(row);

    await client
        .post(Uri.parse('http://$srvAddress/$srvBase/hs/$srvCatalog/otchet'),
            headers: <String, String>{'authorization': basicAuth}, body: data)
        .timeout(
          const Duration(seconds: 60),
        )
        .then((response) async {
      if (response.statusCode == 200) {
        var ok = response.headers['ok'];
        if (ok == "0" || ok == null) {
          ShowDialog(context, '${jsonDecode(utf8.decode(response.bodyBytes))}',
              Colors.red);
        } else {
          var bytes = response.bodyBytes;
          var dir = await getApplicationDocumentsDirectory();
          final filename = response.headers['filename'];
          if (filename != null) {
            File file = File("${dir.path}/$filename.pdf");
            await file.writeAsBytes(bytes).then((value) {
              result = value.path;
            });
          }
        }
        // var jsonData = jsonDecode(utf8.decode(response.bodyBytes));
        // if (jsonData['ok']) {
        //   result = true;
        // } else {
        //   ShowDialog(context, jsonData["message"], Colors.red);
        // }
      } else {
        ShowDialog(context, 'Ошибка ${response.statusCode}: ${response.body}',
            Colors.red);
      }
    });
  } catch (e) {
    ShowDialog(context, "Упс! Что-то пошло нет так. ($e)", Colors.red);
    return result;
  } finally {
    client.close();
  }
  return result;
}

Future<bool> auth(context, String login, String pwd) async {
  var client = http.Client();
  bool result = false;
  try {
    bool isOnline = await hasNetwork();

    if (!isOnline) {
      ShowNoInternet(context);
      return result;
    }

    Map<String, dynamic> row = {
      'login': login,
      'pwd': pwd,
    };

    String data = jsonEncode(row);

    await client
        .post(Uri.parse('http://$srvAddress/$srvBase/hs/$srvCatalog/auth'),
            headers: <String, String>{'authorization': basicAuth}, body: data)
        .timeout(
          const Duration(seconds: 60),
        )
        .then((response) async {
      if (response.statusCode == 200) {
        var jsonData = jsonDecode(utf8.decode(response.bodyBytes));
        if (jsonData['ok']) {
          userId = jsonData['result']['id'];
          user = jsonData['result']['name'];
          cashier = jsonData['result']['cashier'];
          editingOrder = jsonData['result']['editingOrder'];
          Map<String, dynamic> row = {'login': login, 'password': pwd};
          dbHelper.insert(row, 'Users');
          result = true;
        } else {
          ShowDialog(context, jsonData["message"], Colors.red);
        }
      } else {
        ShowDialog(context, 'Ошибка ${response.statusCode}: ${response.body}',
            Colors.red);
      }
    });
  } catch (e) {
    ShowDialog(context, "Упс! Что-то пошло нет так. ($e)", Colors.red);
  } finally {
    client.close();
  }
  return result;
}

Future<bool> hasNetwork() async {
  return true;
  // try {
  //   final result = await InternetAddress.lookup('example.com');
  //   return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  // } on SocketException catch (_) {
  //   return false;
  // }
}
