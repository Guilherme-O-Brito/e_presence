import 'dart:convert';
import 'dart:io';

import 'package:e_presence/models/student.dart';
import 'package:e_presence/pages/home.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ClassroomPage extends StatefulWidget {
  final String classRoomName;
  final String classRoomDesc;
  final String roomName;

  const ClassroomPage({
    required this.classRoomName,
    required this.roomName,
    required this.classRoomDesc,
    super.key,
  });

  @override
  State<ClassroomPage> createState() => _ClassroomPageState();
}

enum ClassState { inClass, endedClass }

class _ClassroomPageState extends State<ClassroomPage> {
  ClassState _classState = ClassState.inClass;
  late final MqttServerClient client;

  List<Student> students = [];

  Future<void> _generateExcel(List<Student> students, String classRoomName, String description) async {
    // criando planilha do excel
    final excel = Excel.createExcel();
    // acessando e formatando a data do dispositivo
    final String date = DateFormat('dd-MM-yyyy').format(DateTime.now());
    // nome da planilha
    final String spreadsheetName = '$classRoomName $date';

    // inicia colunas
    final Sheet sheet = excel[spreadsheetName];
    sheet.appendRow(['Aula', spreadsheetName]);
    sheet.appendRow(['Descrição', description]);
    sheet.appendRow(['Nome', 'Matricula']);

    // adiciona todas as linhas com os nomes e matriculas do aluno
    for (Student student in students) {
      sheet.appendRow([student.nome, student.matricula]);
    }

    // cria um arquivo temporario apenas para compartilhar a planilha
    final tempDir = await getTemporaryDirectory();
    final tempPath = '${tempDir.path}/$spreadsheetName.xlsx';
    final tempFile = File(tempPath);
    await tempFile.writeAsBytes(excel.encode()!);

    // compartilha o arquivo
    await Share.shareXFiles([XFile(tempFile.path)], text: 'Lista de presenças na aula $classRoomName');

    // deleta o arquivo temporario
    await tempFile.delete();
    
  }

  // de acordo com o estado atual da aula retorna o botão correto
  Widget _getButton() {
    switch (_classState) {
      case ClassState.inClass:
        return ElevatedButton(
          key: ValueKey('Encerrar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            elevation: 3,
          ),
          onPressed: () {
            setState(() {
              client.disconnect();
              _classState = ClassState.endedClass;
              // volta pro menu diretamente caso a lista de alunos esteja vazia
              if (students.isEmpty) {
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    // ignore: use_build_context_synchronously
                    context, 
                    MaterialPageRoute(builder: (context) => Home()), 
                    (Route<dynamic> route) => false,
                  );
                }
              }
            });
          },
          child: Text('Encerrar Aula', style: TextStyle(fontSize: 20)),
        );
      case ClassState.endedClass:
        return ElevatedButton(
          key: ValueKey('Sair'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            elevation: 3,
          ),
          onPressed: () async {
            await _generateExcel(students, widget.classRoomName, widget.classRoomDesc);
            
            if (context.mounted) {
              Navigator.pushAndRemoveUntil(
                // ignore: use_build_context_synchronously
                context, 
                MaterialPageRoute(builder: (context) => Home()), 
                (Route<dynamic> route) => false,
              );
            }
            
          },
          child: Text(
            'Gerar Tabela de Chamada e Sair',
            style: TextStyle(fontSize: 20),
          ),
        );
    }
  }

  Future<void> _connectToBroker() async {
    client.port = 1883;
    client.logging(on: false);
    client.onDisconnected = () {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('O cliente foi desconectado!'))
      );
    };
    client.onConnected = () {
      client.subscribe('e_presence/inatel/${widget.roomName}', MqttQos.atLeastOnce);
    };
    client.onSubscribed = (String topic) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Conectado a $topic com sucesso!'))
      );
    };
    client.onSubscribeFail = (String topic) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possivel se conectar a $topic!'))
      );
    };

    try {
      await client.connect();
      client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        final message = c[0].payload as MqttPublishMessage;
        final payload = MqttPublishPayload.bytesToStringAsString(message.payload.message);
        final Map<String, dynamic> data = jsonDecode(payload);
        setState(() {
          // cria novo student e envia pra lista students
          students.add(Student(nome: data['nome']!, matricula: data['matricula']!));
        });
      });
    } catch (e) {
      client.disconnect();
      if (context.mounted) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ocorreu um erro ao se conectar!'))
        );
      }
    }

  }

  @override
  void initState() {
    super.initState();
    // Iniciar o cliente MQTT com o nome da aula e o datetime para garantir unicidade no client id
    client = MqttServerClient('broker.hivemq.com', '${widget.classRoomName}_${DateTime.now().millisecondsSinceEpoch}');
    _connectToBroker();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: Center(
            child: Text(
              widget.classRoomName,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          backgroundColor: const Color.fromARGB(255, 33, 54, 243),
          automaticallyImplyLeading: false,
        ),
        body: Stack(
          children: [
            ListView.builder(
              itemCount: students.length,
              itemBuilder: (context, index) {
                return Card(
                  elevation: 2,
                  child: ListTile(
                    title: Text(students[index].nome),
                    subtitle: Text(students[index].matricula),
                    trailing: Icon(Icons.account_circle),
                  ),
                );
              },
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: AnimatedSwitcher(
                  duration: Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(scale: animation, child: child);
                  },
                  child: _getButton(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
