# ANÁLISE COMPARATIVA DE ABORDAGENS DE GERENCIAMENTO DE ESTADO
EM FLUTTER: UM ESTUDO DE CASO COM BLOC, RIVERPOD, PROVIDER E
GETX

Trabalho de Conclusão de Curso — Sistemas de Informação (UFSC). Compara **BLoC**, **Riverpod**, **Provider** e **GetX** num
mesmo estudo de caso (uma lista de tarefas), avaliando desempenho e qualidade de software.

## Sobre o projeto

**Objetivo geral:** analisar comparativamente BLoC, Riverpod, Provider e GetX,
considerando desempenho e qualidade de software.

**Objetivos específicos:**
1. Implementar um estudo de caso com as quatro abordagens em uma mesma aplicação Flutter.
2. Avaliar o desempenho e a qualidade de software de cada abordagem.
3. Comparar os resultados e elaborar um guia com vantagens e desvantagens de cada abordagem.

As camadas de domínio e dados (entidades, usecases, repositório, SQFlite) são **únicas e
compartilhadas** pelas 4 implementações — só a camada de apresentação muda por abordagem.
É esse desenho que garante que a comparação de desempenho seja justa: trocar de gerenciador
é trocar *só* a pasta `presentation/<abordagem>/`.

## Stack

