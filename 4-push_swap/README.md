#TODO
 Operations:
	- sa (swap a): Swap the first two elements at the top of stack a. Do nothing if there is only one or no elements.
	- sb (swap b): Swap the first two elements at the top of stack b. Do nothing if there is only one or no elements.
	- ss : sa and sb at the same time. 
	- pa (push a): Take the first element at the top of b and put it at the top of a. Do nothing if b is empty.
	- pb (push b): Take the first element at the top of a and put it at the top of b. Do nothing if a is empty.
	- ra (rotate a): Shift up all elements of stack a by one. The first element becomes the last one.
	- rb (rotate b): Shift up all elements of stack b by one. The first element becomes the last one.
	- rr : ra and rb at the same time.
	- rra (reverse rotate a): Shift down all elements of stack a by one. The last element becomes the first one.
	- rrb (reverse rotate b): Shift down all elements of stack b by one. The last element becomes the first one.
	- rrr : rra and rrb at the same time.

Algorithm:
	- 4 Strategies - Must select in runtime, based in input.
		- Each strategy generates sequence of operation.
	Metric: Complexity = number os moves

Disorder Metric You must measure the disorder before doing any moves.:
	function compute_disorder(stack a):
	mistakes = 0
	total_pairs = 0
	for i from 0 to size(a)-1:
	for j from i+1 to size(a)-1:
	total_pairs += 1
	if a[i] > a[j]:
	mistakes += 1
	return mistakes / total_pairs


1. Simple algorithm (O(n2)):
Implement at least one baseline algorithm in the O(n2) class. Examples include:
• Insertion sort adaptation
• Selection sort adaptation
• Bubble sort adaptation
• Simple min/max extraction methods

2. Medium algorithm (O(n√n)):
Implement at least one algorithm in the O(n√n) class. Examples include:
• Chunk-based sorting (divide into √n chunks)
• Block-based partitioning methods
• Bucket sort adaptations with √n buckets
• Range-based sorting strategies
3. Complex algorithm (O(n log n)):
Implement at least one algorithm in the O(n log n) class. Examples include:
• Radix sort adaptation (LSD or MSD)
• Merge sort adaptation using two stacks
• Quick sort adaptation with stack partitioning
• Heap sort adaptation
• Binary indexed tree approaches
4. Custom adaptive algorithm (learner’s design): Design an adaptive strategy
that selects different internal methods depending on the measured disorder. You are not constrained to any specific named algorithm; the internal techniques are entirely up to you. However, your design must respect the following complexity targets per regime (in the Push_swap operation model):
Low disorder: if disorder < 0.2, your chosen method must run in O(n2) time.
Medium disorder: if 0.2 ≤ disorder < 0.5, your chosen method must run in
O(n√n) time.
High disorder: if disorder ≥ 0.5, your chosen method must run in O(n log n)
time.
You must document in your repository (e.g., README.md) the rationale for your
thresholds, the internal techniques used in each regime, and a brief complexity argument (upper bounds) for time and space within the Push_swap model.

- Makefile

• You must write a program named push_swap that takes as arguments:
◦ The stack a formatted as a list of integers (the first argument is the top of the stack).
◦ An optional strategy selector:
--simple Forces the use of your O(n 2) algorithm.
--medium Forces the use of your O(n√n) algorithm.
--complex Forces the use of your O(n log n) algorithm.
--adaptive Forces the use of your adaptive algorithm based on disorder.
This is the default behavior if no selector is given.