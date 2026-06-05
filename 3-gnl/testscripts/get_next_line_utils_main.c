#include "get_next_line.h"
#include <stdio.h>

int	main(void)
{
	char	*joined;
	char	*sub;

	printf("strlen NULL: %zu\n", ft_strlen(NULL));
	printf("strlen \"hello\": %zu\n", ft_strlen("hello"));
	printf("strchr \"hello\" 'l': %s\n", ft_strchr("hello", 'l'));
	printf("strchr NULL: %p\n", (void *)ft_strchr(NULL, 'a'));
	joined = ft_strjoin(NULL, "world");
	printf("strjoin NULL+\"world\": %s\n", joined);
	free(joined);
	sub = ft_substr("abcdef", 2, 3);
	printf("substr(\"abcdef\", 2, 3): %s\n", sub);
	free(sub);
	return (0);
}