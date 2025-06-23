# 📡 e-Presence: Sistema de Chamada IoT

Projeto desenvolvido na disciplina **C115** na **INATEL**.

O objetivo é criar um **protótipo funcional de um sistema de chamadas por IoT**. A proposta é que cada sala de aula possua um **leitor NFC**, e os alunos registrem sua presença simplesmente ao **aproximarem a carteira da faculdade** do leitor. O professor acompanha os dados em **tempo real através de um aplicativo móvel**.

---

## 🔧 Tecnologias Utilizadas

- **ESP32**: Microcontrolador principal
- **RFID RC522**: Leitor NFC para cartões
- **Flutter (Dart)**: Desenvolvimento do aplicativo mobile
- **MQTT (HiveMQ)**: Comunicação entre o ESP32 e o app
- **PlatformIO (C++)**: Ambiente de desenvolvimento da firmware

---

## ⚙️ Pinagem do ESP32

| Componente        | Pino ESP32 |
|-------------------|------------|
| Buzzer            | GPIO4        |
| LED Verde (✔️)     | GPIO21       |
| LED Vermelho (❌)  | GPIO22       |
| SDA (CS)          | GPIO5        |
| SCK               | GPIO18       |
| MISO              | GPIO19       |
| MOSI              | GPIO23       |

> ⚠️ O leitor RFID RC522 deve ser alimentado com **3.3V** (⚠️ **não** use 5V).  
> Também foram utilizados **resistores de 330Ω** nos LEDs.

### 🖼️ Gabarito de Pinagem ESP32

<img src="firmware/e_presence/esp_pinout.webp"/>

---

## 📁 Organização do Projeto

- `firmware/e_presence/src/` → Código-fonte em C++ para o ESP32  
- `lib/` → Código-fonte do app Flutter

---

## 📲 Funcionalidade

- Alunos encostam o cartão no leitor ao entrar na sala
- ESP32 lê o cartão e envia nome/matrícula via MQTT
- Aplicativo do professor exibe a presença em tempo real
- Feedback com som e LED informa sucesso ou falha

---

## 🚀 Demonstração

> 💡 Em desenvolvimento ou prototipagem: ideal para testes com cartão NFC em laboratório.

---

Feito com C++ / Dart (Flutter).