1. O que é uma função variádica?
   Podem receber varios argumentos, indefinidos. usa-se ... Numero variavel de args
   Variadic funcion
2. Como funcionam va_start, va_arg, va_copy e va_end
	Sao maros e funcionam como ponteiro movel caminhando pela memoria
	va_list e' a variavel criada.
	va_start(ap,ultimo param): inicializa ponteiro de argumentos (ap), ultimo_parametro e' o ultimo parametro fixo da funcao
	va_arg(ap, tipo): retorna o valor do argumento atual e avanca ap paa o proximo elemento. E' necessario especificar o tipo exato.
	va_copy(destino, origem): Cria copia exata do estadu atual da ap. Util se tem que passar o mesmo conjunto de argumentos mais de uma vez sem reiniciar do zero.
	va_end(ap): Finaliza uso do ponteiro e limpa recursos. Deve ser chamada antes do return
3. Como percorrer uma string de formato. termina o uso da va_list
while str[i]
4. Como detectar o caractere %
if str[i] = %

5. Como despachar cada conversão para uma função auxiliar
   helper com o proximo digito para cada funcao que imprima dependendo do tipo

6. Como imprimir números em bases diferentes
   converter para a outra base em string

7. Como contar corretamente o número de caracteres impressos
	soma do returno da funcao auxiliar mais o da funcao principal
8. Como tratar ponteiro NULL e string NULL
	tratar caso a caso, s por exemplo imprime (null), ponteiro null e' (nil)
	se format == Null, returna -1 -> padrao

9.  Ler o enunciado e entender que é uma biblioteca, não um programa.
10. Estudar funções variádicas.
11. Criar a estrutura inicial dos arquivos.
12. Preparar o Makefile.
13. Criar ft_printf.h.
14. Decidir se vai usar libft.
15. Planejar as funções auxiliares.
16. Listar os casos de teste.
17. Preparar o README.
18. Só depois começar o código.