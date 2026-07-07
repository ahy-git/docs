# push_swap — suíte de testes

Scripts de teste para o projeto **push_swap** (42 São Paulo, versão 1.1).
Cobrem todos os requisitos do subject: compilação, norma, parsing, corretude,
formato de saída, flags, benchmark, roteamento adaptive, performance, memória
e o checker bonus.

---

## Índice

1. [Pré-requisitos](#pré-requisitos)
2. [Como usar](#como-usar)
3. [Variáveis de ambiente](#variáveis-de-ambiente)
4. [Logs](#logs)
5. [Descrição de cada script](#descrição-de-cada-script)
   - [test_norminette.sh](#test_norminettech)
   - [test_globals.sh](#test_globalssh)
   - [test_makefile.sh](#test_makefilesh)
   - [test_checker.sh](#test_checkersh)
   - [test_errors.sh](#test_errorssh)
   - [test_basic.sh](#test_basicsh)
   - [test_correctness.sh](#test_correctnesssh)
   - [test_flags.sh](#test_flagssh)
   - [test_bench_format.sh](#test_bench_formatsh)
   - [test_adaptive.sh](#test_adaptivesh)
   - [compare_algos.sh](#compare_algossh)
   - [test_performance.sh](#test_performancesh)
   - [test_stability.sh](#test_stabilitysh)
   - [test_leaks.sh](#test_leakssh)
   - [gen_plot.sh](#gen_plotsh)
   - [test_before_after.sh](#test_before_aftersh)
   - [test_shuf_ops.sh](#test_shuf_opssh)
6. [Como a corretude é verificada](#como-a-corretude-é-verificada)
7. [Como o disorder é calculado](#como-o-disorder-é-calculado)
8. [Formato exato do --bench](#formato-exato-do---bench)
9. [Thresholds do --adaptive](#thresholds-do---adaptive)
10. [Arquivos auxiliares](#arquivos-auxiliares)
11. [Observações](#observações)

---

## Pré-requisitos

| Ferramenta   | Obrigatório | Para quê                                               |
|--------------|-------------|--------------------------------------------------------|
| `bash`       | sim         | todos os scripts                                        |
| `python3`    | sim         | gerador de números, verificador interno, cálculos       |
| `make`       | sim         | `test_makefile.sh`                                      |
| `nm`         | recomendado | `test_globals.sh` (pula automaticamente se ausente)     |
| `valgrind`   | recomendado | `test_leaks.sh` (pula automaticamente se ausente)       |
| `norminette` | recomendado | `test_norminette.sh` (pula automaticamente se ausente)  |
| `matplotlib` | não         | `gen_plot.sh` para gráfico PNG (usa ASCII sem ele)      |

---

## Como usar

Os scripts detectam automaticamente os binários em `../` (raiz do projeto).
Podem ser executados **de dentro de `tests/`** ou **da raiz do projeto**.

```sh
# Compilar o projeto antes de testar
make -C push_swap_git          # push_swap
make -C push_swap_git bonus    # checker (opcional)

# Suíte completa
bash tests/run_all.sh

# Scripts individuais (qualquer diretório)
bash tests/test_norminette.sh
bash tests/test_globals.sh
bash tests/test_makefile.sh
bash tests/test_checker.sh
bash tests/test_errors.sh
bash tests/test_basic.sh
bash tests/test_correctness.sh [count] [iters]
bash tests/test_flags.sh [count]
bash tests/test_bench_format.sh [count]
bash tests/test_adaptive.sh
bash tests/compare_algos.sh [size]
bash tests/test_performance.sh [iters]
bash tests/test_stability.sh [size] [iters] [timeout_s]
bash tests/test_leaks.sh [count]
bash tests/gen_plot.sh [iters] [sizes...]
```

### Ordem de execução no `run_all.sh`

```
test_norminette.sh      # norma 42
test_globals.sh         # variaveis globais proibidas
test_makefile.sh        # regras Makefile + sem relink + make bonus
test_checker.sh         # comportamento do checker (bonus, pula se nao compilado)
test_errors.sh          # parsing e erros
test_basic.sh           # uso normal e formato de saida
test_correctness.sh     # corretude da ordenacao (100 nums, 20 rodadas)
test_flags.sh           # flags --simple/--medium/--complex/--adaptive/--bench
test_bench_format.sh    # formato exato do --bench
test_adaptive.sh        # roteamento do --adaptive por disorder
compare_algos.sh        # 4 algoritmos lado a lado
test_performance.sh     # ops vs limites do subject (50 rodadas)
test_stability.sh       # stress 500 nums, 20 rodadas, timeout 10s
test_leaks.sh           # valgrind (100 nums)
```

---

### `test_before_after.sh`

Imprime os valores de stack `a` **antes e depois** de cada ordenação, aplicando
as operações geradas pelo `push_swap` via simulador Python interno.

**Perfis testados:** aleatorio, ordem_inversa, quase_ordenado.

**Como usar:**
```sh
bash tests/test_before_after.sh [size]
# padrão: size=10
```

Para cada perfil, exibe:
```
  [INFO] ANTES : 5 3 1 9 2 ...
  [INFO] DEPOIS: 1 2 3 5 9 ...
  [INFO] Operacoes (--adaptive): 42
  [PASS] ordenacao correta (aleatorio)
```

Nao faz parte do `run_all.sh` — script de uso manual para inspecao visual.

---

### `test_shuf_ops.sh`

Replica os tres comandos de validacao manual com `shuf` e `checker_linux`:

| Teste | Comando original | O que faz |
|---|---|---|
| 1 | `shuf -i 0-9999 -n 500 \| push_swap \| wc -l` | Gera 500 numeros aleatorios de 0-9999, conta ops e verifica limite de 5500 |
| 2 | `ARG="4 67 3 87 23"; push_swap --complex $ARG \| checker_linux $ARG` | Testa ARG fixo com `--complex` e verifica com `checker_linux` |
| 3 | `shuf -n 500 \| push_swap --bench … 2>bench.txt \| checker_linux …` | Roda `--bench` em 500 numeros, exibe cabecalho do bench.txt e verifica com `checker_linux` |

**Requer:** `shuf` (coreutils) e `checker_linux` na raiz do projeto.
Pula graciosamente qualquer teste se a ferramenta nao estiver disponivel.

```sh
bash tests/test_shuf_ops.sh
```

Nao faz parte do `run_all.sh` — depende de `checker_linux` externo.

---

## Variáveis de ambiente

| Variável   | Padrão                  | Para quê                                                |
|------------|-------------------------|---------------------------------------------------------|
| `PS_BIN`   | `../push_swap`          | caminho do binário push_swap                            |
| `CHK_BIN`  | `../checker`            | caminho do checker (bonus)                              |
| `CHECKER`  | (vazio)                 | checker externo, ex.: `./checker_linux`                 |
| `VERIFIER` | `python3 ps_verify.py`  | validador interno (padrão quando CHECKER não definido)  |
| `LOG_FILE` | (definido por run_all)  | arquivo de log; pode ser definido manualmente           |

Exemplos:

```sh
# Usar checker oficial da 42 para validação
CHECKER=./checker_linux bash tests/test_correctness.sh

# Testar binário alternativo com mais iterações de performance
PS_BIN=./push_swap_debug bash tests/test_performance.sh 200

# Gerar log de um script individual
export LOG_FILE=/tmp/meu_log.txt
bash tests/test_adaptive.sh
```

---

## Logs

O `run_all.sh` cria automaticamente `tests/logs/` e salva um arquivo por execução:

```
tests/logs/run_20260630_143022.log
```

O log é **texto puro sem cores ANSI**, com todos os resultados `[PASS]`, `[FAIL]`
e `[INFO]` de cada etapa. Sub-scripts individuais gravam no mesmo arquivo quando
`LOG_FILE` está exportado (o `run_all.sh` faz isso automaticamente).

Formato do log:

```
========================================
push_swap test suite
Data:    Mon Jun 30 14:30:22 -03 2026
PS_BIN:  /home/user/push_swap_git/push_swap
CHK_BIN: /home/user/push_swap_git/checker
========================================

########## test_errors.sh ##########

=== Casos que NAO devem imprimir nada (EMPTY) ===
  [PASS] sem argumentos
  [PASS] um numero (42)
  [FAIL] um numero negativo (-42) (stdout='' stderr='Error')

Resumo: 2 passou, 1 falhou
...
===================================
2 ETAPA(S) COM FALHA
```

---

## Descrição de cada script

### `test_norminette.sh`

Executa `norminette` em todos os arquivos `.c` e `.h` encontrados recursivamente
na raiz do projeto (`src/`, `include/`, etc.).

**O que verifica:**
- Todos os arquivos devem passar na norma sem erros nem notices
- Arquivos de bonus também são verificados (norminette inclui tudo)

**Como usar:**
```sh
bash tests/test_norminette.sh          # escaneia PROJECT_DIR (padrão)
bash tests/test_norminette.sh src/     # escaneia diretório específico
```

**Pula automaticamente** se `norminette` não estiver instalada.
Para instalar: `pip install norminette`.

---

### `test_globals.sh`

Verifica que nenhum binário contém **variáveis globais**, que são proibidas pelo
subject (Common Instructions: *"Global variables are forbidden."*).

**Como funciona:**

Usa `nm -g` para listar símbolos com ligação externa e filtra os segmentos
graváveis:

| Tipo nm | Segmento | Significado                          |
|---------|----------|--------------------------------------|
| `B`     | BSS      | global não-inicializada              |
| `D`     | DATA     | global inicializada                  |
| `C`     | COMMON   | global comum (pode ser mesclada)     |

Símbolos excluídos automaticamente (não são código do aluno):
- `__*` — adicionados pelo runtime do GCC/linker
- `__bss_start`, `_edata`, `_end`, `__data_start`, `__TMC_END__` — do linker
- `ft_*` — funções da libft

Também reporta como `[INFO]` as variáveis `static` de arquivo (tipo `b`/`d`,
minúsculo), que são locais ao arquivo e **não são proibidas**, mas ficam visíveis
para inspeção.

**Testa:** `push_swap` e `checker` (se compilado).

**Pula automaticamente** se `nm` não estiver disponível.

---

### `test_makefile.sh`

Verifica os requisitos de compilação do subject (Common Instructions).

**O que testa, em ordem:**

1. **Regras obrigatórias** — o Makefile deve conter as regras:
   `all`, `clean`, `fclean`, `re`, `bonus`

2. **`make` compila o binário** — após `make fclean`, `make` deve gerar
   `push_swap` executável com exit code 0

3. **Sem relink** — segunda execução de `make` não recompila nada.
   Detectado por `"up to date"` ou `"Nothing to be done"` na saída do make.

4. **`make fclean` remove os binários** — após `fclean`, nem `push_swap` nem
   `checker` devem existir

5. **`make re` reconstrói** — deve recompilar tudo e gerar `push_swap` funcional

6. **`make bonus` compila o checker** — resulta no executável `checker`

> **Aviso:** este script executa `make fclean` e `make re` no projeto. Ao final
> garante que `push_swap` esteja reconstruído para os testes seguintes.

---

### `test_checker.sh`

Valida o **checker bonus** contra todos os requisitos do subject (Chapter VIII).

**Pré-requisito:** `make bonus` deve ter sido executado.
O script pula graciosamente (exit 0, sem falha na suite) se o binário
`checker` não existir. O `test_makefile.sh`, que roda antes, já executa
`make bonus` e produz o binário.

**O que testa:**

| Teste | Entrada | Saída esperada |
|---|---|---|
| Sem argumentos | `./checker` | sem output, exit 0 |
| Arg não-inteiro | `./checker abc` | `Error` no stderr |
| String vazia | `./checker "" 1` | `Error` no stderr |
| Overflow INT | `./checker 2147483648` | `Error` no stderr |
| Duplicata | `./checker 1 2 1` | `Error` no stderr |
| Já ordenado, sem ops | `printf "" \| ./checker 1 2 3` | `OK` |
| Não ordenado, sem ops | `printf "" \| ./checker 3 2 1` | `KO` |
| Stack B não vazia | `printf "pb\n" \| ./checker 1 2 3` | `KO` |
| Operação inválida | `printf "foo\n" \| ./checker 3 2 1` | `Error` no stderr |
| Operação malformada (maiúscula) | `printf "SA\n" \| ./checker 3 2 1` | `Error` no stderr |
| 11 ops válidas aceitas | todas as ops em stack de 20 | stderr ≠ `Error` |
| Integração n=3,5,10,50,100 | `./push_swap \| ./checker` | `OK` em todos |

**Armadilha documentada: `printf "%s\n"` com OPS vazio**

Para `n=3`, `push_swap` pode não gerar nenhuma operação (probabilidade
1/6 de o input já estar ordenado). Nesse caso `OPS=""` e o idioma clássico

```bash
printf "%s\n" "$OPS" | ./checker $NUMS   # ERRADO quando OPS=""
```

envia apenas `\n` para o stdin. O checker trata linha vazia como instrução
inválida → `error_exit` → `Error` no stderr → stdout vazio → `out=""`.

A solução adotada em todo o suite é:

```bash
printf "%s" "$OPS" | ./checker $NUMS     # correto: 0 bytes quando OPS=""
```

`printf "%s"` com string vazia não emite nenhum byte. O checker recebe
EOF imediatamente, quebra o loop e verifica as stacks normalmente.
A mesma correção foi aplicada em `lib.sh` → `verify_sort()` no caminho
que usa `$CHECKER` (checker binário externo).

---

### `test_errors.sh`

Verifica o tratamento de erros do parser, seguindo as regras do subject:

- Entrada inválida → `"Error\n"` no **stderr**, **stdout vazio**
- Entrada vazia ou único número → **tudo vazio** (silêncio total)

**Categorias testadas:**

| Categoria | Exemplos | Resultado esperado |
|---|---|---|
| **EMPTY** — sem args / 1 número | `(vazio)`, `42`, `-42`, `0` | stdout=vazio, stderr=vazio |
| Não-numérico | `a`, `one`, `1a`, `1.5`, `0x10`, `1,2` | `Error` no stderr |
| Sinais malformados | `+-5`, `-+5`, `1-2`, `5-`, `+`, `-`, `--` | `Error` |
| Overflow | `2147483648`, `-2147483649`, `99999999999999999999` | `Error` |
| Duplicados | `1 2 2`, `3 2 3`, `-1 -1`, `0 0`, `"1 2 3 2"` | `Error` |
| Limites válidos | `2147483647`, `-2147483648` | sem Error (reportado) |
| Política ambígua | `""`, `+5`, `-0`, `007`, `" 5"` | apenas reportado (INFO) |

Os casos de "política ambígua" não falham o teste pois o subject deixa
o comportamento a cargo do aluno.

---

### `test_basic.sh`

Verifica o comportamento normal do programa e o **formato exato da saída**.

**O que testa:**

1. **Entrada já ordenada gera 0 operações** — `1 2 3`, `1 2 3 4 5`, `-3 -1 0 2 7`

2. **Entradas comuns ordenam corretamente** — `2 1`, `3 2 1`, `5 1 4 2 3`,
   `10 -5 0 3 -1 8 2`

3. **Formato de saída** — a saída deve conter apenas operações válidas
   (`sa sb ss pa pb ra rb rr rra rrb rrr`), uma por linha

4. **Sem espaços ou tabs** nas linhas de saída (apenas `\n` como separador)

5. **Terminador newline** — a última linha termina com `\n`

6. **Argumentos separados == string única** — `./push_swap 5 3 1 4 2` e
   `./push_swap "5 3 1 4 2"` devem gerar saída idêntica (verificado por md5sum)

---

### `test_correctness.sh`

Verifica que o fluxo de operações produzido **realmente ordena a stack**.

**O que testa:**

1. **Casos triviais** — já ordenado, 1 elemento, 2 elementos, negativos, mistura

2. **Todas as 6 permutações de 3 elementos** — cobertura completa de `n=3`

3. **Casos representativos de 4 e 5 elementos** — piores casos e casos médios

4. **Entrada como string única** — `"5 4 3 2 1"` e `"10 -5 0 3 -1"`

5. **N rodadas aleatórias** — padrão: 20 rodadas × 100 números únicos aleatórios

**Parâmetros:**
```sh
bash tests/test_correctness.sh [count] [iters]
# padrão: count=100, iters=20
```

**Como verifica:** executa `$PS_BIN args` e passa o resultado para `ps_verify.py`
(ou `$CHECKER` se definido). O verificador simula as operações e confirma
`OK` ou `KO`.

---

### `test_flags.sh`

Verifica as flags de seleção de estratégia e o modo `--bench`.

**O que testa:**

1. **Cada seletor ordena corretamente** com `[count]` números aleatórios:
   - `--simple` (O(n²))
   - `--medium` (O(n√n))
   - `--complex` (O(n log n))
   - `--adaptive` (seleção automática por disorder)

2. **Default == `--adaptive`** — sem flag, o número de operações deve ser
   igual ao de `--adaptive` no mesmo input

3. **`--bench` envia métricas apenas para stderr** — stdout continua com
   as operações normais

4. **Todos os campos obrigatórios presentes no stderr** do `--bench`:
   `bench`, `disorder`, `strategy`, `complexity`, `total`
   (verificados **individualmente**, não com OR)

5. **Contadores de cada operação** presentes: `sa`, `sb`, `ss`, `pa`, `pb`,
   `ra`, `rb`, `rr`, `rra`, `rrb`, `rrr`

6. **Flag inválida** (ex.: `--turbo`) — reportada como ERROR ou INFO conforme
   política do aluno

7. **Flag sem números** (`--simple` sozinho) — não deve imprimir operações

---

### `test_bench_format.sh`

Verifica o **formato exato** de cada campo do `--bench`, linha por linha.

O formato esperado (conforme `bench_report.c`):

```
bench
disorder: XX.XX%
strategy: adaptive/simple
complexity: O(n^2)
total: 347
sa: 0
sb: 0
ss: 0
pa: 100
pb: 100
ra: 47
rb: 23
rr: 0
rra: 77
rrb: 0
rrr: 0
```

**O que testa:**

| Campo | Verificação |
|---|---|
| `bench` | linha exata `^bench$` |
| `disorder: XX.XX%` | regex `^disorder: [0-9]+\.[0-9]{2}%$` |
| `strategy:` | para `--adaptive`: `^strategy: adaptive/(simple\|medium\|complex)$` |
| `strategy:` | para `--simple/--medium/--complex`: sem prefixo `adaptive/` |
| `complexity:` | `O(n²)` ou `O(n^2)`, `O(n√n)` ou `O(n sqrt n)`, `O(n log n)` |
| coerência | `simple`↔`O(n²/n^2)`, `medium`↔`O(n√n/n sqrt n)`, `complex`↔`O(n log n)` |
| `total: N` | inteiro, igual à **soma** dos 11 contadores individuais |
| `sa:` … `rrr:` | cada um presente com valor inteiro |
| sem `--bench` | stderr completamente vazio |

---

### `test_adaptive.sh`

Verifica que `--adaptive` **roteia para a estratégia correta** com base na
faixa de disorder do input, conforme exigido pelo subject (seção VI.3.3).

**Thresholds verificados:**

| Faixa de disorder | Estratégia esperada | Saída no `strategy:` |
|---|---|---|
| disorder < 0.2 | Simple — O(n²) | `adaptive/simple` |
| 0.2 ≤ disorder < 0.5 | Medium — O(n√n) | `adaptive/medium` |
| disorder ≥ 0.5 | Complex — O(n log n) | `adaptive/complex` |

**Entradas usadas (determinísticas, tamanho 50):**

| Tipo | Como é gerada | Disorder calculado |
|---|---|---|
| `low` | ordenado [1..50] com 20 swaps adjacentes | 20/1225 ≈ **1.63%** |
| `medium` | primeira metade invertida [25..1, 26..50] | 300/1225 ≈ **24.49%** |
| `high` | completamente invertido [50..1] | 1225/1225 = **100.00%** |

O cálculo do disorder usa exatamente o mesmo algoritmo de `disorder.c`
(inversões de Kendall tau: `mistakes / total_pairs`).

**Testes de borda:**

| Entrada | n | Inversões | Disorder | Esperado |
|---|---|---|---|---|
| Primeiro 9 invertidos + resto ordenado | 20 | 36 | 36/190 ≈ 18.9% | `simple` |
| Primeiro 10 invertidos + resto ordenado | 20 | 45 | 45/190 ≈ 23.7% | `medium` |
| 6 invertidos + 4 ordenados | 10 | 39 | 39/45 ≈ 86.7% | `complex` |

**Verificação adicional:** compara o `disorder:` reportado pelo binário com
o valor calculado pelo mesmo algoritmo — ambos devem ser idênticos (`XX.XX%`).

---

### `compare_algos.sh`

Compara os 4 algoritmos **no mesmo input** e exibe a contagem de operações
lado a lado, em 4 perfis de desordem.

**Perfis testados:**

| Perfil | Como é gerado | Disorder típico |
|---|---|---|
| `sorted` | [1..n] já ordenado | 0% |
| `nearly` | [1..n] com ~5% dos elementos trocados | ~2-5% |
| `random` | permutação aleatória completa | ~50% |
| `reverse` | [n..1] completamente invertido | 100% |

Para cada perfil, exibe:
```
  estrategia        ops
  ----------  --------
  simple          8432
  medium          4219
  complex         3108
  adaptive        3108
```

Também reporta qual estratégia o `--adaptive` escolheu (via `--bench`) e
verifica que **todas as 4 estratégias ordenam corretamente** no perfil.

---

### `test_performance.sh`

Verifica que o número de operações fica dentro dos **limites do subject** (VI.6).

**Limites exigidos:**

| Tamanho | Reprova | Passa | Bom | Excelente |
|---|---|---|---|---|
| 100 números | ≥ 2000 | < 2000 | < 1500 | < 700 |
| 500 números | ≥ 12000 | < 12000 | < 8000 | < 5500 |

O critério de `[PASS]`/`[FAIL]` é o **pior caso** entre todas as rodadas.

**Também verifica (limites clássicos):**
- 3 números: ≤ 3 operações
- 5 números (50 amostras): pior caso ≤ 12 operações

**Estatísticas exibidas** por `stats.py`: mínimo, máximo, média, mediana e
veredito pelo pior caso.

**Parâmetros:**
```sh
bash tests/test_performance.sh [iters]
# padrão: iters=100 (rodadas por tamanho)
```

---

### `test_stability.sh`

Teste de stress com entradas grandes para detectar falhas graves.

**O que detecta em cada rodada:**

| Tipo de falha | Como é detectado |
|---|---|
| **Crash** / segfault | código de saída ≥ 128 (sinal do sistema) |
| **Loop infinito** | `timeout` encerra após `[timeout_s]` segundos (exit 124) |
| **Ordenação errada** | verificador retorna `KO` |
| **Não-determinismo** | mesma entrada → md5sum diferente em 2 execuções |

**Testes de entradas patológicas:**
- `[size]` números totalmente invertidos (pior caso de disorder)
- `[size]` números já ordenados (deve gerar 0 ou poucas operações)

**Parâmetros:**
```sh
bash tests/test_stability.sh [size] [iters] [timeout_s]
# padrão: size=500, iters=20, timeout_s=10
# no run_all.sh: size=500, iters=20, timeout_s=10
```

---

### `test_leaks.sh`

Detecta **vazamentos de memória** usando `valgrind --leak-check=full`.

**Caminhos testados:**

| Tipo | Exemplos |
|---|---|
| Válidos | ordenado `1..5`, invertido `5..1`, aleatório de `[count]` |
| **Caminhos de erro** | não-numérico, overflow, duplicado, `--`, string vazia |
| Flags | `--bench`, `--complex` com aleatório |

Os caminhos de erro são especialmente importantes: o parser deve liberar toda
a memória alocada **antes** de sair com erro (não há um `atexit` implícito).

O valgrind é configurado com:
```
--leak-check=full --show-leak-kinds=all --errors-for-leak-kinds=all --error-exitcode=42
```
Exit code 42 indica vazamento/erro de memória detectado.

**Pula automaticamente** se `valgrind` não estiver instalado.
No macOS: `leaks --atExit -- ./push_swap args...`

---

### `gen_plot.sh`

Coleta contagens de operações em múltiplos tamanhos de entrada e gera gráficos.

**Saídas produzidas:**
- `ps_perf.csv` — dados brutos: `size,strategy,min,avg,max` (uma linha por combinação)
- Gráfico **ASCII** no terminal por estratégia (sempre disponível)
- `ps_perf.png` — 4 linhas coloridas com bandas min/max por estratégia (requer `matplotlib`)
- `ps_perf.html` — fallback Chart.js via CDN quando matplotlib não está instalado

**Estratégias sempre testadas:** `adaptive`, `simple`, `medium`, `complex`

**Limites de skip** (combos impraticáveis):
- `simple` é pulado para `n > 500` (O(n²) gera milhões de ops)
- `medium` é pulado para `n > 5000` (O(n√n) fica muito lento)

```sh
bash tests/gen_plot.sh                             # 10 rodadas, n=5,50,100,200,300,500,1000,5000,10000
bash tests/gen_plot.sh 20 5 50 100 300 500 1000   # 20 rodadas, tamanhos customizados
```

**Linhas de referência no gráfico:** `n=100 passa (<2000)`, `n=100 excelente (<700)`,
`n=500 passa (<12000)`, `n=500 excelente (<5500)` — alinhadas com os thresholds do subject.

---

## Como a corretude é verificada

Por padrão, a suíte usa `ps_verify.py`, um verificador interno que:

1. Recebe os **mesmos argumentos inteiros** que o `push_swap` recebeu
2. Lê o **fluxo de operações** do stdin (linha por linha)
3. **Simula** as operações nas stacks A e B em Python
4. Retorna `OK` se A ficou em ordem crescente e B está vazia, `KO` caso contrário,
   `Error` se encontrar uma operação inválida

Isso garante que a suíte funciona **sem depender do `checker_linux` externo**.
Para usar o checker oficial da 42:

```sh
CHECKER=./checker_linux bash tests/run_all.sh
```

---

## Como o disorder é calculado

O disorder é a proporção de **pares fora de ordem** na stack A inicial
(inversões de Kendall tau), calculado **antes de qualquer operação**:

```
disorder = mistakes / total_pairs

onde:
  total_pairs = n * (n-1) / 2
  mistakes    = número de pares (i, j) com i < j mas stack[i] > stack[j]
```

Exemplos:
- Stack já ordenada: `mistakes = 0` → disorder = `0.00%`
- Stack totalmente invertida: `mistakes = total_pairs` → disorder = `100.00%`
- Stack parcialmente bagunçada: algum valor entre 0% e 100%

Implementação em `disorder.c`:
```c
for each pair (i, j) where i appears before j in the stack:
    total_pairs += 1
    if value[i] > value[j]:
        mistakes += 1
return mistakes / total_pairs
```

---

## Formato exato do `--bench`

Saída enviada ao **stderr** quando `--bench` está presente:

```
bench
disorder: 49.93%
strategy: adaptive/medium
complexity: O(n sqrt n)
total: 7997
sa: 0
sb: 0
ss: 0
pa: 500
pb: 500
ra: 4840
rb: 1098
rr: 0
rra: 0
rrb: 1059
rrr: 0
```

**Regras:**
- Primeira linha: `bench` (sem prefixo `[bench]`)
- `disorder:` — sempre 2 casas decimais com `%`
- `strategy:` — quando chamado via `--adaptive`: `adaptive/<nome>`;
  quando forçado via `--simple` etc.: apenas `<nome>` sem prefixo
- `complexity:` — `O(n²)` (ou `O(n^2)`), `O(n√n)` (ou `O(n sqrt n)`) ou `O(n log n)`
  (a implementação usa símbolos Unicode UTF-8: `²` = `\xc2\xb2`, `√` = `\xe2\x88\x9a`)
- `total:` — inteiro igual à soma dos 11 contadores
- O stdout permanece com **apenas as operações** (inalterado)
- Sem `--bench`, o **stderr permanece completamente vazio**

---

## Thresholds do `--adaptive`

Definidos em `sort_stubs.c` / subject seção VI.3.3:

```c
if (disorder < 0.2)   return STRAT_SIMPLE;   // O(n²)
if (disorder < 0.5)   return STRAT_MEDIUM;   // O(n√n)
return STRAT_COMPLEX;                         // O(n log n)
```

| Faixa | Algoritmo | Justificativa |
|---|---|---|
| disorder < 20% | Simple O(n²) | Poucos elementos fora de ordem: insertion é eficiente |
| 20% ≤ disorder < 50% | Medium O(n√n) | Desordem moderada: chunk sort mais eficiente que insertion |
| disorder ≥ 50% | Complex O(n log n) | Alta desordem: radix sort é claramente superior |

---

## Arquivos auxiliares

| Arquivo | Descrição |
|---|---|
| `lib.sh` | Configuração (`PS_BIN`, `CHK_BIN`, `LOG_FILE`), cores, helpers `pass()`/`fail()`/`info()`/`title()`/`summary()`, funções `need_ps_bin()`, `rand_nums()`, `verify_sort()`, `count_ops()` |
| `ps_verify.py` | Simulador das stacks A e B; verificador interno de corretude; interpreta todos os 11 ops |
| `stats.py` | Calcula min/max/avg/mediana de contagens de ops e exibe veredito vs. limites do subject |
| `agg.py` | Agrega contagens por tamanho para o `gen_plot.sh` |
| `plot.py` | Renderiza gráfico ASCII no terminal e PNG (se matplotlib disponível) |
| `logs/` | Criado automaticamente pelo `run_all.sh`; contém um arquivo `.log` por execução |

### Funções em `lib.sh`

```bash
pass "mensagem"       # incrementa PASS_COUNT, exibe [PASS] verde, grava no log
fail "mensagem"       # incrementa FAIL_COUNT, exibe [FAIL] vermelho, grava no log
info "mensagem"       # apenas exibe [INFO] amarelo e grava no log (nao conta)
title "secao"         # cabecalho de secao, grava no log
summary               # exibe "X passou, Y falhou" e retorna exit code 1 se FAIL_COUNT > 0

need_ps_bin           # aborta com exit 2 se PS_BIN nao existir/nao for executavel
need_chk_bin          # retorna 1 (sem abortar) se CHK_BIN nao existir

rand_nums N [LO] [HI] # gera N inteiros unicos aleatorios via Python
verify_sort arg...    # roda push_swap e passa ops para CHECKER ou ps_verify.py
count_ops arg...      # retorna contagem de linhas (operacoes) na saida do push_swap
```

---

## Observações

- Os `[FAIL]` de performance só passam com algoritmo otimizado (ex.: radix sort com ranks). Um sort O(n²) ingênuo reprova de propósito.
- `test_makefile.sh` altera o estado do projeto (executa `fclean`/`re`). Ao final sempre reconstrói o binário.
- `test_bench_format.sh` e `test_adaptive.sh` pressupõem o formato de saída exato de `bench_report.c`. Se a implementação usar nomes de campo diferentes, ajuste os scripts.
- No macOS: `valgrind` não existe — use `leaks --atExit -- ./push_swap args...` manualmente para os testes de memória.
- Sem `matplotlib`, o `gen_plot.sh` funciona normalmente e gera CSV + gráfico ASCII.
- A linha `[bench]` nos exemplos do subject é apenas **notação da documentação** — o binário real não imprime o prefixo `[bench]`, apenas o nome do campo.
