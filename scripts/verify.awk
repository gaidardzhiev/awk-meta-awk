function assert(label, got, want,    ok) {
	ok = (got == want)
	if (ok) {
		print "PASS " label
	} else {
		print "FAIL " label ": got=" got " want=" want
	}
}

function double(x) {
	return x * 2
}

function fib(n) {
	if (n <= 1) return n
	return fib(n - 1) + fib(n - 2)
}

BEGIN {
	assert("add",        2 + 3,        5)
	assert("sub",        10 - 4,       6)
	assert("mul",        3 * 7,        21)
	assert("div",        9 / 2,        4.5)
	assert("mod",        10 % 3,       1)
	assert("pow",        2 ^ 8,        256)
	assert("concat",     "foo" "bar",  "foobar")
	assert("lt-true",    1 < 2,        1)
	assert("lt-false",   2 < 1,        0)
	assert("eq-num",     42 == 42,     1)
	assert("eq-str",     "x" == "x",   1)
	assert("ne",         1 != 2,       1)
	if (1) { r_if = "yes" } else { r_if = "no" }
	assert("if-true",    r_if,         "yes")
	if (0) { r_else = "yes" } else { r_else = "no" }
	assert("if-false",   r_else,       "no")
	i = 0; s = 0
	while (i < 5) { s = s + i; i++ }
	assert("while",      s,            10)
	s = 0
	for (i = 1; i <= 4; i++) s = s + i
	assert("for",        s,            10)
	assert("userfunc",   double(9),    18)
	assert("fib-7",      fib(7),       13)
	assert("substr",     substr("hello", 2, 3), "ell")
	assert("index",      index("foobar", "bar"), 4)
	assert("length",     length("test"), 4)
	assert("tolower",    tolower("AWK"), "awk")
	assert("toupper",    toupper("awk"), "AWK")
	assert("ternary-lhs", (1 ? "a" : "b"), "a")
	a[1] = "x"; a[2] = "y"
	assert("array-set",  a[1],         "x")
	assert("array-set2", a[2],         "y")
	assert("in-true",    (1 in a),     1)
	assert("in-false",   (9 in a),     0)
	x = 5; x++
	assert("postinc",    x,            6)
	x--
	assert("postdec",    x,            5)
	assert("unary-neg",  -3,           -3)
	assert("regex-match",    ("hello" ~ /ell/),  1)
	assert("regex-nomatch",  ("hello" !~ /xyz/), 1)
	assert("sprintf", sprintf("%d+%d=%d", 1, 2, 3), "1+2=3")

	input[1] = "pass alpha"
	input[2] = "pass beta"
	input[3] = "fail gamma"
	input[4] = "fail delta"
	for (li = 1; li <= 4; li++) {
		line = input[li]
		if (line ~ /^pass/) {
			nr_pass++
			n = split(line, f)
			pass_last = f[2]
		}
		if (line ~ /^fail/) {
			nr_fail++
		}
	}
	assert("rule-pass-count", nr_pass,   2)
	assert("rule-fail-count", nr_fail,   2)
	assert("pass-field2",     pass_last, "beta")
}
