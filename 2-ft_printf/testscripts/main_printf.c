
/* ************************************************************************** */
/*                                                                            */
/* TESTES REALIZADOS                                                          */
/*                                                                            */
/* Este arquivo e usado pelo script test_printf.sh.                            */
/* Ele compara a saida e o retorno de ft_printf com printf original.           */
/*                                                                            */
/* Casos testados:                                                            */
/*                                                                            */
/* 1.  string vazia usando %s                                                  */
/* 2.  texto simples sem conversao                                             */
/* 3.  %c com caractere normal                                                 */
/* 4.  %c com caractere nulo '\0' no meio                                      */
/* 5.  %s com string normal                                                    */
/* 6.  %s com NULL                                                             */
/* 7.  %d com zero                                                             */
/* 8.  %d com numero negativo                                                  */
/* 9.  %d com INT_MIN                                                          */
/* 10. %d com INT_MAX                                                          */
/* 11. %i e %d misturados                                                      */
/* 12. %u com zero                                                             */
/* 13. %u com UINT_MAX                                                         */
/* 14. %x com zero                                                             */
/* 15. %x com hexadecimal minusculo                                            */
/* 16. %X com hexadecimal maiusculo                                            */
/* 17. %x com UINT_MAX                                                         */
/* 18. %X com UINT_MAX                                                         */
/* 19. %p com ponteiro valido fixo                                             */
/* 20. %p com ponteiro NULL                                                    */
/* 21. %% simples                                                              */
/* 22. %% no meio de uma string                                                */
/* 23. todos os tipos obrigatorios juntos                                      */
/* 24. caso misto pesado com %p %s %d %x                                       */
/* 25. strings vazias misturadas com string normal                             */
/* 26. %d%d%d sem separador                                                    */
/* 27. %x%x%x sem separador                                                    */
/* 28. %s %s com primeira string NULL                                          */
/* 29. %c com '\0' sozinho                                                     */
/* 30. %c com '\0' no meio da string                                           */
/* 31. varios percentuais seguidos                                             */
/* 32. varias strings vazias                                                   */
/* 33. varios numeros negativos                                                */
/* 34. %x e %X misturados                                                      */
/* 35. dois ponteiros validos fixos                                            */
/*                                                                            */
/* Observacoes:                                                               */
/*                                                                            */
/* - Os testes de %p usam ponteiros fixos para evitar diferenca de endereco    */
/*   entre execucoes separadas.                                                */
/* - Casos invalidos como "%", "abc%" e "%q" nao entram aqui, pois podem      */
/*   cair em comportamento indefinido no printf original.                      */
/* - Este arquivo testa apenas o mandatory, nao testa bonus.                   */
/*                                                                            */
/* ************************************************************************** */


#include "ft_printf.h"
#include <stdio.h>
#include <string.h>
#include <limits.h>
#include <stdlib.h>
#include <stdint.h>

static int	run_ft_one(int id)
{
	char	*null_str;

	null_str = NULL;
	if (id == 1)
		return (ft_printf("%s", ""));
	if (id == 2)
		return (ft_printf("abc"));
	if (id == 3)
		return (ft_printf("hello %c", 'A'));
	if (id == 4)
		return (ft_printf("%c%c%c", 'a', '\0', 'b'));
	if (id == 5)
		return (ft_printf("%s", "hello"));
	if (id == 6)
		return (ft_printf("%s", null_str));
	if (id == 7)
		return (ft_printf("%d", 0));
	if (id == 8)
		return (ft_printf("%d", -42));
	if (id == 9)
		return (ft_printf("%d", INT_MIN));
	if (id == 10)
		return (ft_printf("%d", INT_MAX));
	if (id == 11)
		return (ft_printf("%i %d", -1, 2147483647));
	if (id == 12)
		return (ft_printf("%u", 0));
	return (-9999);
}

