#!/usr/bin/awk -f
#This project implements a complete awk interpreter (lexer, parser, regex engine, field splitter, VM, built ins) written in awk itself. The interpreter structure is emulated from scratch while using awk's built in string, math, and I/O primitives.
#License GPL3 Copyright (C) 2026 Ivan Gaydardzhiev

function kw_init( i) {
	kw["BEGIN"] = 100
	kw["END"] = 101
	kw["if"] = 102
	kw["else"] = 103
	kw["while"] = 104
	kw["for"] = 105
	kw["in"] = 106
	kw["do"] = 107
	kw["next"] = 108
	kw["exit"] = 109
	kw["return"] = 110
	kw["print"] = 111
	kw["printf"] = 112
	kw["getline"] = 113
	kw["delete"] = 114
	kw["function"] = 115
}

function lx_skip(c) {
	while (sp <= slen) {
		c = substr(src, sp, 1)
		if (c == " " || c == "\t" || c == "\r")
			sp++
		else if (c == "#") {
			while (sp <= slen && substr(src, sp, 1) != "\n")
				sp++
		} else
			break
	}
}

function lx_num(s, c) {
	s = ""
	while (sp <= slen) {
		c = substr(src, sp, 1)
		if (c ~ /[0-9]/ || (c == "." && index(s, ".") == 0) ||
		 ((c == "e" || c == "E") && length(s) > 0) ||
		 ((c == "+" || c == "-") && length(s) > 0 &&
		 (substr(s, length(s), 1) == "e" || substr(s, length(s), 1) == "E"))) {
			s = s c
			sp++
		} else
			break
	}
	return s
}

function lx_str(s, c, esc) {
	sp++
	s = ""
	while (sp <= slen) {
		c = substr(src, sp, 1)
		sp++
		if (c == "\\") {
			esc = substr(src, sp, 1)
			sp++
			if (esc == "n") s = s "\n"
			else if (esc == "t") s = s "\t"
			else if (esc == "r") s = s "\r"
			else if (esc == "\\") s = s "\\"
			else if (esc == "\"") s = s "\""
			else if (esc == "/") s = s "/"
			else s = s "\\" esc
		} else if (c == "\"")
			break
		else
			s = s c
	}
	return s
}

function lx_re(s, c) {
	sp++
	s = ""
	while (sp <= slen) {
		c = substr(src, sp, 1)
		sp++
		if (c == "\\") {
			s = s c substr(src, sp, 1)
			sp++
		} else if (c == "/")
			break
		else
			s = s c
	}
	return s
}

function lx_id(s, c) {
	s = ""
	while (sp <= slen) {
		c = substr(src, sp, 1)
		if (c ~ /[a-zA-Z0-9_]/) {
			s = s c
			sp++
		} else
			break
	}
	return s
}

