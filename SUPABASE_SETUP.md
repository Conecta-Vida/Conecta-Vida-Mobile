# Configuração de Credenciais do Supabase

## ⚠️ SEGURANÇA IMPORTANTE

As credenciais do Supabase **NÃO** devem ser hardcoded no código-fonte. Este projeto foi atualizado para usar variáveis de ambiente.

## Como Configurar

### 1. Instalar o Package flutter_dotenv

```bash
flutter pub add flutter_dotenv
```

### 2. Arquivo `.env`

Um arquivo `.env` foi criado na raiz do projeto com as credenciais. **Este arquivo está no .gitignore e não será enviado ao repositório.**

```
SUPABASE_URL=https://molkujbjqtmugfvtkqpo.supabase.com
SUPABASE_ANON_KEY=sb_publishable_0cGJgTfE_EYrPVPheXrqKg_q9Zg8zE8
```

### 3. Configurar no main.dart

Atualize seu arquivo `main.dart` para carregar as variáveis de ambiente:

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Carregar variáveis de ambiente
  await dotenv.load();
  
  // Inicializar Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );
  
  // Passar credenciais para o serviço
  await SupabaseService.initializeCredentials(
    dotenv.env['SUPABASE_URL'] ?? '',
    dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );
  
  runApp(const MyApp());
}
```

### 4. Arquivo pubspec.yaml

Adicione no `pubspec.yaml`:

```yaml
dependencies:
  flutter_dotenv: ^5.1.0
  
flutter:
  assets:
    - .env
```

## 🔒 Boas Práticas

- ✅ Use variáveis de ambiente para credenciais
- ✅ Nunca commit o arquivo `.env` no Git
- ✅ Crie um arquivo `.env.example` com nomes de variáveis (sem valores)
- ✅ Use logging para debug (não log de senhas/tokens)
- ✅ Revise as permissões do Row Level Security (RLS) no Supabase

## 📝 Melhorias Realizadas

1. **Removidas credenciais hardcoded** do código
2. **Adicionado logging detalhado** para debug via `dart:developer`
3. **Melhorado tratamento de erros** com tipos específicos de exceção
4. **Adicionada verificação de dados vazios** antes de processar
5. **Configurado cSpell** para aceitar palavras em português

## 🐛 Debugging

Para visualizar os logs, use:

```bash
flutter run -v
```

E procure por mensagens com prefixo `[SupabaseService]`.
