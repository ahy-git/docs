#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include "get_next_line_bonus.h"

static void	print_line(char *label, char *line)
{
	printf("%s", label);
	if (line)
	{
		printf("[%s]", line);
		free(line);
	}
	else
		printf("[NULL]");
	printf("\n");
}

int	main(void)
{
	int		fd1;
	int		fd2;
	int		fd3;
	char	*line;

	fd1 = open("file1.txt", O_RDONLY);
	fd2 = open("file2.txt", O_RDONLY);
	fd3 = open("file3.txt", O_RDONLY);
	if (fd1 < 0 || fd2 < 0 || fd3 < 0)
	{
		perror("open");
		return (1);
	}

	line = get_next_line(fd1);
	print_line("fd1 line 1: ", line);

	line = get_next_line(fd2);
	print_line("fd2 line 1: ", line);

	line = get_next_line(fd3);
	print_line("fd3 line 1: ", line);

	line = get_next_line(fd1);
	print_line("fd1 line 2: ", line);

	line = get_next_line(fd2);
	print_line("fd2 line 2: ", line);

	line = get_next_line(fd3);
	print_line("fd3 line 2: ", line);

	line = get_next_line(fd1);
	print_line("fd1 line 3: ", line);

	line = get_next_line(fd2);
	print_line("fd2 line 3: ", line);

	line = get_next_line(fd3);
	print_line("fd3 line 3: ", line);

	line = get_next_line(fd1);
	print_line("fd1 EOF: ", line);

	line = get_next_line(fd2);
	print_line("fd2 EOF: ", line);

	line = get_next_line(fd3);
	print_line("fd3 EOF: ", line);

	close(fd1);
	close(fd2);
	close(fd3);
	return (0);
}