function lx_one(c, c2, t, v) {
	lx_skip()
	if (sp > slen) {
		tok[tc,"t"] = 0
		tok[tc,"v"] = ""
		tc++
		return
	}
	c = substr(src, sp, 1)
	c2 = substr(src, sp+1, 1)
	t = -1
	v = ""
	if (c == "\n") {
		t = 6; v = "\n"; sp++
	} else if (c ~ /[0-9]/ || (c == "." && c2 ~ /[0-9]/)) {
		t = 1; v = lx_num()
	} else if (c == "\"") {
		t = 2; v = lx_str()
	} else if (c ~ /[a-zA-Z_]/) {
		v = lx_id()
		t = (v in kw) ? kw[v] : 4
	} else if (c == "$") {
		t = 238; v = "$"; sp++
	} else if (c == "+" && c2 == "+") { t = 213; v = "++"; sp += 2
	} else if (c == "-" && c2 == "-") { t = 214; v = "--"; sp += 2
	} else if (c == "+" && c2 == "=") { t = 207; v = "+="; sp += 2
	} else if (c == "-" && c2 == "=") { t = 208; v = "-="; sp += 2
	} else if (c == "*" && c2 == "=") { t = 209; v = "*="; sp += 2
	} else if (c == "/" && c2 == "=") { t = 210; v = "/="; sp += 2
	} else if (c == "%" && c2 == "=") { t = 211; v = "%="; sp += 2
	} else if (c == "^" && c2 == "=") { t = 212; v = "^="; sp += 2
	} else if (c == "=" && c2 == "=") { t = 215; v = "=="; sp += 2
	} else if (c == "!" && c2 == "=") { t = 216; v = "!="; sp += 2
	} else if (c == "<" && c2 == "=") { t = 218; v = "<="; sp += 2
	} else if (c == ">" && c2 == "=") { t = 220; v = ">="; sp += 2
	} else if (c == "&" && c2 == "&") { t = 221; v = "&&"; sp += 2
	} else if (c == "|" && c2 == "|") { t = 222; v = "||"; sp += 2
	} else if (c == "!" && c2 == "~") { t = 227; v = "!~"; sp += 2
	} else if (c == ">" && c2 == ">") { t = 229; v = ">>"; sp += 2
	} else if (c == "+") { t = 200; v = "+"; sp++
	} else if (c == "-") { t = 201; v = "-"; sp++
	} else if (c == "*") { t = 202; v = "*"; sp++
	} else if (c == "/") { t = 203; v = "/"; sp++
	} else if (c == "%") { t = 204; v = "%"; sp++
	} else if (c == "^") { t = 205; v = "^"; sp++
	} else if (c == "=") { t = 206; v = "="; sp++
	} else if (c == "<") { t = 217; v = "<"; sp++
	} else if (c == ">") { t = 219; v = ">"; sp++
	} else if (c == "~") { t = 226; v = "~"; sp++
	} else if (c == "!") { t = 223; v = "!"; sp++
	} else if (c == "?") { t = 224; v = "?"; sp++
	} else if (c == ":") { t = 225; v = ":"; sp++
	} else if (c == "|") { t = 228; v = "|"; sp++
	} else if (c == ";") { t = 230; v = ";"; sp++
	} else if (c == ",") { t = 231; v = ","; sp++
	} else if (c == "{") { t = 232; v = "{"; sp++
	} else if (c == "}") { t = 233; v = "}"; sp++
	} else if (c == "(") { t = 234; v = "("; sp++
	} else if (c == ")") { t = 235; v = ")"; sp++
	} else if (c == "[") { t = 236; v = "["; sp++
	} else if (c == "]") { t = 237; v = "]"; sp++
	} else {
		sp++
	}
	tok[tc,"t"] = t
	tok[tc,"v"] = v
	tc++
}

function lx_all(i, prev_t) {
	tc = 0
	sp = 1
	prev_t = 0
	while (sp <= slen) {
		lx_one()
		if (tok[tc-1,"t"] == 203) {
			if (prev_t == 0 || prev_t == 226 || prev_t == 227 ||
			 prev_t == 206 || prev_t == 231 || prev_t == 234 ||
			 prev_t == 232 || prev_t == 230 || prev_t == 6 ||
			 prev_t == 111 || prev_t == 112) {
				sp--
				tok[tc-1,"t"] = 3
				tok[tc-1,"v"] = lx_re()
			}
		}
		prev_t = tok[tc-1,"t"]
	}
	lx_one()
}

function pt() {
	return tok[tp,"t"]
}

function pv() {
	return tok[tp,"v"]
}

function pt2() {
	return tok[tp+1,"t"]
}

function skip_nl() {
	while (pt() == 6) tp++
}

function eat(t) {
	if (pt() != t) {
		printf "parse error: expected %d got %d (%s) at token %d\n", t, pt(), pv(), tp | "cat >&2"
		exit 1
	}
	tp++
}

function eat_semi() {
	while (pt() == 6 || pt() == 230) tp++
}

function emit(op, v, a, i) {
	i = ic
	inst[i,"op"] = op
	inst[i,"v"] = v
	inst[i,"a"] = a
	ic++
	return i
}

function p_program(t, pat, entry) {
	skip_nl()
	while (pt() != 0) {
		t = pt()
		if (t == 115) {
			p_funcdef()
		} else if (t == 100) {
			tp++
			fn["BEGIN"] = ic
			eat(232)
			p_block()
			eat(233)
			emit(34, "", 0)
		} else if (t == 101) {
			tp++
			fn["END"] = ic
			eat(232)
			p_block()
			eat(233)
			emit(34, "", 0)
		} else if (t == 203 || t == 3) {
			pat = pv()
			tp++
			entry = ic
			eat(232)
			p_block()
			emit(34, "", 0)
			eat(233)
			rules[rc,"pat"] = pat
			rules[rc,"type"] = "r"
			rules[rc,"entry"] = entry
			rc++
		} else if (t == 232) {
			eat(232)
			entry = ic
			p_block()
			emit(34, "", 0)
			eat(233)
			rules[rc,"type"] = "u"
			rules[rc,"entry"] = entry
			rc++
		} else {
			p_stmt()
		}
		skip_nl()
	}
}

