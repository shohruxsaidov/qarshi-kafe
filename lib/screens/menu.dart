import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qarshi_kafe/core/constants.dart';
import 'package:qarshi_kafe/core/integrations.dart' as integrations;
import 'package:qarshi_kafe/core/models.dart';
import 'package:qarshi_kafe/screens/auth.dart';
import 'package:qarshi_kafe/screens/dialogs.dart';
import 'package:qarshi_kafe/screens/list_sales.dart';
import 'package:qarshi_kafe/screens/pdfviewpage.dart';
import 'package:qarshi_kafe/screens/receipt.dart';

class ScreenMenu extends StatefulWidget {
  const ScreenMenu({super.key});

  @override
  State<ScreenMenu> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<ScreenMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<DetailReceipt> items = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    getMenu();
    getData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  getMenu() {
    integrations.getMenu(context);
  }

  Future<void> getData() async {
    if (loading) {
      ShowDialog(
          context, "Выполняется синхронизация, подождите!", Colors.green);
      return;
    }
    setState(() {
      loading = true;
    });

    var result = await integrations.getReceipt(context, false);

    if (result != null) {
      items = result;
    }

    setState(() {
      loading = false;
    });
  }

  Future<bool> ShowDialogExit(context) async {
    bool result = false;
    await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: const Text('Вы действительно хотите выйти из программы?'),
            actions: <Widget>[
              TextButton(
                  child: const Text('Да, выйти',
                      style: TextStyle(color: Colors.blue, fontSize: 18)),
                  onPressed: () {
                    SystemNavigator.pop();
                    result = true;
                  }),
              TextButton(
                child: const Text('Нет'),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
              TextButton(
                child: const Text('Выйти из аккаунта',
                    style: TextStyle(color: Colors.red, fontSize: 14)),
                onPressed: () async {
                  dbHelper.clearTables();
                  Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                          builder: (context) => const ScreenAuth()),
                      (Route<dynamic> route) => false);
                },
              ),
            ],
          );
        });

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        var value = ShowDialogExit(context);
        return value;
      },
      child: Scaffold(
          floatingActionButton: !(cashier)
              ? null
              : ElevatedButton(
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text(
                    'Нал.продажа',
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => (const ScreenSales())));
                  },
                ),
          appBar: AppBar(
            title: Text(
              "Заметка ($user)",
              style: const TextStyle(fontSize: 18),
            ),
            actions: [
              !(cashier)
                  ? const SizedBox()
                  : IconButton(
                      onPressed: () async {
                        await showDatePicker(
                                context: context,
                                firstDate: DateTime(2023),
                                lastDate: DateTime(2030))
                            .then((value) async {
                          if (loading) {
                            ShowDialog(
                                context,
                                "Выполняется синхронизация, подождите!",
                                Colors.green);
                            return;
                          }
                          setState(() {
                            loading = true;
                          });

                          String pathReceipt = await integrations
                              .getReportSales(context, value!);
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
                        });
                      },
                      icon: const Icon(Icons.list_alt_sharp)),
              IconButton(
                  onPressed: () async {
                    bool success = await integrations.getMenu(context);
                    if (success) {
                      ShowDialog(
                          context, "Меню успешно обновлено!", Colors.green);
                    }
                  },
                  icon: const Icon(Icons.list)),
            ],
          ),
          body: !(loading)
              ? Column(
                  children: [
                    Text('Версия: $version'),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: getData,
                        child: ListView.separated(
                          itemCount: items.length,
                          itemBuilder: (BuildContext context, int i) {
                            return ListTile(
                              tileColor: !(items[i].id.isEmpty)
                                  ? Colors.amber[100]
                                  : null,
                              title: Text('Стол №${items[i].table}'),
                              subtitle: Text(
                                  '${!(items[i].id.isEmpty) ? timestampToDate(items[i].date) : 0}'),
                              trailing: Text('${items[i].total} сум'),
                              onTap: () {
                                if (!cashier) {
                                  if (items[i].authorId.isNotEmpty &&
                                      items[i].authorId != userId) {
                                    ShowDialog(context, 'Чек заблокирован!',
                                        Colors.red);
                                    return;
                                  }
                                }
                                Navigator.of(context)
                                    .push(MaterialPageRoute(
                                        builder: (context) => (ScreenReceipt(
                                              object: items[i],
                                              sale: false,
                                            ))))
                                    .then((value) {
                                  getData();
                                });
                              },
                            );
                          },
                          separatorBuilder: (context, index) {
                            return const Divider();
                          },
                        ),
                      ),
                    ),
                  ],
                )
              : const Center(
                  child: CircularProgressIndicator(),
                )),
    );
  }
}
