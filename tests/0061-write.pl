main :-
	write(123), nl,
	write([]), nl,
	write('abc def'), nl,
	write([1,2]), nl,
	write([1,2|3]), nl,
	write((foo(X, Y) :- bar, !, baz(X))), nl,
	write((1 + 2) / 3), nl,
	write(1 - -2), nl,
	writeq(123), nl,
	writeq([]), nl,
	writeq('abc def'), nl,
	writeq([1,2]), nl,
	writeq([1,2|3]), nl,
	writeq((foo(X, Y) :- bar, !, baz(X))), nl,
	writeq((1 + 2) / 3), nl,
	writeq(1 - -2), nl.