function p_funcdef(nm, na, i) {
	eat(115)
	nm = pv(); eat(4)
	eat(234)
	na = 0
	fn[nm] = ic
	while (pt() != 235) {
		if (na > 0) eat(231)
		fnp[nm,na] = pv(); eat(4)
		na++
	}
	fna[nm] = na
	eat(235)
	skip_nl()
	eat(232)
	p_block()
	eat(233)
	emit(23, "", 0)
}

function p_block() {
	eat_semi()
	while (pt() != 233 && pt() != 0) {
		p_stmt()
		eat_semi()
	}
}

function p_body() {
	skip_nl()
	if (pt() == 232) {
		eat(232)
		p_block()
		eat(233)
	} else {
		p_stmt()
	}
}

function p_stmt(t, jf, jmp, ji) {
	t = pt()
	if (t == 102) {
		tp++
		eat(234)
		p_expr()
		eat(235)
		jf = emit(21, "", 0)
		p_body()
		if (pt() == 103) {
			tp++
			jmp = emit(20, "", 0)
			inst[jf,"a"] = ic
			p_body()
			inst[jmp,"a"] = ic
		} else {
			inst[jf,"a"] = ic
		}
	} else if (t == 104) {
		tp++
		ji = ic
		eat(234)
		p_expr()
		eat(235)
		jf = emit(21, "", 0)
		p_body()
		emit(20, "", ji)
		inst[jf,"a"] = ic
	} else if (t == 105) {
		tp++
		eat(234)
		if (pt() == 4 && pt2() == 106) {
			kv = pv(); eat(4)
			eat(106)
			av = pv(); eat(4)
			eat(235)
			emit(37, av, kv)
			ji = ic
			emit(38, "", 0)
			jf = emit(21, "", 0)
			emit(39, kv, 0)
			p_body()
			emit(20, "", ji)
			inst[jf,"a"] = ic
			} else {
				if (pt() != 230) p_expr()
				eat_semi()
				ji_cond = ic
				if (pt() != 230) {
					p_expr()
					jf = emit(21, "", 0)
				} else {
					jf = -1
				}
				eat_semi()
				jmp_body = emit(20, "", 0)
				ji_post = ic
				if (pt() != 235) p_expr()
				eat(235)
				emit(20, "", ji_cond)
				inst[jmp_body,"a"] = ic
				p_body()
				emit(20, "", ji_post)
				if (jf >= 0) { inst[jf,"a"] = ic }
			}
	} else if (t == 110) {
		tp++
		if (pt() != 230 && pt() != 6 && pt() != 233)
			p_expr()
		else
			emit(0, "", 0)
		emit(23, "", 0)
		eat_semi()
	} else if (t == 108) {
		tp++
		emit(28, "", 0)
		eat_semi()
	} else if (t == 109) {
		tp++
		if (pt() != 230 && pt() != 6 && pt() != 233)
			p_expr()
		else
			emit(0, "", 0)
		emit(29, "", 0)
		eat_semi()
	} else if (t == 111) {
		p_print()
	} else if (t == 112) {
		p_printf()
	} else if (t == 114) {
		tp++
		p_expr()
		emit(33, "", 0)
		eat_semi()
	} else {
		p_expr()
		eat_semi()
	}
}

function p_print(ac, i) {
	eat(111)
	ac = 0
	if (pt() != 230 && pt() != 6 && pt() != 233 && pt() != 0) {
		p_expr()
		ac++
		while (pt() == 231) {
			tp++
			p_expr()
			ac++
		}
	}
	emit(24, "", ac)
	eat_semi()
}

function p_printf(ac) {
	eat(112)
	ac = 0
	p_expr()
	ac++
	while (pt() == 231) {
		tp++
		p_expr()
		ac++
	}
	emit(25, "", ac)
	eat_semi()
}

function p_expr() {
	p_assign()
}

function p_assign(t, nm, op) {
	p_ternary()
	t = pt()
	if (t == 206) {
		nm = inst[ic-1,"v"]
		ic--
		tp++
		p_expr()
		emit(2, nm, 0)
	} else if (t == 207 || t == 208 || t == 209 || t == 210 || t == 211 || t == 212) {
		nm = inst[ic-1,"v"]
		op = (t == 207 ? 3 : t == 208 ? 4 : t == 209 ? 5 : t == 210 ? 6 : t == 211 ? 7 : 8)
		tp++
		p_expr()
		emit(op, "", 0)
		emit(2, nm, 0)
	}
}

