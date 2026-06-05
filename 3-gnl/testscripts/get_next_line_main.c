#include "../get_next_line.h"
#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>

#define TMP_PATH "/tmp/gnl_test_mandatory.txt"

/* Writes content to a temp file. Returns 0 on success. */
static int	write_tmp(const char *content)
{
	int		fd;
	size_t	len;
	ssize_t	written;

	fd = open(TMP_PATH, O_WRONLY | O_CREAT | O_TRUNC, 0644);
	if (fd < 0)
		return (1);
	len = strlen(content);
	written = write(fd, content, len);
	close(fd);
	if ((size_t)written != len)
		return (1);
	return (0);
}

/* Reads the file via get_next_line and concatenates all lines.
   Caller must free the returned string. */
static char	*read_via_gnl(int fd)
{
	char	*result;
	char	*line;
	char	*tmp;
	size_t	total;
	size_t	line_len;

	result = malloc(1);
	if (!result)
		return (NULL);
	result[0] = '\0';
	total = 0;
	line = get_next_line(fd);
	while (line)
	{
		line_len = strlen(line);
		tmp = malloc(total + line_len + 1);
		if (!tmp)
		{
			free(line);
			free(result);
			return (NULL);
		}
		memcpy(tmp, result, total);
		memcpy(tmp + total, line, line_len + 1);
		free(result);
		free(line);
		result = tmp;
		total += line_len;
		line = get_next_line(fd);
	}
	return (result);
}

/* Runs one subtest: writes content to tmp file, reads via gnl,
   compares to the original. Returns 0 on pass, 1 on fail. */
static int	run_subtest(const char *name, const char *content)
{
	int		fd;
	char	*ft_out;
	int		result;

	printf("--- %s ---\n", name);
	if (write_tmp(content) != 0)
	{
		printf("FAIL: could not write tmp file\n");
		return (1);
	}
	fd = open(TMP_PATH, O_RDONLY);
	if (fd < 0)
	{
		printf("FAIL: could not open tmp file\n");
		return (1);
	}
	ft_out = read_via_gnl(fd);
	close(fd);
	if (!ft_out)
	{
		printf("FAIL: read_via_gnl returned NULL\n");
		return (1);
	}
	result = strcmp(ft_out, content);
	if (result == 0)
		printf("PASS\n");
	else
	{
		printf("FAIL: output differs\n");
		printf("FT  :[%s]\n", ft_out);
		printf("ORIG:[%s]\n", content);
	}
	free(ft_out);
	return (result == 0 ? 0 : 1);
}

/* Tests invalid fd. Returns 0 on pass, 1 on fail. */
static int	test_invalid_fd(void)
{
	char	*line;

	printf("--- invalid fd ---\n");
	line = get_next_line(-1);
	if (line == NULL)
	{
		printf("PASS\n");
		return (0);
	}
	printf("FAIL: expected NULL for fd=-1, got [%s]\n", line);
	free(line);
	return (1);
}

int	main(void)
{
	int	fails;

	fails = 0;
	fails += run_subtest("multiple lines with newline",
			"line one\nline two\nline three\n");
	fails += run_subtest("single line no newline",
			"only line no newline");
	fails += run_subtest("empty lines",
			"first\n\nthird\n\n\nsixth\n");
	fails += run_subtest("very long line",
			"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
			"BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB"
			"CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC\n"
			"short\n");
	fails += run_subtest("empty file", "");
	fails += test_invalid_fd();
	unlink(TMP_PATH);
	printf("\n=== TOTAL FAILS: %d ===\n", fails);
	if (fails == 0)
		return (0);
	return (1);
}