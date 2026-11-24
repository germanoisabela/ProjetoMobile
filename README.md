# SmartFloor

Aplicativo Flutter para captura e planejamento de ambientes.

## Requisitos

- Flutter stable com Dart SDK 3.13.7 ou superior.
- Para Android: Android SDK e Java 17.
- Um emulador Android ou dispositivo Android para executar o aplicativo.

Confira a instalacao com `flutter doctor`.

## Configurar e executar

```sh
git clone https://github.com/joaozmaciel/smartfloor.git
cd smartfloor
flutter pub get
flutter run
```

O `pubspec.lock` esta versionado para manter as mesmas versoes das dependencias
em diferentes maquinas.

## Firebase local

Em modo debug, o aplicativo conecta Firebase Auth e Cloud Firestore aos
emuladores locais. Para inicia-los, instale o Firebase CLI e execute na raiz do
projeto:

```sh
firebase emulators:start --project smartfloor-7b835 --only auth,firestore
```

No emulador Android, o endereco `10.0.2.2` aponta para a maquina que executa os
emuladores; nao e necessario configurar nada adicional. Em um dispositivo
fisico, informe o endereco IP da maquina na mesma rede:

```sh
flutter run --dart-define=FIREBASE_EMULATOR_HOST=192.168.1.10
```

Substitua o IP pelo endereco correto da maquina que hospeda os emuladores. Em
outras plataformas, o padrao e `localhost`.

As configuracoes Firebase para Android estao no repositorio. Para adicionar
outra plataforma, configure-a no Firebase e gere novamente as opcoes com o
FlutterFire CLI. Builds release conectam ao projeto Firebase configurado, nao
aos emuladores locais.

## Validar

```sh
flutter analyze
flutter test
```
