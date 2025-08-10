import 'package:flutter/material.dart';
import 'package:qarshi_kafe/core/constants.dart';
import 'package:qarshi_kafe/core/integrations.dart' as integrations;
import 'package:qarshi_kafe/core/models.dart';
import 'package:qarshi_kafe/screens/dialogs.dart';
import 'package:qarshi_kafe/screens/receipt.dart';

class ScreenSales extends StatefulWidget {
  const ScreenSales({super.key});

  @override
  State<ScreenSales> createState() => _ScreenSalesState();
}

class _ScreenSalesState extends State<ScreenSales> {
  List<DetailReceipt> items = [];
  bool loading = false;
  @override
  void initState() {
    super.initState();
    getData();
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

    var result = await integrations.getReceipt(context, true);

    if (result != null) {
      items = result;
    }

    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Наличная торговля (${items.length})')),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 18.0, right: 8),
          child: Card(
            color: Colors.green,
            child: IconButton(
              icon: const Icon(
                Icons.add,
                color: Colors.white,
              ),
              onPressed: () {
                DetailReceipt item = DetailReceipt(
                    id: '',
                    tableId: '',
                    table: '',
                    total: 0,
                    author: user,
                    authorId: userId,
                    date: 0,
                    number: '',
                    version: '');

                Navigator.of(context)
                    .push(MaterialPageRoute(
                        builder: (context) =>
                            (ScreenReceipt(object: item, sale: true))))
                    .then((value) {
                  getData();
                });
              },
            ),
          ),
        ),
        body: !(loading)
            ? Padding(
                padding: const EdgeInsets.all(4),
                child: RefreshIndicator(
                    onRefresh: getData,
                    child: ListView.separated(
                      itemCount: items.length,
                      itemBuilder: (BuildContext context, int i) {
                        return ListTile(
                          title: Text('№${items[i].number}'),
                          subtitle: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  '${!(items[i].id.isEmpty) ? timestampToDate(items[i].date) : 0}'),
                              Text(items[i].author),
                            ],
                          ),
                          trailing: Text('${items[i].total} сум'),
                          onTap: () {
                            Navigator.of(context)
                                .push(MaterialPageRoute(
                                    builder: (context) => (ScreenReceipt(
                                          object: items[i],
                                          sale: true,
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
                    )),
              )
            : const Center(
                child: CircularProgressIndicator(),
              ));
  }
}
