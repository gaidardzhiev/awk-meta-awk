BEGIN {
	print 100,011,10101
	print "\n"
	print "Hello World from the AWK meta AWK interpreter!"
	if (1) {
		print "if works"
	}
	if (0) {
		print "should not print"
	} else {
		print "else works"
	}
	print "double(8) = " double(8)
	print length("awkmetaawk")
	print sqrt(16)
	print sin(15)
	print substr("hello", 2, 2)
	print substr("awkmetaawk", 4, 4)
	print substr("metaawk", 1, length("meta"))
	print length("awkmetaawk") - length("awk")
	print substr("awkmetaawk", 4, length("meta"))
	print "AWK meta AWK: " substr("awkmetaawk", 4, 4) " interpreter"
	print substr("interpreter", 1, 4) " in " substr("meta", 1, 2) " awk"
	print substr("awkmetaawk", 4, 4) " is cool"
	print substr("awkmetaawk", 4, 4)
	print "Reclaim meta!\nawk-meta.awk is meta in the pure sense, a self implemented interpreter, authentically self referential, meaningfully embodying its own definition.\nThe opposite of hollow corporate appropriation..."
}

function double(x) {
	return x * 2
}

END {
	print "END works"
}