- Flutter 3.47.1 / Dart 3.13.1 (via [FVM](https://fvm.app/))
- `flutter_modular` — injeção de dependência e roteamento
- Gerenciadores comparados: `bloc`/`flutter_bloc` 9.x, `provider` 6.1.1,
  `flutter_riverpod` 2.4.9, `get` 4.6.6
- `sqflite` — persistência local
- `dartz` (Either) + `equatable`

## Estrutura do projeto

```
tcc/
├── lib/app/             # AppModule, AppWidget, main.dart (raiz)
├── modules/
│   ├── dependencies/    # dependências externas centralizadas (workspace)
│   ├── common/          # AppDatabase, Failures, UseCase base, PerformanceTracker
│   ├── home/            # tela inicial com menu (1 botão por gerenciador)
│   └── task/            # módulo principal — domain/data compartilhados + as 4 implementações
│       └── lib/module/
│           ├── domain/         # entities, repositories, usecases
│           ├── data/           # datasource SQFlite, model, repository impl
│           └── presentation/
│               ├── bloc/       # TaskBloc
│               ├── provider/   # ProviderTaskNotifier
│               ├── riverpod/   # RiverpodTaskNotifier + providers.dart
│               ├── getx/       # TaskController + TaskBinding
│               ├── views/      # home views + formulários compartilhados
│               ├── widgets/    # TaskListView, PerfMenu, BenchmarkMenu, ...
│               └── utils/      # TaskFilterUtils, AppThemes, FrameMetricsRecorder, ProtocolRunner
│       └── test/                # suíte de testes equivalente, uma pasta por abordagem
tool/
├── complexity_report/   # pacote Dart standalone — complexidade ciclomática (McCabe)
└── run_protocol.ps1     # orquestra a coleta automática do protocolo quantitativo
```

## Pré-requisitos

- Flutter/Dart conforme o `environment.sdk` do `pubspec.yaml` (recomendado: [FVM](https://fvm.app/),
  `fvm use stable` ou instalar a versão compatível diretamente).
- Um dispositivo físico ou emulador Android conectado, para rodar o app e os cenários/protocolo
  (a suíte de testes unitários não precisa de device).

## Como rodar o app

```bash
fvm flutter pub get
fvm flutter run
```

É um pub workspace: `flutter pub get` na raiz resolve os 4 módulos internos
(`common`, `dependencies`, `home`, `task`) de uma vez. O app abre na `HomeView`, com um
botão para cada uma das 4 implementações.

## Como rodar os testes

```bash
fvm flutter pub get
cd modules/task && fvm flutter test
cd ../../modules/common && fvm flutter test
```

`modules/task/test/` tem 9 casos de teste equivalentes para as 4 abordagens, cada uma
usando a ferramenta idiomática do próprio pacote (`bloc_test`, `ProviderContainer`, etc.).
`modules/common/test/` cobre o `PerformanceTracker` (instrumento de coleta usado pelos
4 cenários de desempenho).

## Ferramentas de análise

### Complexidade ciclomática

`tool/complexity_report` é um pacote Dart standalone (fora do workspace do app) que
implementa a complexidade ciclomática de McCabe via `package:analyzer`, sem depender de
ferramenta externa paga. Calcula complexidade e LOC só dos arquivos exclusivos de cada
abordagem (state holder + home view), excluindo o que é compartilhado pelas 4.

```bash
cd tool/complexity_report
dart pub get
dart run bin/complexity_report.dart ../..
```

(o argumento é o caminho até a raiz do repositório.)

### Protocolo quantitativo automático

`tool/run_protocol.ps1` (Windows/PowerShell) roda, para cada uma das 4 abordagens — sempre
na mesma ordem fixa (`bloc → provider → riverpod → getx`) — o protocolo completo (Load
1k/10k/100k → Busca → Scroll → Tema) via `flutter run --profile`, esperando a bateria
esfriar entre execuções e consolidando os resultados ao final.

**Pré-requisitos:** `adb` no PATH (ou `-Adb <caminho>`), dispositivo com tela acesa e
desbloqueada antes de iniciar, `flutter.bat` acessível (ou `-Flutter <caminho>`).

```powershell
# teste rápido (2 amostras em vez de 20, pra validar o fluxo)
.\tool\run_protocol.ps1 -Device <id> -Quick

# coleta oficial completa
.\tool\run_protocol.ps1 -Device <id>

# coleta opcional de CPU/memória/frequência/temperatura via adb — passada SEPARADA,
# porque a própria amostragem roda dentro do processo medido e pode distorcer os tempos
.\tool\run_protocol.ps1 -Device <id> -SampleResources

# variante mais leve da anterior, sem o dumpsys meminfo (a parte mais pesada)
.\tool\run_protocol.ps1 -Device <id> -SampleResources -NoPss
```

Principais parâmetros (ver `Get-Help .\tool\run_protocol.ps1 -Full` para a lista completa):

| Parâmetro | Padrão | Descrição |
|---|---|---|
| `-Device` | *(obrigatório)* | id do dispositivo (`flutter devices` / `adb devices`) |
| `-Repeats` | 1 | nº de repetições do laço das 4 abordagens, sempre na mesma ordem |
| `-MaxTempC` | 29 | temperatura máxima da bateria (°C) pra iniciar cada execução |
| `-MaxThermalWaitMinutes` | 20 | tempo máximo esperando a temperatura cair antes de seguir mesmo assim |
| `-Quick` | desligado | reduz Load/Busca pra 2 amostras (teste de fluxo, não pra dado oficial) |
| `-RestSeconds` | 120 | descanso entre abordagens |
| `-SampleResources` | desligado | liga a coleta opcional de CPU/memória/frequência/térmico (ver aviso acima) |
| `-NoPss` | desligado | com `-SampleResources`, pula o `dumpsys meminfo` (mais leve) |
| `-OutDir` | `results` (`results_recursos` com `-SampleResources`) | pasta de saída |

**Saída** (em `results\` ou `results_recursos\`): `perf.jsonl` (métricas consolidadas),
`runs.csv` (status/temperatura/bateria por execução), `resources.csv` (com
`-SampleResources`), `invalid.log` (se alguma linha de métrica vier truncada/corrompida) e
os logs brutos de cada execução em `run<N>\`. Essas pastas estão no `.gitignore` — dados de
coleta não entram no controle de versão.

## Metodologia (resumo)

- **4 cenários medidos:** carregamento de dados (1.000/10.000/100.000 linhas), busca com
  debounce, scroll programático e troca de tema.
- **Métricas:** tempo de operação, memória, nº de reconstruções do builder reativo e tempo
  de frame (scroll/tema), todas coletadas por um instrumento único (`PerformanceTracker`),
  nunca pelo Flutter DevTools.
- **Dispositivo de teste:** Xiaomi Mi 9 (Snapdragon 855, Android 10), modo `--profile`.
- Critérios qualitativos (Objetivo 2): organização de código, complexidade ciclomática,
  manutenibilidade e testabilidade — ver `tool/complexity_report` e `modules/task/test/`.

## Autor

Lucas Broering — TCC em Sistemas de Informação (UFSC).