function p_ternary(jf, jmp) {
	p_or()
	if (pt() == 224) {
		tp++
		jf = emit(21, "", 0)
		p_expr()
		eat(225)
		jmp = emit(20, "", 0)
		inst[jf,"a"] = ic
		p_expr()
		inst[jmp,"a"] = ic
	}
}

function p_or(jf, jmp) {
	p_and()
	while (pt() == 222) {
		tp++
		jf = emit(21, "", 0)
		p_and()
		jmp = emit(20, "", 0)
		inst[jf,"a"] = ic
		emit(0, 1, 0)
		inst[jmp,"a"] = ic
	}
}

function p_and(jf, jmp) {
	p_match()
	while (pt() == 221) {
		tp++
		jf = emit(21, "", 0)
		p_match()
		jmp = emit(20, "", 0)
		inst[jf,"a"] = ic
		emit(0, 0, 0)
		inst[jmp,"a"] = ic
	}
}

function p_match() {
	p_cmp()
	if (pt() == 226) {
		tp++
		p_cmp()
		emit(26, "", 0)
	} else if (pt() == 227) {
		tp++
		p_cmp()
		emit(27, "", 0)
	}
}

function p_cmp(t) {
	p_concat()
	t = pt()
	if (t == 215) { tp++; p_concat(); emit(10, "", 0)
	} else if (t == 216) { tp++; p_concat(); emit(11, "", 0)
	} else if (t == 217) { tp++; p_concat(); emit(12, "", 0)
	} else if (t == 218) { tp++; p_concat(); emit(13, "", 0)
	} else if (t == 219) { tp++; p_concat(); emit(14, "", 0)
	} else if (t == 220) { tp++; p_concat(); emit(15, "", 0)
	} else if (t == 106) { tp++; emit(0, pv(), 0); eat(4); emit(32, "", 0)
	}
}

function p_concat() {
	p_add()
	while (pt() == 1 || pt() == 2 || pt() == 4 || pt() == 234) {
		p_add()
		emit(9, "", 0)
	}
}

function p_add(t) {
	p_mul()
	while (1) {
		t = pt()
		if (t == 200) { tp++; p_mul(); emit(3, "", 0)
		} else if (t == 201) { tp++; p_mul(); emit(4, "", 0)
		} else break
	}
}

function p_mul(t) {
	p_unary()
	while (1) {
		t = pt()
		if (t == 202) { tp++; p_unary(); emit(5, "", 0)
		} else if (t == 203) { tp++; p_unary(); emit(6, "", 0)
		} else if (t == 204) { tp++; p_unary(); emit(7, "", 0)
		} else break
	}
}

function p_unary(t) {
	t = pt()
	if (t == 201) { tp++; p_pow(); emit(19, "", 0)
	} else if (t == 223) { tp++; p_pow(); emit(18, "", 0)
	} else p_pow()
}

function p_pow() {
	p_postfix()
	if (pt() == 205) {
		tp++
		p_unary()
		emit(8, "", 0)
	}
}

function p_postfix(nm) {
	p_primary()
	if (pt() == 213) {
		tp++
		nm = inst[ic-1,"v"]
		emit(1, nm, 0)
		emit(0, 1, 0)
		emit(3, "", 0)
		emit(2, nm, 0)
		emit(35, "", 0)
	} else if (pt() == 214) {
		tp++
		nm = inst[ic-1,"v"]
		emit(1, nm, 0)
		emit(0, 1, 0)
		emit(4, "", 0)
		emit(2, nm, 0)
		emit(35, "", 0)
	}
}

