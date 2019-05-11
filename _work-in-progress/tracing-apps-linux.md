
strace

Dump information about a file: `file <executable>`

Shared symbols in the executable: `objdump -T <executable>`. Shared symbols are those that a given binary imports from other libraries (imports). To list private symbols use `objdump -t <executable>`. FIXME: explain output
