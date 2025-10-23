import 'package:flutter/material.dart';

void main() {
  runApp(const MeuApp());
}

class MeuApp extends StatelessWidget {
  const MeuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lista de Compras',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const TelaDaLista(),
    );
  }
}

class TelaDaLista extends StatefulWidget {
  const TelaDaLista({super.key});

  @override
  State<TelaDaLista> createState() => _TelaDaListaState();
}

class _TelaDaListaState extends State<TelaDaLista> {
  final List<String> itensDaLista = [
    'Maçãs',
    'Leite',
    'Pão',
    'Manteiga',
    'Ovos',
  ];

  Future<void> _mostrarDialogoAdicionarItem() async {
    final TextEditingController controladorTexto = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Adicionar Novo Item'),
          content: TextField(
            controller: controladorTexto,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Nome do item'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Adicionar'),
              onPressed: () {
                final String novoItem = controladorTexto.text;
                if (novoItem.isNotEmpty) {
                  setState(() {
                    itensDaLista.add(novoItem);
                  });
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minha Lista de Compras'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.black,
      ),
      body: ListView.builder(
        itemCount: itensDaLista.length,
        itemBuilder: (BuildContext context, int index) {
          return ListTile(
            title: Text(itensDaLista[index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarDialogoAdicionarItem,
        child: const Icon(Icons.add),
        backgroundColor: Colors.green,
      ),
    );
  }
}