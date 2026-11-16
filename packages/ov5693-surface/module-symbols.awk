# Arguments: exact System.map, stock dependency names, modules.symbols, imports.
FILENAME == ARGV[1] {
    if ($3 ~ /^__ksymtab_/)
        builtin[substr($3, 11)] = 1
    next
}
FILENAME == ARGV[2] {
    dependencies[$1] = $2
    next
}
FILENAME == ARGV[3] {
    if ($1 == "alias" && $2 ~ /^symbol:/ && $3 in dependencies)
        providers[substr($2, 8)] = dependencies[$3]
    next
}
{
    symbol = $1
    if (symbol in builtin)
        provider = "vmlinux"
    else if (symbol in providers)
        provider = providers[symbol]
    else {
        print "No verified kernel export/provider for " symbol > "/dev/stderr"
        exit 1
    }
    printf "0x00000000\t%s\t%s\tEXPORT_SYMBOL_GPL\t\n", symbol, provider
}
