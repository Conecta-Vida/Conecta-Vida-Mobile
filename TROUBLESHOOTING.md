# 🐛 Guia de Troubleshooting

## Problema: Credenciais não estão sendo carregadas

### ❌ Erro típico:
```
Exception: Erro: Variáveis SUPABASE_URL e SUPABASE_ANON_KEY não configuradas no .env
```

### ✅ Solução:
1. Verifique se o arquivo `.env` existe na **raiz do projeto**
2. Certifique-se de que o `pubspec.yaml` tem `.env` nos assets:
   ```yaml
   flutter:
     assets:
       - .env
   ```
3. Execute `flutter pub get`
4. Execute `flutter run` (não `flutter run -v` ainda)

---

## Problema: Dados não aparecem no Supabase

### ❌ O que pode estar acontecendo:
- [ ] Permissões RLS (Row Level Security) bloqueando inserts
- [ ] Chave anônima com permissões insuficientes
- [ ] Estrutura de tabela diferente do esperado
- [ ] Dados inválidos sendo enviados

### ✅ Passos para debug:

1. **Verifique as tabelas no Supabase:**
   - Acesse supabase.com/dashboard
   - Vá em SQL Editor
   - Execute:
     ```sql
     SELECT * FROM usuarios LIMIT 1;
     SELECT * FROM noticias LIMIT 1;
     ```

2. **Verifique as permissões RLS:**
   - Vá em Authentication → Policies
   - Procure por policies nas tabelas: `usuarios`, `noticias`, `noticias_compartilhadas`
   - Confirme que permitem `INSERT` e `UPDATE` para a chave anônima

3. **Teste com curl (no terminal):**
   ```bash
   curl -X GET 'https://molkujbjqtmugfvtkqpo.supabase.com/rest/v1/usuarios' \
     -H "apikey: sb_publishable_0cGJgTfE_EYrPVPheXrqKg_q9Zg8zE8" \
     -H "Authorization: Bearer sb_publishable_0cGJgTfE_EYrPVPheXrqKg_q9Zg8zE8"
   ```

4. **Veja os logs do servidor:**
   - No Supabase Dashboard
   - Vá em Logs
   - Procure por erros de autenticação ou permissão

---

## Problema: `flutter_dotenv` não encontrado

### ❌ Erro:
```
Error: Cannot find package "flutter_dotenv" at "packages/flutter_dotenv"
```

### ✅ Solução:
```bash
flutter pub get
flutter pub add flutter_dotenv
```

Se ainda não funcionar:
```bash
cd seu_projeto
rm -rf pubspec.lock  # Remover lock file
flutter pub get
```

---

## Problema: Logs não aparecem

### ❌ Não vejo as mensagens de `SupabaseService`

### ✅ Solução:
1. Execute com logs verbosos:
   ```bash
   flutter run -v 2>&1 | grep -i "supabase\|erro\|error"
   ```

2. Ou procure especificamente:
   ```bash
   flutter run -v 2>&1 | grep "SupabaseService"
   ```

3. No VS Code, abra o Debug Console:
   - Run → Open Debug Console (Ctrl+Shift+Y)
   - Procure por `[SupabaseService]`

---

## Problema: Auth não funciona (signUp/signIn)

### ❌ Erro ao fazer login:
```
Exception: Falha no login: Invalid login credentials
```

### ✅ Verificações:
1. **Confirme que o usuário existe:**
   - No Supabase Dashboard
   - Vá em Authentication → Users
   - Procure pelo email

2. **Verifique se confirmação de email é necessária:**
   - Vá em Authentication → Providers → Email
   - Procure por "Email confirmations"
   - Se ativado, usuário precisa confirmar email antes de fazer login

3. **Teste com dados válidos:**
   - Email: `usuario@example.com`
   - Senha: Mínimo 6 caracteres

4. **Verifique os logs de auth:**
   ```bash
   # No seu app
   print('Tentando login: $email');
   ```

---

## Problema: Classe `NewsModel` ou `NewsController` não encontrada

### ❌ Erro:
```
Error: Cannot find "NewsModel" in "...models/noticia.dart"
```

### ✅ Verificações:
1. Confirme que o arquivo existe: `lib/models/noticia.dart`
2. Confirme que a classe é realmente chamada `NewsModel` (não `Noticia`)
3. Verifique se tem `toMap()` e `fromMap()` methods

Se a classe for `Noticia`, atualize em `supabase_service.dart`:
```dart
// Alterar:
NewsModel.fromMap(...)
// Para:
Noticia.fromMap(...)
```

---

## Problema: Arquivo `.env` não é encontrado em produção

### ❌ Erro em release build:
```
Exception: Erro: Variáveis SUPABASE_URL e SUPABASE_ANON_KEY não configuradas
```

### ✅ Solução para produção:
1. **Na nuvem (Firebase, Heroku, etc):**
   - Defina as variáveis de ambiente no dashboard
   - Elas serão automaticamente injetadas

2. **No Android:**
   - Adicione ao `android/app/build.gradle`
   - Ou use buildConfigField

3. **No iOS:**
   - Adicione ao `ios/Runner/Info.plist`
   - Ou use variáveis de compilação

---

## Problema: Permissão negada ao sincronizar

### ❌ Erro:
```
Exception: failed: new row violates row-level security policy
```

### ✅ Solução - Configurar RLS:
1. No Supabase Dashboard
2. Vá em SQL Editor
3. Copie e execute para cada tabela:

```sql
-- Para tabela usuarios
ALTER TABLE usuarios ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can insert their own data" 
  ON usuarios FOR INSERT 
  WITH CHECK (auth.uid() = auth.uid() OR true);

-- Para tabela noticias  
ALTER TABLE noticias ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Noticias are viewable by everyone"
  ON noticias FOR SELECT USING (true);
CREATE POLICY "Noticias can be inserted by service"
  ON noticias FOR INSERT WITH CHECK (true);

-- Para tabela noticias_compartilhadas
ALTER TABLE noticias_compartilhadas ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Compartilhamentos can be inserted"
  ON noticias_compartilhadas FOR INSERT WITH CHECK (true);
```

---

## Problema: `PostgrestException` não é reconhecido

### ❌ Erro:
```
Error: Undefined name "PostgrestException"
```

### ✅ Solução:
Verifique se tem a importação:
```dart
import 'package:supabase_flutter/supabase_flutter.dart';
```

Ela deve trazer `PostgrestException` automaticamente.

---

## Checklist de Debug

- [ ] `.env` existe na raiz do projeto
- [ ] `flutter pub get` foi executado
- [ ] `pubspec.yaml` tem `.env` nos assets
- [ ] Credenciais estão corretas no `.env`
- [ ] Permissões RLS estão configuradas
- [ ] Executando com `flutter run -v` para ver logs
- [ ] Verificou o console do Supabase
- [ ] Não há typos nos nomes de tabelas/colunas
- [ ] Modelos (UserModel, NewsModel) têm `toMap()` e `fromMap()`
- [ ] Internet está funcionando

---

## Contatos e Recursos

- **Docs Flutter:** https://flutter.dev/docs
- **Supabase Docs:** https://supabase.com/docs
- **Stack Overflow:** Tag com `flutter` e `supabase`
- **GitHub Issues:** https://github.com/supabase/supabase-flutter/issues

Se nada funcionar, procure pelos logs completos no console do Supabase!
