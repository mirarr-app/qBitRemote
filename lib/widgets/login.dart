import 'package:flutter/material.dart';

class AddServer extends StatefulWidget {
  final Function(String, String, String) onLogin;

  AddServer({Key? key, required this.onLogin}) : super(key: key);

  @override
  _AddServerState createState() => _AddServerState();
}

class _AddServerState extends State<AddServer> {
  final TextEditingController _serverUrlController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(20)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Add Server',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            autocorrect: false,
            style: const TextStyle(
              color: Colors.black,
            ),
            cursorColor: Colors.black,
            controller: _serverUrlController,
            keyboardType: TextInputType.text,
            decoration: InputDecoration(
              labelText: 'Server URL',
              labelStyle: const TextStyle(
                  color: Colors.black, fontWeight: FontWeight.bold),
              filled: true,
              fillColor: Colors.orangeAccent[200],
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.orange),
                borderRadius: BorderRadius.circular(10.0),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.orange),
                borderRadius: BorderRadius.circular(10.0),
              ),
              floatingLabelBehavior: FloatingLabelBehavior.never,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            autocorrect: false,
            style: const TextStyle(
              color: Colors.black,
            ),
            cursorColor: Colors.black,
            controller: _usernameController,
            keyboardType: TextInputType.text,
            decoration: InputDecoration(
              labelText: 'Username',
              labelStyle: const TextStyle(
                  color: Colors.black, fontWeight: FontWeight.bold),
              filled: true,
              fillColor: Colors.orangeAccent[200],
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.orange),
                borderRadius: BorderRadius.circular(10.0),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.orange),
                borderRadius: BorderRadius.circular(10.0),
              ),
              floatingLabelBehavior: FloatingLabelBehavior.never,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            obscureText: true,
            autocorrect: false,
            style: const TextStyle(
              color: Colors.black,
            ),
            cursorColor: Colors.black,
            controller: _passwordController,
            keyboardType: TextInputType.visiblePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              labelStyle: const TextStyle(
                  color: Colors.black, fontWeight: FontWeight.bold),
              filled: true,
              fillColor: Colors.orangeAccent[200],
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.orange),
                borderRadius: BorderRadius.circular(10.0),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.orange),
                borderRadius: BorderRadius.circular(10.0),
              ),
              floatingLabelBehavior: FloatingLabelBehavior.never,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              widget.onLogin(
                _serverUrlController.text.trim(),
                _usernameController.text.trim(),
                _passwordController.text.trim(),
              );
              Navigator.pop(context);
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }
}
