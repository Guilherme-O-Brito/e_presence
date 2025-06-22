#include <Arduino.h>
#include <SPI.h>
#include <MFRC522.h>
#include <WiFi.h>
#include <PubSubClient.h>
#include <string.h>

// pinos usados na esp
#define LED_VD 21 // led verde
#define LED_VM 22 // led vermelho
#define BUZZER 4
// pinos usados apenas pelo leitor RFID via SPI
#define SDA 5
#define MOSI 23
#define MISO 19
#define SCK 18

// Criando objeto do leitor rfid
MFRC522 rfid(SDA, -1);
MFRC522::MIFARE_Key key;

// configurações do wifi
const char* ssid = ""; // nome da sua rede wifi
const char* password = ""; // senha da sua rede wifi

// configurações do broker MQTT
// usando HiveMQ
const char* mqtt_server = "broker.hivemq.com";
const int mqtt_port = 1883;
const char* mqtt_topic = "e_presence/I_XII"; // idealmente o topico utilizado deve ser e_presence/{nome da sala da aula}

// Cliente MQTT
WiFiClient espClient;
PubSubClient client(espClient);

// Armazena as matriculas que ja fizeram presença para evitar duplicidade
String matriculas[200];

// Tabela de notas (frequências em Hz)
const int zeldaMelody[] = {
  523, // C5
  587, // D5
  659, // E5
  698, // F5
  784, // G5
  880, // A5
  988, // B5
  1046 // C6
};

// Durações em milissegundos (cada vez mais rápidas)
const int zeldaNoteDurations[] = {
  200, 180, 160, 140, 120, 100, 80, 300
};

// Notas graves para o som de erro (em Hz)
const int errorMelody[] = {
  196, // G3
  130  // C3
};

// Duração das notas (em milissegundos)
const int errorDurations[] = {
  200,
  250
};

// toca uma musica de feedback positivo
void playZeldaChestSound() {
    digitalWrite(LED_VD, HIGH);
    for (int i = 0; i < 8; i++) {
        tone(BUZZER, zeldaMelody[i], zeldaNoteDurations[i]);
        delay(zeldaNoteDurations[i] + 20); // pequena pausa entre as notas
    }
    noTone(BUZZER);
    digitalWrite(LED_VD, LOW);
}

// toca uma musica de feedback negativo
void playErrorSound() {
    digitalWrite(LED_VM, HIGH);
    for (int i = 0; i < 2; i++) {
        tone(BUZZER, errorMelody[i], errorDurations[i]);
        delay(errorDurations[i] + 30); // pequena pausa
    }
    noTone(BUZZER);
    digitalWrite(LED_VM, LOW);
}

// verifica se a matricula lida ja não registrou presença antes
bool checkMatricula(String matricula) {
    const char* matriculaStr = matricula.c_str();
    for (int i=0;i<200;i++) 
        if (strcmp(matricula.c_str(), matriculas[i].c_str()) == 0) return true;
    return false;
}

// adiciona uma matricula na proxima posição disponivel no vetor de matriculas
bool addMatricula(String matricula) {
    for (int i=0;i<200;i++) {
        if (strcmp(matriculas[i].c_str(), "") == 0) {
            matriculas[i] = matricula;
            return true;
        }
    }
    return false;
}

// le a tag encontrada pelo sensor e envia a nome e matricula via mqtt
void readNFC() {
    byte nome_buffer[18];
    byte matricula_buffer[18];
    byte size = 18;
    String nome = "";
    String matricula = "";

    // autentica e le o bloco 4 (nome)
    if (rfid.PCD_Authenticate(MFRC522::PICC_CMD_MF_AUTH_KEY_A, 4, &key, &(rfid.uid)) != MFRC522::STATUS_OK) {
        playErrorSound();
        return;
    }
    
    if (rfid.MIFARE_Read(4, nome_buffer, &size) != MFRC522::STATUS_OK) {
        playErrorSound();
        return;
    }

    for (int i=0;i<16;i++) 
        if (nome_buffer[i] >= 32 && nome_buffer[i] <= 126) {
            nome += (char)nome_buffer[i];
        }
    
    

    // autentica e le o bloco 5 (matricula)
    if (rfid.PCD_Authenticate(MFRC522::PICC_CMD_MF_AUTH_KEY_A, 5, &key, &(rfid.uid)) != MFRC522::STATUS_OK) {
        playErrorSound();
        return;
    }

    if (rfid.MIFARE_Read(5, matricula_buffer, &size) != MFRC522::STATUS_OK) {
        playErrorSound();
        return;
    }

    for (int i=0;i<16;i++)
        if (matricula_buffer[i] >= 32 && matricula_buffer[i] <= 126) {
            matricula += (char)matricula_buffer[i];
        }
    
     
    if (checkMatricula(matricula)) {
        playErrorSound();
        return;
    }

    if (!addMatricula(matricula)) {
        playErrorSound();
        return;
    }

    String json = "{\"nome\":\"" + nome + "\", \"matricula\":\"" + matricula + "\"}";
    client.publish(mqtt_topic, json.c_str());
    Serial.println("Presenca enviada via MQTT");

    // feedback visual e audivel da leitura concluida
    digitalWrite(LED_VD, HIGH);
    digitalWrite(LED_VM, LOW);  
    playZeldaChestSound();

}

void reconnectMQTT() {
    // tenta se conectar ate conseguir
    while (!client.connected()) {
        Serial.println("Tentando se conectar ao MQTT . . .");
        String clientId = "ESPClient-";
        clientId += String(random(0xffff), HEX); // gera ID aleatorio

        if (client.connect(clientId.c_str())) {
            Serial.println("Conectado ao broker");
        } else {
            Serial.print("Conexao falhou: ");
            Serial.print(client.state());
            Serial.println("Tentando se conectar novamente em 5 segundos . . .");
            playErrorSound();
            delay(5000);
        }

    }   
}

void setup() {

    Serial.begin(115200);

    pinMode(LED_VD, OUTPUT);
    pinMode(LED_VM, OUTPUT);
    pinMode(BUZZER, OUTPUT);   

    digitalWrite(LED_VD, LOW);
    digitalWrite(LED_VM, LOW);

    // Inicializa a chave com FF FF FF FF FF FF
    for (byte i = 0; i < 6; i++) {
        key.keyByte[i] = 0xFF;
    }
    Serial.println("Pinos digitais iniciados");

    // Iniciando SPI manualmente
    SPI.begin(SCK, MISO, MOSI, SDA);
    Serial.println("SPI Iniciada");

    // Iniciando leitor rfid RC522
    rfid.PCD_Init();
    Serial.println("Leitor RFID iniciado");

    // Conectando ao wifi
    WiFi.begin(ssid, password);
    Serial.println("Conectando ao Wi-Fi");
    while (WiFi.status() != WL_CONNECTED) {
        delay(500);
        Serial.print(".");
    }
    Serial.println("Wi-Fi conectado");

    // Configurando cliente MQTT
    client.setServer(mqtt_server, mqtt_port);
}

void loop() {
    String nome = "";
    String matricula = "";

    // garante conexão ao mqtt
    if (!client.connected()) {
        reconnectMQTT();
    }

    client.loop();

    // verifica se uma tag foi encontrada pelo sensor
    if (!rfid.PICC_IsNewCardPresent() || !rfid.PICC_ReadCardSerial()) {
        delay(50);
        return;
    }

    readNFC();

    // desconecta da tag
    rfid.PICC_HaltA();
    rfid.PCD_StopCrypto1();

}