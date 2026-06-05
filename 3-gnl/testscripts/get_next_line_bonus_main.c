#include "../get_next_line_bonus.h"
#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

#define TMP_A "/tmp/gnl_bonus_a.txt"
#define TMP_B "/tmp/gnl_bonus_b.txt"
#define TMP_C "/tmp/gnl_bonus_c.txt"

/* Writes content to a path. Returns 0 on success. */
static int	write_file(const char *path, const char *content)
{
	int		fd;
	size_t	len;
	ssize_t	written;

	fd = open(path, O_WRONLY | O_CREAT | O_TRUNC, 0644);
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
static char	*read_all(int fd)
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

/* Appends src to *dst (reallocating). Frees src and old *dst. */
static int	append_line(char **dst, char *src)
{
	char	*tmp;
	size_t	dst_len;
	size_t	src_len;

	if (!src)
		return (0);
	dst_len = strlen(*dst);
	src_len = strlen(src);
	tmp = malloc(dst_len + src_len + 1);
	if (!tmp)
	{
		free(src);
		return (1);
	}
	memcpy(tmp, *dst, dst_len);
	memcpy(tmp + dst_len, src, src_len + 1);
	free(*dst);
	free(src);
	*dst = tmp;
	return (0);
}

/* Standard subtest: write content, read via gnl, compare.
   Returns 0 on pass, 1 on fail. */
static int	run_basic(const char *name, const char *content)
{
	int		fd;
	char	*ft_out;
	int		ok;

	printf("--- %s ---\n", name);
	if (write_file(TMP_A, content) != 0)
		return (printf("FAIL: write\n"), 1);
	fd = open(TMP_A, O_RDONLY);
	if (fd < 0)
		return (printf("FAIL: open\n"), 1);
	ft_out = read_all(fd);
	close(fd);
	if (!ft_out)
		return (printf("FAIL: read_all NULL\n"), 1);
	ok = (strcmp(ft_out, content) == 0);
	if (ok)
		printf("PASS\n");
	else
	{
		printf("FAIL: output differs\n");
		printf("FT  :[%s]\n", ft_out);
		printf("ORIG:[%s]\n", content);
	}
	free(ft_out);
	return (ok ? 0 : 1);
}

/* Reads 3 fds in a round-robin manner. Builds 3 separate strings,
   one per fd, and compares each to the original content. */
static int	test_multiple_fds(void)
{
	const char	*ca = "A1\nA2\nA3\n";
	const char	*cb = "B1\nB2\nB3\nB4\n";
	const char	*cc = "C1\nC2\n";
	int			fds[3];
	char		*outs[3];
	int			i;
	int			active;
	char		*line;
	int			ok;

	printf("--- multiple fds interleaved ---\n");
	if (write_file(TMP_A, ca) || write_file(TMP_B, cb)
		|| write_file(TMP_C, cc))
		return (printf("FAIL: write\n"), 1);
	fds[0] = open(TMP_A, O_RDONLY);
	fds[1] = open(TMP_B, O_RDONLY);
	fds[2] = open(TMP_C, O_RDONLY);
	if (fds[0] < 0 || fds[1] < 0 || fds[2] < 0)
		return (printf("FAIL: open\n"), 1);
	i = 0;
	while (i < 3)
	{
		outs[i] = malloc(1);
		outs[i][0] = '\0';
		i++;
	}
	active = 3;
	while (active > 0)
	{
		active = 0;
		i = 0;
		while (i < 3)
		{
			line = get_next_line(fds[i]);
			if (line)
			{
				append_line(&outs[i], line);
				active++;
			}
			i++;
		}
	}
	close(fds[0]);
	close(fds[1]);
	close(fds[2]);
	ok = (strcmp(outs[0], ca) == 0
			&& strcmp(outs[1], cb) == 0
			&& strcmp(outs[2], cc) == 0);
	if (ok)
		printf("PASS\n");
	else
	{
		printf("FAIL: outputs differ\n");
		printf("FT_A  :[%s]\n", outs[0]);
		printf("ORIG_A:[%s]\n", ca);
		printf("FT_B  :[%s]\n", outs[1]);
		printf("ORIG_B:[%s]\n", cb);
		printf("FT_C  :[%s]\n", outs[2]);
		printf("ORIG_C:[%s]\n", cc);
	}
	free(outs[0]);
	free(outs[1]);
	free(outs[2]);
	return (ok ? 0 : 1);
}

/* Opens the same file twice and reads in round-robin.
   Each fd should have independent state and yield the full content. */
static int	test_same_file_twice(void)
{
	const char	*content = "X1\nX2\nX3\nX4\nX5\n";
	int			fd1;
	int			fd2;
	char		*out1;
	char		*out2;
	char		*line;
	int			active;
	int			ok;

	printf("--- same file twice ---\n");
	if (write_file(TMP_A, content) != 0)
		return (printf("FAIL: write\n"), 1);
	fd1 = open(TMP_A, O_RDONLY);
	fd2 = open(TMP_A, O_RDONLY);
	if (fd1 < 0 || fd2 < 0)
		return (printf("FAIL: open\n"), 1);
	out1 = malloc(1);
	out2 = malloc(1);
	out1[0] = '\0';
	out2[0] = '\0';
	active = 1;
	while (active)
	{
		active = 0;
		line = get_next_line(fd1);
		if (line)
		{
			append_line(&out1, line);
			active = 1;
		}
		line = get_next_line(fd2);
		if (line)
		{
			append_line(&out2, line);
			active = 1;
		}
	}
	close(fd1);
	close(fd2);
	ok = (strcmp(out1, content) == 0 && strcmp(out2, content) == 0);
	if (ok)
		printf("PASS\n");
	else
	{
		printf("FAIL: outputs differ\n");
		printf("FT_1  :[%s]\n", out1);
		printf("FT_2  :[%s]\n", out2);
		printf("ORIG  :[%s]\n", content);
	}
	free(out1);
	free(out2);
	return (ok ? 0 : 1);
}

static int	test_invalid_fd(void)
{
	char	*line;

	printf("--- invalid fd ---\n");
	line = get_next_line(-1);
	if (line == NULL)
		return (printf("PASS\n"), 0);
	printf("FAIL: expected NULL for fd=-1, got [%s]\n", line);
	free(line);
	return (1);
}

int	main(void)
{
	int	fails;

	fails = 0;
	fails += run_basic("multiple lines with newline",
			"line one\nline two\nline three\n");
	fails += run_basic("single line no newline",
			"only line no newline");
	fails += run_basic("empty lines",
			"first\n\nthird\n\n\nsixth\n");
	fails += run_basic("very long line",
			"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
			"BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB"
			"CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC\n"
			"short\n");
	fails += run_basic("empty file", "");
	fails += test_invalid_fd();
	fails += test_multiple_fds();
	fails += test_same_file_twice();
	unlink(TMP_A);
	unlink(TMP_B);
	unlink(TMP_C);
	printf("\n=== TOTAL FAILS: %d ===\n", fails);
	if (fails == 0)
		return (0);
	return (1);
}