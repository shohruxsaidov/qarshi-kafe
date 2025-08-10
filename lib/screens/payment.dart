import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:number_text_input_formatter/number_text_input_formatter.dart';
import 'package:qarshi_kafe/core/models.dart';
import 'package:qarshi_kafe/screens/dialogs.dart';

class ScreenPayment extends StatefulWidget {
  DetailReceipt object;

  ScreenPayment({super.key, required this.object});

  @override
  State<ScreenPayment> createState() => _ScreenPaymentState();
}

class _ScreenPaymentState extends State<ScreenPayment> {
  final TextEditingController _cashPay = TextEditingController(text: '0');
  final TextEditingController _terminalPay = TextEditingController(text: '0');
  final TextEditingController _transferPay = TextEditingController(text: '0');
  List _controllers = [];
  num total = 100000;
  num totalPay = 0;
  late DetailReceipt object;

  @override
  void initState() {
    total = widget.object.total;
    super.initState();
    _controllers = [_cashPay, _terminalPay, _transferPay];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Всего: $total'),
      ),
      bottomNavigationBar: _bottomNavigationBar(),
      body: SizedBox(
        width: MediaQuery.of(context).size.width,
        // height: media,
        child: ListView(
          children: [
            itemPayment(
              'Наличная',
              _cashPay,
            ),
            itemPayment(
              'Перевод',
              _transferPay,
            ),
            itemPayment('Терминал', _terminalPay),
          ],
        ),
      ),
    );
  }

  Widget _bottomNavigationBar() {
    return Padding(
        padding: const EdgeInsets.only(bottom: 20, left: 40, right: 40),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green, elevation: 8.0),
          child: Text(
            'Оплачено: ${NumberFormat.decimalPattern().format(totalPay).replaceAll(',', ' ')}',
            style: const TextStyle(color: Colors.white),
          ),
          onPressed: () async {
            if (totalPay < total) {
              ShowDialog(context, "Сумма оплаты меньше сумма чека", Colors.red);
              return;
            }
            List<Payments> payments = [];

            for (var _controller in _controllers) {
              num value = 0;
              if (_controller.text.isEmpty) {
                continue;
              } else {
                value = num.parse(_controller.text);
              }

              Payments? payment;
              if (_controller == _cashPay) {
                payment = Payments(type: 'cash', total: value);
              }

              if (_controller == _transferPay) {
                payment = Payments(type: 'transfer', total: value);
              }

              if (_controller == _terminalPay) {
                payment = Payments(type: 'terminal', total: value);
              }

              if (payment == null) {
                ShowDialog(context, 'Неправильный вид оплаты!', Colors.red);
                return;
              }
              payments.add(payment);
            }

            if (payments.isNotEmpty) {
              widget.object.payments = payments;
              Navigator.of(context).pop(true);
            }
          },
        ));
  }

  Widget itemPayment(String name, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        color: Colors.white,
        elevation: 8.0,
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(
              height: 40,
              width: 150,
              child: TextField(
                controller: controller,
                inputFormatters: [
                  NumberTextInputFormatter(
                    integerDigits: 10,
                    decimalDigits: 2,
                    maxValue: '1000000000.00',
                    decimalSeparator: '.',
                    // groupDigits: 1,
                    groupSeparator: ',',
                    allowNegative: false,
                    overrideDecimalPoint: true,
                    insertDecimalPoint: false,
                    insertDecimalDigits: true,
                  ),
                ],
                onChanged: (value) {
                  num toPay0 = calculatetoPay(controller);
                  num currentPay = 0;
                  if (value.isEmpty) {
                    currentPay = 0;
                    return;
                  } else {
                    currentPay = num.parse(controller.text);
                  }

                  if (currentPay > 0 && currentPay > toPay0) {
                    controller.text = toPay0.toString();
                  }
                  calculatetotalPay();
                },
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  // labelText:
                  //     э
                  border: OutlineInputBorder(),
                ),
              )),
          IconButton(
              onPressed: () async {
                num toPay = calculatetoPay(controller);
                controller.text = toPay.toString();

                calculatetotalPay();
              },
              icon: const Icon(Icons.add)),
        ]),
      ),
    );
  }

  calculatetotalPay() {
    totalPay = 0;
    for (var i in _controllers) {
      if (i.text.isEmpty) {
        continue;
      }

      totalPay = totalPay + num.parse(i.text);
    }

    setState(() {});
  }

  num calculatetoPay(controller) {
    if (controller.text.isEmpty) {
      return 0;
    }
    num currentPay = num.parse(controller.text);
    num toPay = total;

    for (var i in _controllers) {
      if (controller == i) {
        continue;
      }
      if (i.text.isEmpty) {
        i.text = '0';
      }
      num iPay = num.parse(i.text);
      toPay = toPay - iPay;
    }

    return toPay;
  }
}
