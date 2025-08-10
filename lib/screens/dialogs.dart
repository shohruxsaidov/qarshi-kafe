import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void ShowDialog(context, text_, color) async {
  return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          content: SingleChildScrollView(
            child: Text(
              text_.toString(),
              style: TextStyle(color: color, fontSize: 12),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'ОК',
                style: TextStyle(color: Colors.black),
              ),
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
              },
            ),
          ],
        );
      });
}

void ShowNoInternet(context) async {
  return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          content: SizedBox(
            height: 120,
            width: MediaQuery.of(context).size.width -
                (MediaQuery.of(context).size.width / 8),
            child: const Column(
              children: [
                Icon(CupertinoIcons.wifi_slash, size: 64, color: Colors.red),
                Text(
                  "Нет интернета",
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  height: 5,
                ),
                Text(
                  "Проверьте интернет-соединение или перезапустите приложенине",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('ОК'),
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
              },
            ),
          ],
        );
      });
}

Future<bool> ShowDialogYesNo(context, text_, color) async {
  // bool result = false;
  bool result = false;

  await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          content: Text(
            '$text_',
            style: TextStyle(
                color: color, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Да',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: () {
                result = true;
                Navigator.of(context, rootNavigator: true).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
              child: const Text(
                'Нет',
                style:
                    TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                result = false;
                Navigator.of(context, rootNavigator: true).pop();
              },
            ),
          ],
        );
      });

  return result;
}
