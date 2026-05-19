## Scripts de teste da libft

Este projeto usa alguns scripts shell para conferir a libft antes da entrega.

A ideia geral e:

1. manter os arquivos da libft na raiz do projeto;
2. manter os testes em `testscripts/`;
3. cada teste fica em um arquivo `.txt` com o nome da funcao;
4. os scripts usam esses `.txt` como `main` temporario;
5. os resultados ficam salvos em pastas de logs.

Exemplo:

```txt
ft_strlen.c
testscripts/ft_strlen.txt
logs/ft_strlen.log
```
---

## `1checkfiles.sh`

Esse script verifica se o projeto tem os arquivos esperados da libft.

Ele confere:

* arquivos obrigatorios do subject;
* `libft.h`;
* `Makefile`;
* funcoes obrigatorias;
* funcoes bonus de lista;
* arquivos `.c` extras que nao pertencem ao projeto;
* existencia do `README.md`;
* Norminette nos arquivos da libft.

Saidas principais:

```txt
✅ NORM OK
❌ NORM ERR
❌ FALTANDO
⚠️ EXTRA
```

Use esse script para conferir se a pasta esta limpa e se todos os arquivos
esperados existem antes de entregar.

---

## `3tester.sh`

Esse e o teste funcional principal.

Ele faz uma mini-Moulinette caseira:

1. procura cada arquivo `ft_*.c`;
2. procura um teste com o mesmo nome em `testscripts/ft_*.txt`;
3. copia o `.txt` para `main_test.c`;
4. compila `main_test.c` com todos os `ft_*.c`;
5. executa o programa;
6. compara as linhas `FT  :` com as linhas `ORIG:`;
7. salva o resultado em `logs/`.

O formato esperado dos testes e:

```txt
FT  : resultado da minha funcao
ORIG: resultado esperado
```

Cada linha `FT  :` precisa ter uma linha `ORIG:` correspondente.

Saidas principais:

```txt
✅ PASSOU
❌ FALHOU
❌ COMPILA
💥 CRASH
⚠️ FORMATO
⚪ SEM TESTE
```

Significado:

```txt
✅ PASSOU
FT e ORIG ficaram iguais.

❌ FALHOU
O programa rodou, mas FT e ORIG deram resultados diferentes.

❌ COMPILA
O teste ou algum arquivo da libft nao compilou.

💥 CRASH
O programa compilou, mas quebrou durante a execucao.

⚠️ FORMATO
Faltam linhas FT/ORIG ou a quantidade de linhas esta diferente.

⚪ SEM TESTE
Existe ft_nome.c, mas nao existe testscripts/ft_nome.txt.
```

---

## `2memcheckValgrind.sh`

Esse script roda os testes usando Valgrind.

Ele serve para encontrar problemas de memoria, como:

* leaks;
* invalid read;
* invalid write;
* uso de memoria nao inicializada;
* uso de ponteiro invalido;
* crash durante a execucao.

Ele tambem usa os arquivos `.txt` de `testscripts/` como `main` temporario.

O alvo continua sendo a libft.

Saidas principais:

```txt
✅ OK
⚠️ LEAK
❌ ERRO MEM
💥 CRASH
❌ COMPILA
⚪ SEM TESTE
```

Significado:

```txt
✅ OK
Sem leaks importantes e sem erros de memoria.

⚠️ LEAK
Memoria foi alocada e nao foi liberada.

❌ ERRO MEM
Valgrind encontrou erro de memoria.

💥 CRASH
O programa quebrou durante a execucao.

❌ COMPILA
Nao conseguiu compilar o teste.

⚪ SEM TESTE
Nao existe teste para aquela funcao.
```

Importante:

O Valgrind analisa o programa inteiro.

Entao, se o proprio teste esquecer de dar `free`, o Valgrind tambem acusa
leak. Por isso, todo teste que aloca memoria precisa liberar corretamente.

Exemplos:

```c
free(ptr);
free_split(arr);
ft_lstclear(&lst, free);
```

---

## `4Checksanitizer.sh`

Esse script faz checks mais rigidos de qualidade.

Ele tem tres partes:

1. compilacao estrita;
2. sanitizers;
3. cppcheck.

A compilacao estrita usa flags extras, alem de:

```bash
-Wall -Wextra -Werror
```

Ela tambem pode usar flags como:

```bash
-Wshadow
-Wconversion
-Wstrict-prototypes
-Wmissing-prototypes
-Wpedantic
-Wunreachable-code
-Wcast-align
```

Essas flags ajudam a achar:

* conversoes implicitas perigosas;
* variaveis que escondem outras;
* prototipos ausentes;
* casts suspeitos;
* codigo inalcançavel;
* problemas que a Moulinette talvez nao mostre.

A parte dos sanitizers usa:

```bash
-fsanitize=address,undefined
```

Isso ajuda a encontrar:

* acesso fora de array;
* uso de ponteiro invalido;
* undefined behavior;
* alguns casos de overflow;
* crash durante execucao.

A parte do `cppcheck` roda apenas se ele estiver instalado.

Para instalar:

```bash
sudo apt install cppcheck
```

Importante:

Esse script e mais rigoroso que a Moulinette. Ele deve ser usado como ajuda
para melhorar o codigo, nao como regra absoluta da 42.

---

## Sobre os arquivos `.txt` em `testscripts/`

Os arquivos `.txt` sao codigos C completos, normalmente contendo um `main`.

Eles usam `.txt` apenas para nao misturar os testes com os arquivos reais da
libft.

Exemplo:

```txt
testscripts/ft_strlen.txt
```

Esse arquivo testa:

```txt
ft_strlen.c
```

Durante o teste, o script copia esse arquivo para:

```txt
main_test.c
```

Depois compila:

```bash
cc main_test.c ft_*.c
```

Por isso os testes conseguem usar qualquer funcao da libft como dependencia.

---

## Padrao dos testes

Todo teste deve imprimir resultados nesse formato:

```txt
FT  : resultado da funcao testada
ORIG: resultado esperado
```

Exemplo:

```txt
FT  : 42
ORIG: 42
```

Certo:

```txt
FT  : Hello
ORIG: Hello
```

Errado:

```txt
FT  : antes = hello
FT  : Hello
ORIG: Hello
```

Se precisar imprimir informacao extra, use outro prefixo:

```txt
INFO:
DEBUG:
antes:
```

Nunca use `FT  :` se nao houver um `ORIG:` correspondente.

---

## Pastas de logs

Cada script salva os resultados em uma pasta propria:

```txt
logs/
logs_valgrind/
logs_quality/
```

Exemplos:

```txt
logs/ft_strlen.log
logs_valgrind/ft_split.log
logs_quality/ft_itoa.compile.log
```

Quando algo falhar, abra o log correspondente para ver o erro completo.

---

## Como rodar

Dê permissao de execucao:

```bash
chmod +x 1checkfiles.sh
chmod +x 2memcheckValgrind.sh
chmod +x 3tester.sh
chmod +x 4Checksanitizer.sh
```

Rode:

```bash
./1checkfiles.sh
./3tester.sh
./2memcheckValgrind.sh
./4Checksanitizer.sh
```

Ordem recomendada:

```txt
1. ./1checkfiles.sh
2. ./3tester.sh
3. ./2memcheckValgrind.sh
4. ./4Checksanitizer.sh
```

---

## Resumo rapido

```txt
1checkfiles.sh
Confere arquivos obrigatorios, extras, README e Norminette.

3tester.sh
Roda testes funcionais comparando FT com ORIG.

2memcheckValgrind.sh
Roda Valgrind para achar leaks e erros de memoria.

4Checksanitizer.sh
Roda checks mais rigidos com flags extras, sanitizers e cppcheck.

testscripts/*.txt
Sao mains de teste usados temporariamente pelos scripts.
```