function p_primary(t, v, ac, i) {
	t = pt()
	v = pv()
	if (t == 1) {
		tp++
		emit(0, v+0, 0)
	} else if (t == 2) {
		tp++
		emit(0, v, 0)
	} else if (t == 3) {
		tp++
		emit(0, v, 0)
	} else if (t == 4) {
		tp++
		if (pt() == 234) {
			tp++
			ac = 0
			is_builtin = (v == "split" || v == "sprintf" || v == "substr" || \
				v == "index" || v == "length" || v == "tolower" || v == "toupper" || \
				v == "sin" || v == "cos" || v == "atan2" || v == "log" || \
				v == "exp" || v == "sqrt" || v == "int" || v == "rand" || v == "srand")
			while (pt() != 235) {
				if (ac > 0) eat(231)
				if (v == "split" && ac == 1) {
					emit(0, pv(), 0); eat(4)
				} else if (!is_builtin && pt() == 4 && (tok[tp+1,"t"] == 231 || tok[tp+1,"t"] == 235)) {
					emit(0, "\x01" pv(), 0)
					eat(4)
				} else {
					p_expr()
				}
				ac++
			}
			eat(235)
			emit(22, v, ac)
		} else if (pt() == 236) {
			tp++
			p_expr()
			eat(237)
			if (pt() == 206) {
				tp++
				p_expr()
				emit(36, v, 0)
			} else {
				emit(1, v, 1)
			}
		} else {
			emit(1, v, 0)
		}
	} else if (t == 238) {
		tp++
		p_primary()
		emit(30, "", 0)
	} else if (t == 234) {
		tp++
		p_expr()
		eat(235)
	} else if (t == 213) {
		tp++
		v = pv(); eat(4)
		emit(1, v, 0)
		emit(0, 1, 0)
		emit(3, "", 0)
		emit(2, v, 0)
	} else if (t == 214) {
		tp++
		v = pv(); eat(4)
		emit(1, v, 0)
		emit(0, 1, 0)
		emit(4, "", 0)
		emit(2, v, 0)
	} else {
		printf "parse error: unexpected token %d (%s)\n", t, v | "cat >&2"
		exit 1
	}
}

function re_compile(pat, nc) {
	nc = 0
	re_pos = 1
	re_pat = pat
	re_len = length(pat)
	return re_alt(nc)
}

function re_alt(nc, left, right, s) {
	left = re_seq(nc)
	if (re_pos <= re_len && substr(re_pat, re_pos, 1) == "|") {
		re_pos++
		right = re_alt(nc)
		s = nc++
		nfa[s,"op"] = 2
		nfa[s,"o1"] = left
		nfa[s,"o2"] = right
		return s
	}
	return left
}

function re_seq(nc, h, t, n) {
	h = re_quant(nc)
	t = h
	while (re_pos <= re_len) {
		c = substr(re_pat, re_pos, 1)
		if (c == ")" || c == "|")
			break
		n = re_quant(nc)
		nfa[t,"next"] = n
		t = n
	}
	return h
}

function re_quant(nc, n, s, q) {
	n = re_atom(nc)
	if (re_pos > re_len)
		return n
	q = substr(re_pat, re_pos, 1)
	if (q == "*" || q == "+" || q == "?") {
		re_pos++
		s = nc++
		nfa[s,"op"] = 2
		nfa[s,"o1"] = n
		nfa[s,"o2"] = -1
		return s
	}
	return n
}

function re_atom(nc, c, s) {
	if (re_pos > re_len)
		return -1
	c = substr(re_pat, re_pos, 1)
	re_pos++
	if (c == "(") {
		s = re_alt(nc)
		re_pos++
		return s
	} else if (c == ".") {
		s = nc++
		nfa[s,"op"] = 1
		return s
	} else if (c == "[") {
		return re_class(nc)
	} else if (c == "\\") {
		c = substr(re_pat, re_pos, 1)
		re_pos++
		s = nc++
		nfa[s,"op"] = 0
		nfa[s,"c"] = c
		return s
	} else {
		s = nc++
		nfa[s,"op"] = 0
		nfa[s,"c"] = c
		return s
	}
}

function re_class(nc, s, cls, c) {
	s = nc++
	cls = ""
	if (re_pos <= re_len && substr(re_pat, re_pos, 1) == "^") {
		nfa[s,"neg"] = 1
		re_pos++
	}
	while (re_pos <= re_len) {
		c = substr(re_pat, re_pos, 1)
		re_pos++
		if (c == "]") break
		cls = cls c
	}
	nfa[s,"op"] = 4
	nfa[s,"cls"] = cls
	return s
}

function re_match(str, start, nfa_start, pos, c, st) {
	pos = start
	st = nfa_start
	while (st != -1 && pos <= length(str)) {
		c = substr(str, pos, 1)
		if (nfa[st,"op"] == 0) {
			if (c != nfa[st,"c"]) return -1
			pos++
			st = nfa[st,"next"]
		} else if (nfa[st,"op"] == 1) {
			pos++
			st = nfa[st,"next"]
		} else if (nfa[st,"op"] == 3) {
			return pos - start
		} else {
			return -1
		}
	}
	return pos - start
}

