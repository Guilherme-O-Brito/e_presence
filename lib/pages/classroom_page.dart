import 'dart:io';

import 'package:e_presence/models/student.dart';
import 'package:e_presence/pages/home.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ClassroomPage extends StatefulWidget {
  final String classRoomName;
  final String classRoomDesc;

  const ClassroomPage({
    required this.classRoomName,
    required this.classRoomDesc,
    super.key,
  });

  @override
  State<ClassroomPage> createState() => _ClassroomPageState();
}

enum ClassState { inClass, endedClass }

Future<void> _generateExcel(List<Student> students, String classRoomName) async {
    // criando planilha do excel
    final excel = Excel.createExcel();
    // acessando e formatando a data do dispositivo
    final String date = DateFormat('dd-MM-yyyy').format(DateTime.now());
    // nome da planilha
    final String spreadsheetName = '$classRoomName $date';

    // inicia colunas
    final Sheet sheet = excel[spreadsheetName];
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

class _ClassroomPageState extends State<ClassroomPage> {
  ClassState _classState = ClassState.inClass;

  List<Student> students = [
    Student(nome: 'Guilherme', matricula: 'GEC-1940'),
    Student(nome: 'Eduardo', matricula: 'GEC-1939'),
    Student(nome: 'Alexandre', matricula: 'GES-1254'),
  ];

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
              _classState = ClassState.endedClass;
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
            await _generateExcel(students, widget.classRoomName);
            
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
