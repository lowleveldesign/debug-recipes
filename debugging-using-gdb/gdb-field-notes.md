
## General

To ptrace any process, you may add ptrace capability to gdb:

```
sudo setcap cap_sys_ptrace=eip $(which gdb)
```

set disassembly-flavor intel

## Symbols

https://sourceware.org/elfutils/Debuginfod.html



```
set debuginfod enable on
```

## Breakpoints

b {func} - set breakpoint on testfunc
b {[file:]line_num}

info break 

dis {num} - disable breakpoint
ena {num} - enable breakpoint
del {num} - delete breakpoint

## Execution

run - run from start
run args - run with cmd line
r - rerun the program
s - step in
n - step over
u - until the next line (for example, to exit the loop)
c - continue
ret [return_code] - return from the current function
j {line} - jump to a given line

info threads - list the active threads
thread {num} - switch focus to thread {num}

set disassemble-next-line on
show disassemble-next-line

## Code

l [func] - show code lines of func
disassemble - show assembly code

## Stack


bt - show stack

f {num} - select stack frame

up|down - up or down on the stack

## Variables

p {var} - print variable
p {\*arr@10} - print the first 10 elements of the array arr
mem read -tdouble -c10 arr - read a count of 10 items of type double from an array
watch {var} - break if the value of the variable changes

info local - show local variables ????
info args - show all arguments to the function
info vars - show all local variables

disp {var} - display variable on each debugger break (can be called multiple times)
undisp {var} - do not show the variable any longer

## Meta

In GDB, you may create custom variables with `set $t = my_var->t`.

You may use the output variable of the command to reference it:

```
(gdb) p x
$12 = (int) 2
```

The `$` is for the last variable in the output. To print structures we may use GDB functions
