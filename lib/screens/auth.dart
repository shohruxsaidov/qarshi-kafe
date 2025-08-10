import 'package:flutter/material.dart';
import 'package:qarshi_kafe/core/constants.dart';
import 'package:qarshi_kafe/core/integrations.dart' as integrations;
import 'package:qarshi_kafe/screens/dialogs.dart';
import 'package:qarshi_kafe/screens/menu.dart';

class ScreenAuth extends StatefulWidget {
  const ScreenAuth({super.key});

  @override
  State<ScreenAuth> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<ScreenAuth> {
  final _loginController = TextEditingController(text: '');
  final _passwordController = TextEditingController(text: '');
  final _adressController = TextEditingController(text: srvAddress);
  bool loading = false;

  @override
  void initState() {
    openBase();
    checkUser();
    super.initState();
    startAuth();
  }

  void openBase() async {
    await dbHelper.database;
  }

  startAuth() async {
    const Duration(milliseconds: 100);

    if (_loginController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty) {
      authorization();
    }
  }

  void checkUser() async {
    var result = await dbHelper.getUser();
    if (result != null) {
      _loginController.text = result['login'];
      _passwordController.text = result['password'];
      authorization();
    }
  }

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    _adressController.dispose();
    super.dispose();
  }

  authorization() async {
    if (_loginController.text.isEmpty) {
      ShowDialog(context, 'Заполняйте логин!', Colors.red);
      return;
    }

    if (_passwordController.text.isEmpty) {
      ShowDialog(context, 'Заполняйте пароль!', Colors.red);
      return;
    }

    if (loading) {
      ShowDialog(context, 'Подождите, выполняется синхронизация!', Colors.red);
      return;
    }
    setState(() {
      loading = true;
    });

    bool success = await integrations.auth(
        context, _loginController.text, _passwordController.text);
    if (success) {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => (const ScreenMenu())));
    }

    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
        const SizedBox(
          height: 100,
        ),
        SizedBox(
          width: MediaQuery.of(context).size.width * .7,
          child: Row(
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width * .5,
                child: TextField(
                  decoration:
                      const InputDecoration(label: Text('Адрес сервера')),
                  onChanged: (value) {
                    setState(() {
                      srvAddress = value;
                    });
                  },
                  controller: _adressController,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(
          height: 40,
        ),
        Padding(
            padding: const EdgeInsets.only(bottom: 20, top: 5),
            child: _input(const Icon(Icons.account_circle_outlined), "ЛОГИН",
                _loginController, false)),
        Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: _input(
                const Icon(Icons.lock), "ПАРОЛЬ", _passwordController, true)),
        Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              height: 40,
              child: ElevatedButton(
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.white),
                  child: Container(
                      alignment: Alignment.center,
                      width: 200,
                      height: 60,
                      child: !(loading)
                          ? const Text('Войти',
                              style: TextStyle(color: Colors.black))
                          : const CircularProgressIndicator()),
                  onPressed: () async {
                    authorization();
                  }),
            )),
      ]),
    );
  }

  Widget _input(
      Icon icon, String hint, TextEditingController controller, bool obscure) {
    return Container(
      height: 55,
      padding: const EdgeInsets.only(left: 20, right: 20),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(fontSize: 18, color: Colors.black),
        decoration: InputDecoration(
            hintStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black26),
            hintText: hint,
            focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.black, width: 1)),
            enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.black, width: 1)),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 10, right: 10),
              child: IconTheme(
                  data: const IconThemeData(color: Colors.black54),
                  child: icon),
            )),
      ),
    );
  }
}