static int	run_ft_two(int id)
{
	if (id == 13)
		return (ft_printf("%u", UINT_MAX));
	if (id == 14)
		return (ft_printf("%x", 0));
	if (id == 15)
		return (ft_printf("%x", 255));
	if (id == 16)
		return (ft_printf("%X", 255));
	if (id == 17)
		return (ft_printf("%x", UINT_MAX));
	if (id == 18)
		return (ft_printf("%X", UINT_MAX));
	if (id == 19)
		return (ft_printf("%p", (void *)(uintptr_t)255));
	if (id == 20)
		return (ft_printf("%p", NULL));
	if (id == 21)
		return (ft_printf("%%"));
	if (id == 22)
		return (ft_printf("a%%b%%c"));
	if (id == 23)
		return (ft_printf("%c %s %d %i %u %x %X %%",
				'Z', "ok", -12, 34, 42, 255, 255));
	if (id == 24)
		return (ft_printf("ptr:%p str:%s int:%d hex:%x",
				(void *)(uintptr_t)255, "abc", -99, 3735928559u));
	if (id == 25)
		return (ft_printf("%s%s%s", "", "middle", ""));
	return (-9999);
}

static int	run_ft_three(int id)
{
	char	*null_str;

	null_str = NULL;
	if (id == 26)
		return (ft_printf("%d%d%d", 1, 2, 3));
	if (id == 27)
		return (ft_printf("%x%x%x", 10, 11, 12));
	if (id == 28)
		return (ft_printf("%s %s", null_str, "abc"));
	if (id == 29)
		return (ft_printf("%c", '\0'));
	if (id == 30)
		return (ft_printf("a%cb", '\0'));
	if (id == 31)
		return (ft_printf("%%%%%%"));
	if (id == 32)
		return (ft_printf("%s%s%s", "", "", ""));
	if (id == 33)
		return (ft_printf("%d %d %d", -1, -22, -333));
	if (id == 34)
		return (ft_printf("%x %X %x %X", 10, 10, 48879, 48879));
	if (id == 35)
		return (ft_printf("%p %p",
				(void *)(uintptr_t)255, (void *)(uintptr_t)4096));
	return (-9999);
}

static int	run_orig_one(int id)
{
	char	*null_str;

	null_str = NULL;
	if (id == 1)
		return (printf("%s", ""));
	if (id == 2)
		return (printf("abc"));
	if (id == 3)
		return (printf("hello %c", 'A'));
	if (id == 4)
		return (printf("%c%c%c", 'a', '\0', 'b'));
	if (id == 5)
		return (printf("%s", "hello"));
	if (id == 6)
		return (printf("%s", null_str));
	if (id == 7)
		return (printf("%d", 0));
	if (id == 8)
		return (printf("%d", -42));
	if (id == 9)
		return (printf("%d", INT_MIN));
	if (id == 10)
		return (printf("%d", INT_MAX));
	if (id == 11)
		return (printf("%i %d", -1, 2147483647));
	if (id == 12)
		return (printf("%u", 0));
	return (-9999);
}

static int	run_orig_two(int id)
{
	if (id == 13)
		return (printf("%u", UINT_MAX));
	if (id == 14)
		return (printf("%x", 0));
	if (id == 15)
		return (printf("%x", 255));
	if (id == 16)
		return (printf("%X", 255));
	if (id == 17)
		return (printf("%x", UINT_MAX));
	if (id == 18)
		return (printf("%X", UINT_MAX));
	if (id == 19)
		return (printf("%p", (void *)(uintptr_t)255));
	if (id == 20)
		return (printf("%p", NULL));
	if (id == 21)
		return (printf("%%"));
	if (id == 22)
		return (printf("a%%b%%c"));
	if (id == 23)
		return (printf("%c %s %d %i %u %x %X %%",
				'Z', "ok", -12, 34, 42, 255, 255));
	if (id == 24)
		return (printf("ptr:%p str:%s int:%d hex:%x",
				(void *)(uintptr_t)255, "abc", -99, 3735928559u));
	if (id == 25)
		return (printf("%s%s%s", "", "middle", ""));
	return (-9999);
}

static int	run_orig_three(int id)
{
	char	*null_str;

	null_str = NULL;
	if (id == 26)
		return (printf("%d%d%d", 1, 2, 3));
	if (id == 27)
		return (printf("%x%x%x", 10, 11, 12));
	if (id == 28)
		return (printf("%s %s", null_str, "abc"));
	if (id == 29)
		return (printf("%c", '\0'));
	if (id == 30)
		return (printf("a%cb", '\0'));
	if (id == 31)
		return (printf("%%%%%%"));
	if (id == 32)
		return (printf("%s%s%s", "", "", ""));
	if (id == 33)
		return (printf("%d %d %d", -1, -22, -333));
	if (id == 34)
		return (printf("%x %X %x %X", 10, 10, 48879, 48879));
	if (id == 35)
		return (printf("%p %p",
				(void *)(uintptr_t)255, (void *)(uintptr_t)4096));
	return (-9999);
}