function fs_split(rec, fs, n, i, p, m, f) {
	delete fields
	nf = 0
	if (fs == " ") {
		n = split(rec, f)
		for (i = 1; i <= n; i++) fields[i] = f[i]
		nf = n
	} else {
		p = 1
		while (p <= length(rec)) {
			m = index(substr(rec, p), fs)
			if (m == 0) {
				fields[++nf] = substr(rec, p)
				break
			} else {
				fields[++nf] = substr(rec, p, m - 1)
				p += m + length(fs) - 1
			}
		}
	}
	fields[0] = rec
}

function vm_push(v) {
	stk[++sv] = v
}

function vm_pop() {
	return stk[sv--]
}

function vm_run(entry, i, op, v, a, r, l, b, ac, j, nm, k) {
	i = entry
	while (1) {
		op = inst[i,"op"]
		v = inst[i,"v"]
		a = inst[i,"a"]
		if (op == 0) {
			vm_push(v)
			i++
		} else if (op == 1) {
			if (a == 1) {
				k = vm_pop()
				nm = (alias[v] != "" ? alias[v] : v)
				vm_push(arr[nm, k])
			} else
				vm_push(var[v])
			i++
		} else if (op == 2) {
			r = vm_pop()
			var[v] = r
			vm_push(r)
			i++
		} else if (op == 36) {
			r = vm_pop(); k = vm_pop()
			nm = (alias[v] != "" ? alias[v] : v)
			arr[nm,k] = r
			vm_push(r)
			i++
		} else if (op == 3) {
			r = vm_pop(); l = vm_pop(); vm_push(l + r); i++
		} else if (op == 4) {
			r = vm_pop(); l = vm_pop(); vm_push(l - r); i++
		} else if (op == 5) {
			r = vm_pop(); l = vm_pop(); vm_push(l * r); i++
		} else if (op == 6) {
			r = vm_pop(); l = vm_pop(); vm_push(l / r); i++
		} else if (op == 7) {
			r = vm_pop(); l = vm_pop(); vm_push(l % r); i++
		} else if (op == 8) {
			r = vm_pop(); l = vm_pop(); vm_push(l ^ r); i++
		} else if (op == 9) {
			r = vm_pop(); l = vm_pop(); vm_push(l r); i++
		} else if (op == 10) {
			r = vm_pop(); l = vm_pop(); vm_push(l == r ? 1 : 0); i++
		} else if (op == 11) {
			r = vm_pop(); l = vm_pop(); vm_push(l != r ? 1 : 0); i++
		} else if (op == 12) {
			r = vm_pop(); l = vm_pop(); vm_push(l < r ? 1 : 0); i++
		} else if (op == 13) {
			r = vm_pop(); l = vm_pop(); vm_push(l <= r ? 1 : 0); i++
		} else if (op == 14) {
			r = vm_pop(); l = vm_pop(); vm_push(l > r ? 1 : 0); i++
		} else if (op == 15) {
			r = vm_pop(); l = vm_pop(); vm_push(l >= r ? 1 : 0); i++
		} else if (op == 16) {
			r = vm_pop(); l = vm_pop(); vm_push((l && r) ? 1 : 0); i++
		} else if (op == 17) {
			r = vm_pop(); l = vm_pop(); vm_push((l || r) ? 1 : 0); i++
		} else if (op == 18) {
			l = vm_pop(); vm_push(!l ? 1 : 0); i++
		} else if (op == 19) {
			l = vm_pop(); vm_push(-l); i++
		} else if (op == 20) {
			i = a
		} else if (op == 21) {
			b = vm_pop()
			if (!b) i = a; else i++
		} else if (op == 22) {
			nm = v
			ac = a
			vm_run_call(nm, ac)
			i++
		} else if (op == 23) {
			ret = vm_pop()
			return
		} else if (op == 24) {
			ac = a
			if (ac == 0) {
				print fields[0]
			} else {
				r = ""
				for (j = ac; j >= 1; j--) {
					if (j < ac) r = OFS r
					r = vm_pop() r
				}
				print r
			}
			i++
		} else if (op == 25) {
			ac = a
			for (j = ac; j >= 1; j--) pfarg[j] = vm_pop()
			if (ac == 1) printf pfarg[1]
			else if (ac == 2) printf pfarg[1], pfarg[2]
			else if (ac == 3) printf pfarg[1], pfarg[2], pfarg[3]
			else if (ac == 4) printf pfarg[1], pfarg[2], pfarg[3], pfarg[4]
			else if (ac == 5) printf pfarg[1], pfarg[2], pfarg[3], pfarg[4], pfarg[5]
			else if (ac == 6) printf pfarg[1], pfarg[2], pfarg[3], pfarg[4], pfarg[5], pfarg[6]
			else if (ac == 7) printf pfarg[1], pfarg[2], pfarg[3], pfarg[4], pfarg[5], pfarg[6], pfarg[7]
			else if (ac == 8) printf pfarg[1], pfarg[2], pfarg[3], pfarg[4], pfarg[5], pfarg[6], pfarg[7], pfarg[8]
			i++
		} else if (op == 26) {
			r = vm_pop(); l = vm_pop()
			vm_push((l ~ r) ? 1 : 0); i++
		} else if (op == 27) {
			r = vm_pop(); l = vm_pop()
			vm_push((l !~ r) ? 1 : 0); i++
		} else if (op == 28) {
			vm_next = 1
			return
		} else if (op == 29) {
			r = vm_pop(); exit r
		} else if (op == 30) {
			j = vm_pop()
			vm_push(fields[j])
			i++
		} else if (op == 31) {
			r = vm_pop(); j = vm_pop()
			fields[j] = r
			i++
		} else if (op == 32) {
			nm = vm_pop(); k = vm_pop()
			nm = (alias[nm] != "" ? alias[nm] : nm)
			vm_push((nm SUBSEP k) in arr ? 1 : 0)
			i++
		} else if (op == 33) {
			nm = vm_pop()
			delete arr[nm]
			i++
		} else if (op == 34) {
			return
		} else if (op == 35) {
			sv--
			i++
		} else if (op == 37) {
			forin_depth++
			fd = forin_depth
			forin_cnt[fd] = 0
			nm = (alias[v] != "" ? alias[v] : v)
			forin_arr[fd] = nm
			forin_var[fd] = a
			pfx = nm SUBSEP
			plen = length(pfx)
			for (fk in arr) {
				if (substr(fk, 1, plen) == pfx) {
					forin_keys[fd, forin_cnt[fd]] = substr(fk, plen + 1)
					forin_cnt[fd]++
				}
			}
			forin_idx[fd] = 0
			i++
		} else if (op == 38) {
			fd = forin_depth
			if (forin_idx[fd] < forin_cnt[fd]) {
				vm_push(1)
			} else {
				vm_push(0)
				forin_depth--
			}
			i++
		} else if (op == 39) {
			fd = forin_depth
			var[v] = forin_keys[fd, forin_idx[fd]]
			forin_idx[fd]++
			i++
		} else {
			printf "vm: unknown opcode %d\n", op | "cat >&2"
			exit 1
		}
	}
}

