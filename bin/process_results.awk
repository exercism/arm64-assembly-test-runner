#!/bin/awk -f
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
        n = split(line, parts, /RUN_TEST\(/)
        if (n > 1) {
            end = index(parts[n], ")")
            if (end > 1) last_test = substr(parts[n], 1, end - 1)
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
    n = split($0, F, ":")
    test_name = F[3]
    if (F[4] == "PASS") {
        test_status = "pass"
        has_msg = 0
    } else {
        test_status = "fail"
        overall_status = "fail"
        if (n >= 5) {
            # Rejoin trailing fields in case the message contains colons.
            msg = F[5]
            for (i = 6; i <= n; i++) msg = msg ":" F[i]
            # Strip the leading space from ": <msg>".
            if (substr(msg, 1, 1) == " ") msg = substr(msg, 2)
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
