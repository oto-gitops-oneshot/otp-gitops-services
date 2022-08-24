BEGIN{
    FS = "{{"
    if (length(arrayvar)>0) {
        token_count=split(arrayvar,tokens,"[;, ]")
        for(i=1;i<=token_count;i++) {
            kv_count = split(tokens[i],kv,"[=:]")
            if (kv_count>2) {
                printf("Error(jinja_vars): Bad kv with %s while expecting 'key=value' format.\n", tokens[i])
                exit 1
            }
            kv_array[kv[1]]=kv[2]
        }
    }
}
{
    if ($0 ~ /{{ *[a-zA-Z][a-zA-Z0-9_]*[a-zA-Z0-9] }}/)
    {
        for (k in kv_array) {
            sub("{{ *"k" *}}", kv_array[k], $0)
        }
    }
    print
}

