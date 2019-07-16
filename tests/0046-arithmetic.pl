main :-
	3 + 4 =:= 7, ok('i+'),
	X1 is 3 + 4.0, f(X1, 7), ok('f+'),
	257 /\ 1 =:= 1, ok('/\\'),
	\3 =:= -4, ok('\\'),
	8 >> 1 =:= 4, ok('>>'),
	8 << 1 =:= 16, ok('<<'),
	256 \/ 1 =:= 257, ok('\\/'),
	257 xor 1 =:= 256, ok('xor'),
	4 ** 2 =:= 16, ok('i**'),
	X2 is 4.0 ** 2, f(X2, 16), ok('f**'),
	X3 is 14 / 7, f(X3, 2), ok('/'),
	55 - 2 =:= 53, ok('i-'),
	X4 is 55.0 - -12, f(X4, 67), ok('f-'),
	-(3) =:= -3, ok('u-'),
	9 // 4 =:= 2, ok('//'),
	3 * 2 =:= 6, ok('i*'),
	X5 is 6.2 * 2, f(X5, 12.4), ok('f*'),
	8 rem 3 =:= 2, ok('rem'),
	abs(-3) =:= 3, X6 is abs(9.0), f(X6, 9), ok('abs'),
	X7 is atan(0.5), f(X7, 0.463647609000806), ok('atan'),
	ceiling(3.6) =:= 4, ceiling(-3.2) =:= -3, ok('ceiling'),
	X8 is cos(0.5), f(X8, 0.877582561890373), ok('cos'),
	X9 is exp(0.5), f(X9, 1.64872127070013), ok('exp'),
	X10 is float(5), f(X10, 5), ok('float'),
	X11 is float_fractional_part(66.2), f(X11, 0.2), ok('frac'),
	X12 is float_integer_part(66.2), f(X12, 66), ok('int'),
	floor(3.2) =:= 3, floor(-3.2) =:= -4, ok('floor'),
	X13 is log(0.5), Y is -0.69314718055994, f(X13, Y), ok('log'),
	round(3.2) =:= 3, round(-3.6) =:= -4, ok('round'),
	sign(-3.2) =:= -1, sign(5) =:= 1, sign(0) =:= 0, ok('sign'),
	X14 is sin(0.5), f(X14, 0.479425538604203), ok('sin'),
	X15 is sqrt(4.0), f(X15, 2), ok('sqrt'),
	truncate(3.2) =:= 3, truncate(-4.9) =:= -4, ok('truncate').

ok(OP) :- display(OP), nl.
f(X, Y) :- abs(X - Y) < 0000000.1.