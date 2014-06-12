#!/usr/bin/env bash
# Return the number of work items to do and blocked

todo_file="/work/todo.txt"

run_segment() {
	if [ ! -f "$todo_file" ]; then
		return 1
	fi

	local todo_count=$(grep "*" ${todo_file} | wc -l)
	local blocked_count=$(grep "^\W*x" ${todo_file} | wc -l)

	if [ "$todo_count" -gt "0" ]; then
		echo "⚡︎ ${todo_count}|${blocked_count}"
	fi

	return 0
}