function vm_run_call(nm, ac, j, save_sv, args, k, cd, local_ret, save_ret) {
	if (nm == "length") {
		if (ac == 0) vm_push(length(fields[0]))
		else { l = vm_pop(); vm_push(length(l)) }
		return
	} else if (nm == "substr") {
		if (ac == 2) { l = vm_pop(); r = vm_pop(); vm_push(substr(r, l)) }
		else { b = vm_pop(); l = vm_pop(); r = vm_pop(); vm_push(substr(r, l, b)) }
		return
	} else if (nm == "index") {
		r = vm_pop(); l = vm_pop(); vm_push(index(l, r)); return
	} else if (nm == "split") {
		r = vm_pop(); l = vm_pop()
		if (substr(r, 1, 1) == "\x01") r = substr(r, 2)
		delete sptmp
		n = split(l, sptmp, " ")
		for (j = 1; j <= n; j++) arr[r, j] = sptmp[j]
		vm_push(n); return
	} else if (nm == "sprintf") {
		for (j = ac; j >= 1; j--) sparg[j] = vm_pop()
		if (ac == 1) r = sprintf(sparg[1])
		else if (ac == 2) r = sprintf(sparg[1], sparg[2])
		else if (ac == 3) r = sprintf(sparg[1], sparg[2], sparg[3])
		else if (ac == 4) r = sprintf(sparg[1], sparg[2], sparg[3], sparg[4])
		else if (ac == 5) r = sprintf(sparg[1], sparg[2], sparg[3], sparg[4], sparg[5])
		else if (ac == 6) r = sprintf(sparg[1], sparg[2], sparg[3], sparg[4], sparg[5], sparg[6])
		else if (ac == 7) r = sprintf(sparg[1], sparg[2], sparg[3], sparg[4], sparg[5], sparg[6], sparg[7])
		else if (ac == 8) r = sprintf(sparg[1], sparg[2], sparg[3], sparg[4], sparg[5], sparg[6], sparg[7], sparg[8])
		vm_push(r); return
	} else if (nm == "sin") { vm_push(sin(vm_pop())); return
	} else if (nm == "cos") { vm_push(cos(vm_pop())); return
	} else if (nm == "exp") { vm_push(exp(vm_pop())); return
	} else if (nm == "log") { vm_push(log(vm_pop())); return
	} else if (nm == "sqrt") { vm_push(sqrt(vm_pop())); return
	} else if (nm == "int") { vm_push(int(vm_pop())); return
	} else if (nm == "rand") { vm_push(rand()); return
	} else if (nm == "srand"){ srand(vm_pop()); return
	} else if (nm == "atan2"){ r = vm_pop(); l = vm_pop(); vm_push(atan2(l,r)); return
	} else if (nm == "tolower") { vm_push(tolower(vm_pop())); return
	} else if (nm == "toupper") { vm_push(toupper(vm_pop())); return
	}
	if (!(nm in fn)) {
		printf "vm: undefined function %s\n", nm | "cat >&2"
		exit 1
	}
	save_sv = sv
	save_ret = ret
	call_depth++
	cd = call_depth
	for (j = 0; j < ac; j++) args[j] = stk[sv - ac + 1 + j]
	sv -= ac
	for (j = 0; j < fna[nm]; j++) {
		pnm = fnp[nm,j]
		save_var[cd,j] = var[pnm]
		save_alias[cd,j] = alias[pnm]
		if (j < ac && substr(args[j], 1, 1) == "\x01") {
			caller_nm = substr(args[j], 2)
			alias[pnm] = caller_nm
			var[pnm] = var[caller_nm]
		} else {
			alias[pnm] = ""
			var[pnm] = (j < ac ? args[j] : "")
		}
	}
	vm_run(fn[nm])
	local_ret = ret
	for (j = 0; j < fna[nm]; j++) {
		pnm = fnp[nm,j]
		var[pnm] = save_var[cd,j]
		alias[pnm] = save_alias[cd,j]
	}
	call_depth--
	ret = save_ret
	sv = save_sv - ac
	vm_push(local_ret)
}

