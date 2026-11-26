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

## Supabase

O app usa o Supabase Auth para login, cadastro e recuperacao de senha. A URL do
projeto e a chave publica `publishable` podem ser substituidas no build:

```sh
flutter run --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=<publishable-key>
```

A chave publishable e destinada ao cliente. Nunca use a chave `secret` ou
`service_role` no aplicativo. O cadastro envia nome, telefone, WhatsApp, CEP,
cidade e idade como metadados do usuario no Supabase Auth. Com confirmacao de
e-mail habilitada, o usuario precisa confirmar o endereco antes de entrar.

Os projetos ficam vinculados ao usuario autenticado no Supabase. Antes de usar
esse recurso, execute o SQL de
[criacao da tabela e das politicas de acesso](./supabase/migrations/20261125160500_create_projects.sql)
no SQL Editor do seu projeto Supabase.

## Validar

```sh
flutter analyze
flutter test
```
