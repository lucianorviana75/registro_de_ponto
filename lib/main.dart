import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

// ================= MODELOS =================

class Funcionario {
  int id;
  String nome;

  Funcionario({required this.id, required this.nome});

  Map<String, dynamic> toMap() => {'id': id, 'nome': nome};

  factory Funcionario.fromMap(Map<String, dynamic> map) =>
      Funcionario(id: map['id'], nome: map['nome']);
}

class Ponto {
  int idFuncionario;
  String data;
  String entrada1;
  String saida1;
  String entrada2;
  String saida2;

  Ponto({
    required this.idFuncionario,
    required this.data,
    this.entrada1 = '',
    this.saida1 = '',
    this.entrada2 = '',
    this.saida2 = '',
  });

  Map<String, dynamic> toMap() => {
        'id_funcionario': idFuncionario,
        'data': data,
        'entrada1': entrada1,
        'saida1': saida1,
        'entrada2': entrada2,
        'saida2': saida2,
      };

  factory Ponto.fromMap(Map<String, dynamic> map) => Ponto(
        idFuncionario: map['id_funcionario'],
        data: map['data'],
        entrada1: map['entrada1'] ?? '',
        saida1: map['saida1'] ?? '',
        entrada2: map['entrada2'] ?? '',
        saida2: map['saida2'] ?? '',
      );
}

// ================= HOME =================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Funcionario> funcionarios = [];
  List<Ponto> pontos = [];

  TextEditingController controllerNome = TextEditingController();
  String status = "Aguardando ação";
  File? jsonFile;

  @override
  void initState() {
    super.initState();
    loadJSON();
  }

  Future<File> getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/registros.json');
  }

  Future<void> loadJSON() async {
    final file = await getFile();
    jsonFile = file;

    if (await file.exists()) {
      final content = await file.readAsString();
      if (content.isNotEmpty) {
        final data = jsonDecode(content);
        funcionarios = (data['funcionarios'] as List)
            .map((f) => Funcionario.fromMap(f))
            .toList();
        pontos =
            (data['pontos'] as List).map((p) => Ponto.fromMap(p)).toList();
      }
    } else {
      await file.writeAsString(jsonEncode({'funcionarios': [], 'pontos': []}));
    }

    setState(() {});
  }

  Future<void> saveJSON() async {
    if (jsonFile == null) return;

    final data = {
      'funcionarios': funcionarios.map((f) => f.toMap()).toList(),
      'pontos': pontos.map((p) => p.toMap()).toList()
    };

    await jsonFile!.writeAsString(jsonEncode(data));
  }

  // ================= FUNCIONÁRIO =================

  void cadastrarFuncionario() {
    String nome = controllerNome.text.trim();
    if (nome.isEmpty) {
      setState(() => status = "Nome inválido");
      return;
    }

    final id = funcionarios.isEmpty ? 1 : funcionarios.last.id + 1;

    funcionarios.add(Funcionario(id: id, nome: nome));
    controllerNome.clear();
    saveJSON();

    setState(() {
      status = "Funcionário cadastrado com sucesso";
    });
  }

  void deletarFuncionario(int id) async {
    bool? confirmar = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirmar exclusão"),
        content:
            const Text("Deseja realmente excluir este funcionário?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Não")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Sim")),
        ],
      ),
    );

    if (confirmar == true) {
      funcionarios.removeWhere((f) => f.id == id);
      pontos.removeWhere((p) => p.idFuncionario == id);
      saveJSON();

      setState(() {
        status = "Funcionário removido";
      });
    }
  }

  // ================= REGISTRAR PONTO =================

  void registrarPonto(Funcionario f) {
    final agora = DateTime.now();
    String data = "${agora.year}-${agora.month}-${agora.day}";
    String hora =
        "${agora.hour.toString().padLeft(2, '0')}:${agora.minute.toString().padLeft(2, '0')}";

    Ponto? pontoHoje;

    try {
      pontoHoje = pontos.firstWhere(
          (p) => p.idFuncionario == f.id && p.data == data);
    } catch (_) {
      pontoHoje = Ponto(idFuncionario: f.id, data: data);
      pontos.add(pontoHoje);
    }

    setState(() {
      if (pontoHoje!.entrada1.isEmpty) {
        pontoHoje.entrada1 = hora;
        status = "Entrada 1 registrada às $hora";
      } else if (pontoHoje.saida1.isEmpty) {
        pontoHoje.saida1 = hora;
        status = "Saída 1 registrada às $hora";
      } else if (pontoHoje.entrada2.isEmpty) {
        pontoHoje.entrada2 = hora;
        status = "Entrada 2 registrada às $hora";
      } else if (pontoHoje.saida2.isEmpty) {
        pontoHoje.saida2 = hora;
        status = "Saída 2 registrada às $hora";
      } else {
        status = "Todos os pontos já registrados hoje";
      }
    });

    saveJSON();
  }

  // ================= INTERFACE =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Controle de Ponto"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: controllerNome,
              decoration: const InputDecoration(
                labelText: "Nome do funcionário",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
                onPressed: cadastrarFuncionario,
                child: const Text("Cadastrar")),
            const SizedBox(height: 20),

            Expanded(
              child: ListView.builder(
                itemCount: funcionarios.length,
                itemBuilder: (context, index) {
                  final f = funcionarios[index];

                  Ponto? pontoHoje;
                  try {
                    pontoHoje = pontos.firstWhere((p) =>
                        p.idFuncionario == f.id &&
                        p.data ==
                            "${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}");
                  } catch (_) {
                    pontoHoje = null;
                  }

                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(f.nome,
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          if (pontoHoje != null) ...[
                            Text("Entrada 1: ${pontoHoje.entrada1}"),
                            Text("Saída 1: ${pontoHoje.saida1}"),
                            Text("Entrada 2: ${pontoHoje.entrada2}"),
                            Text("Saída 2: ${pontoHoje.saida2}"),
                          ] else
                            const Text("Sem registros hoje"),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              ElevatedButton(
                                  onPressed: () => registrarPonto(f),
                                  child:
                                      const Text("Registrar Ponto")),
                              const Spacer(),
                              IconButton(
                                  onPressed: () =>
                                      deletarFuncionario(f.id),
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red))
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: status.contains("registrada")
                    ? Colors.green
                    : status.contains("removido")
                        ? Colors.red
                        : Colors.blue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status,
                style: const TextStyle(color: Colors.white),
              ),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
                onPressed: () async {
                  final dir =
                      await getApplicationDocumentsDirectory();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            "JSON salvo em: ${dir.path}/registros.json")),
                  );
                },
                child: const Text("Mostrar caminho JSON")),
          ],
        ),
      ),
    );
  }
}