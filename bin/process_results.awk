function jesc(s) {
    gsub(/\\/, "\\\\", s)
    gsub(/"/,  "\\\"", s)
    gsub(/\b/, "\\b", s)
    gsub(/\f/, "\\f", s)
    gsub(/\n/, "\\n", s)
    gsub(/\r/, "\\r", s)
    gsub(/\t/, "\\t", s)
    return s
}
function truncate(s,    notice) {
    notice = "\nOutput was truncated. Please limit to 500 chars."
    if (length(s) > 500) {
        s = substr(s, 1, 500 - length(notice)) notice
    }
    return s
}
BEGIN {
    last_test = ""
    while ((getline line < test_src) > 0) {
        while (match(line, /RUN_TEST\([A-Za-z_][A-Za-z0-9_]*\)/)) {
            last_test = substr(line, RSTART + 9, RLENGTH - 10)
            line = substr(line, RSTART + RLENGTH)
        }
    }
    close(test_src)

    overall_status = "pass"
    n_tests = 0
    output_buf = ""
    completed = 0
}
completed { next }
/^[^:]+_test\.c:[0-9]+:[A-Za-z_][A-Za-z0-9_]*:(PASS|FAIL)(:.*)?$/ {
    line = $0
    p1 = index(line, ":")
    rest = substr(line, p1 + 1)
    p2 = index(rest, ":")
    rest2 = substr(rest, p2 + 1)
    p3 = index(rest2, ":")
    test_name = substr(rest2, 1, p3 - 1)
    rest3 = substr(rest2, p3 + 1)
    if (substr(rest3, 1, 4) == "PASS") {
        test_status = "pass"
        has_msg = 0
    } else {
        test_status = "fail"
        overall_status = "fail"
        tail = substr(rest3, 5)
        if (substr(tail, 1, 2) == ": ") {
            msg = substr(tail, 3)
            has_msg = 1
        } else {
            has_msg = 0
        }
    }
    n_tests++
    names[n_tests] = test_name
    statuses[n_tests] = test_status
    has_msgs[n_tests] = has_msg
    if (has_msg) msgs[n_tests] = msg
    if (output_buf != "") {
        has_outs[n_tests] = 1
        outputs[n_tests] = truncate(output_buf)
    } else {
        has_outs[n_tests] = 0
    }
    output_buf = ""
    if (test_name == last_test) completed = 1
    next
}
{ output_buf = output_buf $0 "\n" }
END {
    if (!completed) {
        printf "{\"version\":2,\"status\":\"error\",\"message\":\"%s\",\"tests\":[]}\n", jesc(output_buf)
    } else {
        printf "{\"version\":2,\"status\":\"%s\",\"message\":null,\"tests\":[", overall_status
        for (i = 1; i <= n_tests; i++) {
            if (i > 1) printf ","
            printf "{\"name\":\"%s\",\"status\":\"%s\"", jesc(names[i]), statuses[i]
            if (has_msgs[i]) printf ",\"message\":\"%s\"", jesc(msgs[i])
            if (has_outs[i]) printf ",\"output\":\"%s\"", jesc(outputs[i])
            printf "}"
        }
        printf "]}\n"
    }
}
