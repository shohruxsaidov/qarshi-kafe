import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:number_text_input_formatter/number_text_input_formatter.dart';
import 'package:qarshi_kafe/core/constants.dart';
import 'package:qarshi_kafe/core/integrations.dart' as integrations;
import 'package:qarshi_kafe/core/models.dart';
import 'package:qarshi_kafe/screens/dialogs.dart';
import 'package:qarshi_kafe/screens/payment.dart';
import 'package:qarshi_kafe/screens/pdfviewpage.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

class ScreenReceipt extends StatefulWidget {
  DetailReceipt object;
  bool sale;
  ScreenReceipt({super.key, required this.object, required this.sale});

  @override
  State<ScreenReceipt> createState() => _ScreenOrderState();
}

class _ScreenOrderState extends State<ScreenReceipt> {
  bool loading = false;
  late DetailReceipt object;
  List<ItemsReceipt> items = [];
  bool edited = false;
  bool finish = false;
  // bool refundActive = false;
  List<ItemsReceipt> refunds = [];
  final ScrollController _scrollControllerRefunds = ScrollController();
  double _refundSize = 60;
  num totalRefund = 0;
  // List<ItemsReceipt> allRefunds = [];
  AnimationController? localAnimationController;

  @override
  void initState() {
    object = widget.object;
    super.initState();
    getData();
  }

  getData() async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (object.id.isEmpty) {
      return;
    }
    loading = true;

    var result =
        await integrations.getReceipt(context, id: object.id, widget.sale);
    if (result != null) {
      object = result;
      items = object.items!;
      refunds = object.refunds!;
    }

