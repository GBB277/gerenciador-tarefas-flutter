# Gerenciador de Tarefas Inteligente (Flutter)

Aplicativo desenvolvido para o trabalho **Explorando Tecnologias Móveis** (Unochapecó), usando **Flutter (Dart)**.

## Funcionalidades

**Pedidas no enunciado**
- Criar, editar e excluir tarefas
- Categorias: Trabalho, Estudo, Pessoal, Saúde e Outros
- Prioridades: Alta, Média e Baixa
- Marcar tarefas como concluídas
- Buscar e filtrar tarefas
- Persistência local dos dados (`shared_preferences`)

**Extras**
- Ordenação inteligente: pendentes primeiro, atrasadas no topo, depois prioridade e prazo
- Filtros por status (Pendentes, Todas, Concluídas), categoria, prioridade e prazo (Atrasadas, Hoje, Próximos 7 dias, Sem prazo)
- Deslizar para a direita conclui; para a esquerda exclui; sempre com **Desfazer**
- Cartão de resumo com percentual concluído e número de tarefas atrasadas
- Prazo com atalhos (Hoje, Amanhã, Outra data) e destaque para tarefas atrasadas
- Tema claro e escuro alternável dentro do app (a escolha fica salva)
- Limpar todas as concluídas de uma vez
- Interface em português (calendário e textos do sistema)

## Estrutura do projeto

```
lib/
  main.dart                          ponto de entrada, tema e idioma
  models/task.dart                   modelo Task, prioridades, categorias e JSON
  services/task_storage.dart         persistência local (SharedPreferences)
  controllers/task_controller.dart   estado das tarefas, filtros e ordenação
  controllers/theme_controller.dart  tema claro/escuro salvo no aparelho
  screens/home_screen.dart           lista, resumo, busca e painel de filtros
  screens/task_form_screen.dart      formulário de criar e editar
  widgets/task_tile.dart             cartão de cada tarefa
test/widget_test.dart                teste do modelo
```

Gerenciamento de estado: `ChangeNotifier` + `ListenableBuilder` (nativo do Flutter, sem pacotes extras).

## Como rodar

Pré-requisitos: Flutter SDK, Git e Android Studio (Android SDK, Build-Tools e um emulador). Confira com:

```bash
flutter doctor
```

Depois:

```bash
git clone https://github.com/GBB277/gerenciador-tarefas-flutter.git
cd gerenciador-tarefas-flutter
flutter pub get
flutter run              # escolhe o dispositivo disponível
flutter run -d chrome    # ou rodar no navegador
```

No Windows, ative o **Modo de Desenvolvedor** (exigido pelos plugins).

Com o app rodando: **r** faz hot reload, **R** faz hot restart e **q** encerra.

## Build

```bash
flutter build apk --release   # APK em build/app/outputs/flutter-apk/
flutter build appbundle       # AAB para a Google Play
flutter build web             # site estático
flutter build ipa             # iOS (exige Mac com Xcode)
```
