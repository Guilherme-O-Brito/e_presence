import 'package:e_presence/pages/classroom_page.dart';
import 'package:flutter/material.dart';

class CreateClassroom extends StatefulWidget {
  const CreateClassroom({super.key});

  @override
  State<CreateClassroom> createState() => _CreateClassroomState();
}

class _CreateClassroomState extends State<CreateClassroom> {
  final _formKey = GlobalKey<FormState>();
  final _classRoomName = TextEditingController();
  final _classRoomDesc = TextEditingController();
  final _roomName = TextEditingController();
  final invalidCharacters = ['#', '+', '\$', '/', '\\', ' ', '\n', '\t']; // lista com caracteres invalidos para conexão com o broker

  @override
  void dispose() {
    _classRoomName.dispose();
    _classRoomDesc.dispose();
    _roomName.dispose();
    super.dispose();
  }

  _createClassRoom() {
    if (_formKey.currentState!.validate()) {
      String name = _classRoomName.text;
      String desc = _classRoomDesc.text;
      String room = _roomName.text;

      Navigator.push(context, MaterialPageRoute(builder: (context) => ClassroomPage(classRoomName: name, roomName: room, classRoomDesc: desc)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: const Text(
            'Iniciar Nova Aula',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 33, 54, 243),
      ),
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            // Garante o alinhamento central do formulario considerando tamanho da tela, tamanho do app bar e padding aplicado
            minHeight:
                MediaQuery.of(context).size.height -
                kToolbarHeight -
                MediaQuery.of(context).padding.top,
          ),
          child: IntrinsicHeight(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextFormField(
                      controller: _classRoomName,
                      style: TextStyle(fontSize: 22),
                      decoration: InputDecoration(
                        label: const Text('Nome da Aula'),
                      ),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Informe o nome da aula';
                        } 
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _roomName,
                      style: TextStyle(fontSize: 22),
                      decoration: InputDecoration(
                        label: const Text('Sala de Aula'),
                      ),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Informe a sala de aula';
                        } else {
                          for (final char in invalidCharacters) {
                            if (value.contains(char)) {
                              return 'O nome não pode conter ${invalidCharacters.join(" ")}';
                            }
                          }
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _classRoomDesc,
                      style: TextStyle(fontSize: 22),
                      decoration: InputDecoration(
                        label: const Text('Descrição'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _createClassRoom,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        elevation: 3,
                      ),
                      child: const Text(
                        'Iniciar Aula',
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