BEGIN {
	kw_init()
	src = ""
	slen = 0
	tc = 0
	tp = 0
	ic = 0
	sv = 0
	rc = 0
}

{
	src = src $0 "\n"
}

END {
	slen = length(src)
	lx_all()
	tp = 0
	p_program()
	if ("BEGIN" in fn) vm_run(fn["BEGIN"])
	if (rc > 0) {
		nr = 0
		if (ARGC > 2) {
			for (ai = 2; ai < ARGC; ai++) {
				fn_input = ARGV[ai]
				while ((getline rec < fn_input) > 0) {
					nr++
					var["NR"] = nr
					var["FNR"] = nr - (ai - 2) * nr
					fs_split(rec, " ")
					var["NF"] = nf
					for (fi = 0; fi <= nf; fi++) var["$" fi] = fields[fi]
					for (ri = 0; ri < rc; ri++) {
						vm_next = 0
						if (rules[ri,"type"] == "u") {
							vm_run(rules[ri,"entry"])
						} else if (rules[ri,"type"] == "r") {
							if (rec ~ rules[ri,"pat"])
								vm_run(rules[ri,"entry"])
						}
						if (vm_next) break
					}
				}
				close(fn_input)
			}
		} else {
			while ((getline rec < "/dev/stdin") > 0) {
				nr++
				var["NR"] = nr
				var["FNR"] = nr
				fs_split(rec, " ")
				var["NF"] = nf
				for (fi = 0; fi <= nf; fi++) var["$" fi] = fields[fi]
				for (ri = 0; ri < rc; ri++) {
					vm_next = 0
					if (rules[ri,"type"] == "u") {
						vm_run(rules[ri,"entry"])
					} else if (rules[ri,"type"] == "r") {
						if (rec ~ rules[ri,"pat"])
							vm_run(rules[ri,"entry"])
					}
					if (vm_next) break
				}
			}
		}
	}
	if ("END" in fn) vm_run(fn["END"])
}