int	main(int argc, char **argv)
{
	int	id;
	int	ret;

	if (argc != 3)
		return (1);
	id = atoi(argv[2]);
	if (strcmp(argv[1], "ft") == 0 && id <= 12)
		ret = run_ft_one(id);
	else if (strcmp(argv[1], "ft") == 0 && id <= 25)
		ret = run_ft_two(id);
	else if (strcmp(argv[1], "ft") == 0)
		ret = run_ft_three(id);
	else if (strcmp(argv[1], "orig") == 0 && id <= 12)
		ret = run_orig_one(id);
	else if (strcmp(argv[1], "orig") == 0 && id <= 25)
		ret = run_orig_two(id);
	else if (strcmp(argv[1], "orig") == 0)
		ret = run_orig_three(id);
	else
		return (1);
	fprintf(stderr, "RET:%d\n", ret);
	return (0);
}

/* ************************************************************************** */
/*                                                                            */
/* TESTES REALIZADOS                                                          */
/*                                                                            */
/* Este arquivo e usado pelo script tester.sh para comparar ft_printf com      */
/* printf original. Para cada caso, o script compara:                          */
/*                                                                            */
/* - saida padrao byte a byte                                                  */
/* - valor de retorno                                                          */
/* - crash ou erro de execucao                                                 */
/*                                                                            */
/* CASE 1                                                                      */
/* Testa string vazia usando %s.                                               */
/* Verifica se ft_printf imprime nada e retorna 0.                             */
/*                                                                            */
/* CASE 2                                                                      */
/* Testa texto simples sem nenhuma conversao.                                  */
/* Verifica se caracteres normais sao impressos e contados corretamente.       */
/*                                                                            */
/* CASE 3                                                                      */
/* Testa %c com caractere normal.                                              */
/* Verifica se um char recebido por va_arg como int e impresso corretamente.   */
/*                                                                            */
/* CASE 4                                                                      */
/* Testa %c com caractere '\0' no meio.                                        */
/* Verifica se o byte nulo e impresso e contado mesmo sem aparecer na tela.    */
/*                                                                            */
/* CASE 5                                                                      */
/* Testa %s com string normal.                                                 */
/* Verifica se a string inteira e impressa e se o retorno bate com strlen.     */
/*                                                                            */
/* CASE 6                                                                      */
/* Testa %s com NULL.                                                          */
/* Verifica se ft_printf imita printf ao receber uma string nula.              */
/*                                                                            */
/* CASE 7                                                                      */
/* Testa %d com zero.                                                          */
/* Verifica se 0 e impresso como um caractere e retorna 1.                     */
/*                                                                            */
/* CASE 8                                                                      */
/* Testa %d com numero negativo simples.                                       */
/* Verifica se o sinal '-' e contado junto com os digitos.                     */
/*                                                                            */
/* CASE 9                                                                      */
/* Testa %d com INT_MIN.                                                       */
/* Verifica se o menor int e impresso sem overflow.                            */
/*                                                                            */
/* CASE 10                                                                     */
/* Testa %d com INT_MAX.                                                       */
/* Verifica se o maior int positivo e impresso corretamente.                   */
/*                                                                            */
/* CASE 11                                                                     */
/* Testa %i e %d juntos.                                                       */
/* Verifica se os dois usam a mesma logica decimal em base 10.                 */
/*                                                                            */
/* CASE 12                                                                     */
/* Testa %u com zero.                                                          */
/* Verifica se unsigned zero imprime 0 e retorna 1.                            */
/*                                                                            */
/* CASE 13                                                                     */
/* Testa %u com UINT_MAX.                                                      */
/* Verifica se unsigned int grande nao e tratado como int negativo.            */
/*                                                                            */
/* CASE 14                                                                     */
/* Testa %x com zero.                                                          */
/* Verifica se hexadecimal zero imprime apenas 0.                              */
/*                                                                            */
/* CASE 15                                                                     */
/* Testa %x com 255.                                                           */
/* Verifica conversao hexadecimal minuscula: 255 deve virar ff.                */
/*                                                                            */
/* CASE 16                                                                     */
/* Testa %X com 255.                                                           */
/* Verifica conversao hexadecimal maiuscula: 255 deve virar FF.                */
/*                                                                            */
/* CASE 17                                                                     */
/* Testa %x com UINT_MAX.                                                      */
/* Verifica hexadecimal minusculo com o maior unsigned int.                    */
/*                                                                            */
/* CASE 18                                                                     */
/* Testa %X com UINT_MAX.                                                      */
/* Verifica hexadecimal maiusculo com o maior unsigned int.                    */
/*                                                                            */
/* CASE 19                                                                     */
/* Testa %p com ponteiro valido fixo.                                          */
/* Usa um endereco fixo para evitar diferenca entre execucoes separadas.       */
/*                                                                            */
/* CASE 20                                                                     */
/* Testa %p com NULL.                                                          */
/* Verifica se ponteiro nulo segue o mesmo formato do printf do ambiente.      */
/*                                                                            */
/* CASE 21                                                                     */
/* Testa %% sozinho.                                                           */
/* Verifica se imprime apenas o caractere porcentagem e retorna 1.             */
/*                                                                            */
/* CASE 22                                                                     */
/* Testa %% no meio de uma string.                                             */
/* Verifica se porcentagens escapadas nao consomem argumentos.                 */
/*                                                                            */
/* CASE 23                                                                     */
/* Testa todos os tipos obrigatorios juntos.                                   */
/* Verifica c s d i u x X e %% na mesma chamada.                               */
/*                                                                            */
/* CASE 24                                                                     */
/* Testa um caso misto pesado.                                                 */
/* Mistura %p %s %d e %x em uma frase maior.                                   */
/*                                                                            */
/* CASE 25                                                                     */
/* Testa strings vazias misturadas com string normal.                          */
/* Verifica se strings vazias nao quebram a contagem.                          */
/*                                                                            */
/* CASE 26                                                                     */
/* Testa %d%d%d sem separador.                                                 */
/* Verifica se varios inteiros seguidos sao impressos sem perder argumento.    */
/*                                                                            */
/* CASE 27                                                                     */
/* Testa %x%x%x sem separador.                                                 */
/* Verifica se varios hexadecimais seguidos consomem os argumentos certos.     */
/*                                                                            */
/* CASE 28                                                                     */
/* Testa %s %s com a primeira string NULL.                                     */
/* Verifica NULL seguido de string valida na mesma chamada.                    */
/*                                                                            */
/* CASE 29                                                                     */
/* Testa %c com '\0' sozinho.                                                  */
/* Verifica se o byte nulo e impresso e se o retorno e 1.                      */
/*                                                                            */
/* CASE 30                                                                     */
/* Testa %c com '\0' no meio da string.                                        */
/* Verifica se a contagem inclui o byte nulo entre dois caracteres visiveis.   */
/*                                                                            */
/* CASE 31                                                                     */
/* Testa varios percentuais seguidos.                                          */
/* Verifica se %%%%%% imprime a quantidade correta de porcentagens.            */
/*                                                                            */
/* CASE 32                                                                     */
/* Testa varias strings vazias.                                                */
/* Verifica se multiplos %s vazios retornam 0 e nao imprimem lixo.             */
/*                                                                            */
/* CASE 33                                                                     */
/* Testa varios numeros negativos.                                             */
/* Verifica se cada sinal '-' e impresso e contado corretamente.               */
/*                                                                            */
/* CASE 34                                                                     */
/* Testa %x e %X misturados.                                                   */
/* Verifica alternancia entre hexadecimal minusculo e maiusculo.               */
/*                                                                            */
/* CASE 35                                                                     */
/* Testa dois ponteiros validos fixos.                                         */
/* Verifica se dois %p na mesma chamada consomem e imprimem os dois valores.   */
/*                                                                            */
/* Observacoes:                                                               */
/*                                                                            */
/* - Este arquivo testa apenas o mandatory do ft_printf.                       */
/* - Nao testa flags, width, precision ou bonus.                               */
/* - Casos invalidos como "%", "abc%" e "%q" nao entram aqui porque podem     */
/*   cair em comportamento indefinido no printf original.                      */
/* - Os testes de %p usam valores fixos convertidos para ponteiro para evitar  */
/*   diferencas de endereco entre processos diferentes.                        */
/*                                                                            */
/* ************************************************************************** */