    updateTotal();

    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        floatingActionButton: ElevatedButton(
          style: ElevatedButton.styleFrom(
              elevation: 8.0,
              shape: const CircleBorder(),
              backgroundColor: Colors.green),
          child: const Icon(
            Icons.add,
            color: Colors.white,
          ),
          onPressed: () async {
            if (!editingOrder && !widget.sale) {
              ShowDialog(
                  context, "У вас нет доступа к редактированию!", Colors.red);
              return;
            }
            await SelectProduct().then((value) {
              updateTotal();
            });
          },
        ),
        bottomNavigationBar: _bottomNavigationBar(),
        appBar: AppBar(
          title: Text(!(!widget.sale)
              ? 'Нал.продажа №${object.number}'
              : 'Стол №${object.table}'),
          actions: [
            TextButton(
                onPressed: () async {
                  if (object.id.isEmpty || edited) {
                    ShowDialog(context, "Сначала сохраните чек!", Colors.red);
                    return;
                  }

                  setState(() {
                    loading = true;
                  });

                  String pathReceipt = await integrations.getPreschet(
                      context, object.id, widget.sale);
                  if (pathReceipt.isNotEmpty) {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => PdfViewPage(
                                  path: pathReceipt,
                                )));
                  }

                  setState(() {
                    loading = false;
                  });
                },
                child: const Text('Пресчет')),
            !(cashier)
                ? const SizedBox()
                : IconButton(
                    onPressed: () {
                      // if (edited) {
                      //   ShowDialog(context, "Сначала сохраняйте изменений!",
                      //       Colors.red);
                      //   return;
                      // }

                      object.items = items;
                      object.refunds = refunds;
                      updateTotal();
                      if (object.total < 0) {
                        ShowDialog(
                            context,
                            "Итого чека меньше 0, проверьте позиций возрата!",
                            Colors.red);
                        return;
                      }
                      Navigator.of(context)
                          .push(MaterialPageRoute(
                              builder: (context) => (ScreenPayment(
                                    object: object,
                                  ))))
                          .then((value) async {
                        if (value == null) {
                          return;
                        }
                        if (value) {
                          num totalPay = 0;
                          for (var i in object.payments!) {
                            totalPay += i.total;
                          }

                          if (totalPay >= object.total) {
                            finish = true;
                          }

                          if (!finish) {
                            ShowDialog(context, "Нет оплаты", Colors.red);
                            return;
                          }

                          if (loading) {
                            ShowDialog(
                                context,
                                "Выполняется синхронизация, подождите!",
                                Colors.green);
                            return;
                          }

                          String pathReceipt = '';
                          var result = await integrations.postPayment(
                              context, object, widget.sale);
                          print(pathReceipt);
                          if (result['success']) {
                            Navigator.of(context).pop(pathReceipt);
                            if (result['path'].isNotEmpty) {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => PdfViewPage(
                                            path: result['path'],
                                          )));
                            }

                            setState(() {
                              loading = false;
                            });
                          }
                        }
                      });
                    },
                    icon: const Icon(Icons.attach_money_outlined))
          ],
        ),
        body: _body());
  }

  updateTotal() {
    object.total = 0;
    totalRefund = 0;

    for (var i in items) {
      object.total = object.total + i.total;
    }
    for (var i in refunds) {
      totalRefund = totalRefund + i.total;
    }
    object.total = object.total - totalRefund;
    setState(() {});
  }

  Future SelectProduct() async {
    TextEditingController searchController = TextEditingController();
    List<Menu> currentMenu = [];
    currentMenu.addAll(menu);
    // List<TextEditingController> Controllers = [];
    for (var i = 0; i < currentMenu.length; i++) {
      String value = '';
      for (var element in items) {
        if (element.id == currentMenu[i].id && element.date == 0) {
          value = element.qt.toString();
        }
      }
      currentMenu[i].controller.text = value;
      // Controllers.add(_controller);
    }
    bool createdTextControllers = false;
    editingAction(item, Menu m, setState, num qt) {
      if (m.price == 0) {
        ShowDialog(context, 'Цена не установлена!', Colors.red);
        return;
      }
      edited = true;
      if (item != null) {
        item.qt = item.qt + qt;
        if (item.qt < 0) {
          item.qt = 0;
        }
        item.total = item.price * item.qt;
      } else {
        if (qt < 0) {
          qt = 0;
        }
        ItemsReceipt item = ItemsReceipt(
            id: m.id,
            price: m.price,
            product: m.product,
            qt: qt,
            total: m.price * qt,
            date: 0);
        items.add(item);
      }
      setState(() {});
    }

    deleteAction(item, setState) {
      if (item == null) {
        return;
      }
      edited = true;
      items.removeAt(items.indexOf(item));
      setState(() {});
    }

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          return ClipRRect(
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30.0),
                topRight: Radius.circular(30.0)),
            child: DraggableScrollableSheet(
              expand: false,
              initialChildSize: .7,
              minChildSize: .7,
              maxChildSize: .85,
              builder: (_, controller) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Container(
                        height: 4,
                        width: 70,
                        color: Colors.black,
                      ),
                    ),
                    Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: TextField(
                          controller: searchController,
                          onChanged: (value) {
                            if (value.isEmpty) {
                              currentMenu.clear();
                              currentMenu.addAll(menu);
                              setState(() {});
                              return;
                            }

                            currentMenu = [];

                            for (var i in menu) {
                              if (i.product.toLowerCase().contains(value)) {
                                if (!currentMenu.contains(i)) {
                                  currentMenu.add(i);
                                }
                              }
                              if (i.price.toString().contains(value)) {
                                if (!currentMenu.contains(i)) {
                                  currentMenu.add(i);
                                }
                              }
                            }

                            setState(() {});
                          },
                          decoration:
                              const InputDecoration(label: Text('Поиск.')),
                        )),
                    Expanded(
                      child: ListView.separated(
                        shrinkWrap: true,
                        controller: controller,
                        itemCount: currentMenu.length,
                        itemBuilder: (_, i) {
                          ItemsReceipt? item;

                          for (var element in items) {
                            if (element.id == currentMenu[i].id &&
                                element.date == 0) {
                              item = element;
                            }
                          }
                          currentMenu[i].controller.selection =
                              TextSelection.fromPosition(TextPosition(
                                  offset:
                                      currentMenu[i].controller.text.length));

                          if (!createdTextControllers) {
                            createdTextControllers = true;
                          }

                          return SizedBox(
                            width: MediaQuery.of(context).size.width,
                            child: Row(children: [
                              SizedBox(
                                width: MediaQuery.of(context).size.width * .7,
                                child: ListTile(
                                  title: Text(
                                    currentMenu[i].product,
                                  ),
                                  subtitle: Text(
                                      "${!(item != null) ? 0 : item.qt.toStringAsFixed(3)} x ${NumberFormat.decimalPattern().format(currentMenu[i].price).replaceAll(',', ' ')} (${currentMenu[i].unit})"),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.only(right: 4),
                                width: MediaQuery.of(context).size.width * .3,
                                height: 100,
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    SizedBox(
                                        height: 40,
                                        child: TextField(
                                          // autofocus: true,
                                          style: const TextStyle(fontSize: 13),
                                          textAlign: TextAlign.right,
                                          controller: currentMenu[i].controller,
                                          inputFormatters: [
                                            FilteringTextInputFormatter.deny(
                                                RegExp(r'[/\\,]')),
                                          ],
                                          keyboardType: TextInputType.number,
                                          decoration: InputDecoration(
                                            suffixIcon: IconButton(
                                              icon: const Icon(
                                                CupertinoIcons.xmark,
                                                size: 8,
                                              ),
                                              onPressed: () {
                                                edited = true;
                                                currentMenu[i].controller.clear;
                                                if (item != null) {
                                                  item.qt = 0;
                                                  deleteAction(item, setState);
                                                }
                                                currentMenu[i].controller.text =
                                                    '0';
                                                setState(() {});
                                              },
                                            ),
                                            border: const OutlineInputBorder(),
                                          ),
                                          onChanged: (value) {
                                            if (value.endsWith('.')) {
                                              return;
                                            }

                                            edited = true;
                                            if (value.isEmpty ||
                                                value == '0.000') {
                                              deleteAction(item, setState);
                                              return;
                                            }

                                            if (item != null) {
                                              item.qt = 0;
                                            }

                                            // Удаляем лишние нули после запятой, если они есть
                                            String qtString = value.replaceAll(
                                                RegExp(r"([.]*0)(?!.*\d)"), "");
                                            print('value $qtString');
                                            num qt = num.parse(value);
                                            print('after $qt');

                                            editingAction(item, currentMenu[i],
                                                setState, qt);
                                          },
                                        )),
                                    Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Card(
                                              color: Colors.red,
                                              child: SizedBox(
                                                  width: 36,
                                                  height: 36,
                                                  child: IconButton(
                                                    onPressed: () {
                                                      edited = true;

                                                      editingAction(
                                                          item,
                                                          currentMenu[i],
                                                          setState,
                                                          -1);

                                                      if (item != null) {
                                                        currentMenu[i]
                                                                .controller
                                                                .text =
                                                            item.qt
                                                                .toStringAsFixed(
                                                                    3);
                                                      }
                                                    },
                                                    icon: const Icon(
                                                      Icons.remove,
                                                      color: Colors.white,
                                                    ),
                                                  ))),
                                          Card(
                                              color: Colors.green,
                                              child: SizedBox(
                                                width: 36,
                                                height: 36,
                                                child: IconButton(
                                                  onPressed: () {
                                                    editingAction(
                                                        item,
                                                        currentMenu[i],
                                                        setState,
                                                        1);
                                                    if (item != null) {
                                                      currentMenu[i]
                                                              .controller
                                                              .text =
                                                          item.qt
                                                              .toStringAsFixed(
                                                                  3);
                                                    }
                                                  },
                                                  icon: const Icon(
                                                    Icons.add,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              )),
                                        ]),
                                  ],
                                ),
                              )
                            ]),
                          );
                        },
                        separatorBuilder: (context, index) {
                          return const Divider();
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        });
      },
    );
  }

  Future ShowDialogQt(
      context, ItemsReceipt item, List<ItemsReceipt> items, bool add) async {
    num orginalQt = item.qt;

    TextEditingController qtController =
        TextEditingController(text: item.qt.toString());
    editingAction(num qt) {
      edited = true;
      item.qt = qt;
      if (item.qt < 0) {
        item.qt = 0;
      }

      item.total = item.price * item.qt;
      qtController.text = item.qt.toString();
    }

    qtController.selection = TextSelection.fromPosition(
        TextPosition(offset: qtController.text.length));
    FocusNode focusNode = FocusNode();

    return showDialog(
      context: context,
      builder: (context) {
        FocusScope.of(context).requestFocus(focusNode);
        return AlertDialog(
            backgroundColor: Colors.white,
            content: SizedBox(
              height: 120,
              child: Column(
                children: [
                  ListTile(
                    title: Text(
                      item.product,
                    ),
                    subtitle: Text(
                        "${item.qt} x ${NumberFormat.decimalPattern().format(item.price).replaceAll(',', ' ')} (${item.unit})"),
                  ),
                  Container(
                    padding: const EdgeInsets.only(right: 4),
                    width: 150,
                    height: 40,
                    child: TextField(
                      // autofocus: true,
                      style: const TextStyle(fontSize: 13),
                      textAlign: TextAlign.right,
                      controller: qtController,
                      focusNode: focusNode,
                      inputFormatters: [
                        NumberTextInputFormatter(
                          integerDigits: 10,
                          decimalDigits: 3,
                          maxValue: '1000000000.00',
                          groupSeparator: ',',
                          allowNegative: false,
                        ),
                      ],
                      keyboardType: TextInputType.number,

                      onChanged: (value) {
                        if (qtController.text[qtController.text.length - 1] ==
                            '.') {
                          return;
                        }
                        if (value.isEmpty) {
                          return;
                        }

                        num qt = num.parse(qtController.text);

                        editingAction(qt);
                      },
                    ),
                  )
                ],
              ),
            ),
            actions: <Widget>[
              ElevatedButton(
                  onPressed: () {
                    num limit = 0;
                    num qt = 0;
                    for (var i in items) {
                      if (i.id == item.id) {
                        limit = limit + i.qt;
                      }
                    }

                    for (var i in refunds) {
                      if (i.id == item.id) {
                        qt = qt + i.qt;
                      }
                    }

                    if (add) {
                      qt = qt + item.qt;
                    }
                    if (limit < qt) {
                      ShowDialog(
                          context,
                          'Превышенно количество: ${qt - limit}! (Всего в заказе: $limit)',
                          Colors.red);
                      item.qt = orginalQt;

                      return;
                    }
                    if (add) items.add(item);

                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'))
            ]);
      },
    );
  }

  Widget _body() {
    return Column(
      children: [
        Text(
            'Счет №: ${!(object.id.isNotEmpty) ? 'Новый заказ' : '${object.number} ${!(object.date > 0) ? '' : timestampToDate(object.date)}'}'),
        Expanded(child: listSales()),
        SizedBox(
            height: _refundSize,
            child: Column(
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero)),
                  onPressed: () {
                    setState(() {
                      if (_refundSize == 60) {
                        _refundSize = 300;
                      } else {
                        _refundSize = 60;
                      }
                    });
                  },
                  child: Container(
                    alignment: Alignment.center,
                    width: MediaQuery.of(context).size.width,
                    height: 40,
                    color: Colors.red,
                    child: Text(
                      "Возвраты $totalRefund (${refunds.length})",
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
                Expanded(
                  child: listRefunds(),
                )
              ],
            )),
      ],
    );
  }

  Widget listSales() {
    return ListView.separated(
      itemCount: items.length,
      itemBuilder: (BuildContext context, int i) {
        return Dismissible(
          key: Key(i.toString()),
          direction: DismissDirection.startToEnd,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerLeft,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                "Возврат",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.endToStart) {
            } else {
              if (!cashier) {
                ShowDialog(context, "У вас нет доступа кассира!", Colors.red);
                return;
              }
              ItemsReceipt item = ItemsReceipt(
                  id: items[i].id,
                  product: items[i].product,
                  qt: items[i].qt,
                  price: items[i].price,
                  total: items[i].total,
                  date: items[i].date);
              setState(() {
                _refundSize = 300;
              });
              _scrollControllerRefunds.animateTo(
                _scrollControllerRefunds.position.maxScrollExtent,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
              );
              ShowDialogQt(context, item, refunds, true).then((value) {
                updateTotal();
                setState(() {});
              });
            }
            return null;
          },
          child: ListTile(
              // contentPadding: EdgeInsets.a/,
              title: Text('${i + 1}. ${items[i].product}'),
              subtitle: Text(
                  '${items[i].qt} x ${items[i].price} = ${NumberFormat.decimalPatternDigits(decimalDigits: 2).format(items[i].total).replaceAll(',', ' ')} \n${DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(items[i].date))}'),
              trailing: SizedBox(
                width: 100,
                child: Row(children: [
                  Card(
                    color: Colors.red,
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: IconButton(
                        onPressed: () async {
                          if (!editingOrder && !widget.sale) {
                            ShowDialog(
                                context,
                                "У вас нет доступа к редактированию!",
                                Colors.red);
                            return;
                          }
                          if (items[i].date > 0) {
                            ShowDialog(
                                context,
                                "Нельзя изменить после подтверждения!",
                                Colors.red);
                            return;
                          }

                          edited = true;
                          var qt = items[i].qt;
                          items[i].qt--;
                          if (items[i].qt < 0) {
                            items[i].qt = 0;
                          }
                          if (items[i].qt <= 0) {
                            await ShowDialogYesNo(context,
                                    "Хотите удалить позицию?", Colors.red)
                                .then((value) {
                              if (value) {
                                setState(() {
                                  items.removeAt(i);
                                });
                              } else {
                                items[i].qt = qt;
                              }
                            });
                          }
                          try {
                            items[i].total = items[i].price * items[i].qt;
                          } catch (e) {
                            print('$e');
                          }
                          updateTotal();
                        },
                        icon: const Icon(Icons.remove),
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Card(
                      color: Colors.green,
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: IconButton(
                          onPressed: () {
                            if (!editingOrder && !widget.sale) {
                              ShowDialog(
                                  context,
                                  "У вас нет доступа к редактированию!",
                                  Colors.red);
                              return;
                            }
                            if (items[i].date > 0) {
                              ShowDialog(
                                  context,
                                  "Нельзя изменить после подтверждения!",
                                  Colors.red);
                              return;
                            }
                            edited = true;
                            // setState(() {
                            items[i].qt++;
                            items[i].total = items[i].price * items[i].qt;
                            // });
                            updateTotal();
                          },
                          icon: const Icon(Icons.add),
                          // iconSize: 24,
                          color: Colors.white,
                        ),
                      )),
                ]),
              )),
        );
      },
      separatorBuilder: (context, index) {
        return const Divider();
      },
    );
  }

  Widget listRefunds() {
    return ListView.separated(
      itemCount: refunds.length,
      controller: _scrollControllerRefunds,
      itemBuilder: (BuildContext context, int i) {
        return ListTile(
            // tileColor: !(refunds[i].qt != 0) ? null : Colors.red,
            title: Text('${i + 1}. ${refunds[i].product}'),
            subtitle: Text(
                '${refunds[i].qt} x ${refunds[i].price} = ${refunds[i].total}'),
            trailing: !(cashier)
                ? null
                : SizedBox(
                    width: 100,
                    child: Row(
                      children: [
                        Card(
                          color: Colors.red,
                          child: SizedBox(
                            width: 40,
                            height: 40,
                            child: IconButton(
                              onPressed: () async {
                                ShowDialogYesNo(
                                        context, "Удалить позицию?", Colors.red)
                                    .then((value) {
                                  if (value) {
                                    refunds.removeAt(i);
                                    updateTotal();
                                  }
                                });
                              },
                              icon: const Icon(Icons.delete),
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Card(
                          color: Colors.green,
                          child: SizedBox(
                            width: 40,
                            height: 40,
                            child: IconButton(
                              onPressed: () async {
                                ShowDialogQt(
                                        context, refunds[i], refunds, false)
                                    .then((value) {
                                  setState(() {
                                    edited = true;
                                    updateTotal();
                                  });
                                  ();
                                });
                              },
                              icon: const Icon(Icons.edit),
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ));
      },
      separatorBuilder: (context, index) {
        return const Divider();
      },
    );
  }

  Widget _bottomNavigationBar() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.zero)),
          backgroundColor: !(finish) ? Colors.blue : Colors.green,
          elevation: 8.0),
      child: Container(
        alignment: Alignment.center,
        width: MediaQuery.of(context).size.width,
        height: 60,
        child: !(loading)
            ? Text(
                'Всего: ${NumberFormat.decimalPattern().format(object.total).replaceAll(',', ' ')} (Возврат: $totalRefund)',
                style: const TextStyle(color: Colors.white, fontSize: 18),
              )
            : const CircularProgressIndicator(),
      ),
      onPressed: () async {
        bool success = false;

        if (loading) {
          ShowDialog(
              context, "Выполняется синхронизация, подождите!", Colors.green);
          return;
        }
        await ShowDialogYesNo(context, "Отправить чек?", Colors.green)
            .then((value) async {
          if (value) {
            setState(() {
              loading = true;
            });

            object.items = items;
            object.refunds = refunds;

            Map result =
                await integrations.postReceipt(context, object, widget.sale);

            if (result['success']) {
              Navigator.of(context).pop(true);
              showTopSnackBar(
                Overlay.of(context),
                CustomSnackBar.info(
                  message: !(result['hasOrder'])
                      ? 'Нет заказов кухню!'
                      : 'Успешно отправлен заказ кухню!',
                  backgroundColor:
                      !(result['hasOrder']) ? Colors.red : Colors.green,
                  textStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 21),
                ),
                persistent: false,
                onAnimationControllerInit: (controller) {
                  localAnimationController = controller;
                },
              );
            }
            setState(() {
              loading = false;
            });
          }
        });
      },
    );
  }
}
