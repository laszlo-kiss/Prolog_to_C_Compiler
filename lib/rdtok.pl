%   File   : RDTOK.PL
%   Author : R.A.O'Keefe
%   Updated: 2 July 1984
%   Purpose: Tokeniser in reasonably standard Prolog.

/*  This tokeniser is meant to complement the library READs routine.
    It recognises Dec-10 Prolog with the following exceptions:

	%( is not accepted as an alternative to {

	%) is not accepted as an alternative to )

	NOLC convention is not supported (read_name could be made to do it)

	,.. is not accepted as an alternative to | (hooray!)

	large integers are not read in as xwd(Top18Bits,Bottom18Bits)

	After a comma, "(" is read as ' (' rather than '('.  This does the
	parser no harm at all, and the Dec-10 tokeniser's behaviour here
	doesn't actually buy you anything.  This tokeniser guarantees never
	to return '(' except immediately after an atom, yielding ' (' every
	other where.

    In particular, radix notation is EXACTLY as in Dec-10 Prolog version 3.53.
    Some times might be of interest.  Applied to an earlier version of this file:
	this code took			1.66 seconds
	the Dec-10 tokeniser took	1.28 seconds
	A Pascal version took		0.96 seconds
    The Dec-10 tokeniser was called via the old RDTOK interface, with
    which this file is compatible.  One reason for the difference in
    speed is the way variables are looked up: this code uses a linear
    list, while the Dec-10 tokeniser uses some sort of tree.  The Pascal
    version is the program WLIST which lists "words" and their frequencies.
    It uses a hash table.  Another difference is the way characters are
    classified: the Dec-10 tokeniser and WLIST have a table which maps
    ASCII codes to character classes, and don't do all this comparison
    and memberchking.  We could do that without leaving standard Prolog,
    but what do you want from one evening's work?
*/    


:- mode read_tokens(+, -, -),
	read_after_atom(+, -, -),
	'$rdtok_read_string'(+, -, +, -),
	'$rdtok_escape'(+, -),
	'$rdtok_hex_digit'(+, -),
	read_solidus(+, -, -),
	read_solidus(+, -),
	read_fullstop(+, -, -).

:- determinate '$rdtok_hex_digit'/2,
	read_integer/3,
	read_lookup/2.

	
%   read_tokens(TokenList, Dictionary)
%   returns a list of tokens.  It is needed to "prime" read_tokens/2
%   with the initial blank, and to check for end of file.  The
%   Dictionary is a list of AtomName=Variable pairs in no particular order.
%   The way end of file is handled is that everything else FAILS when it
%   hits character "-1", sometimes printing a warning.  It might have been
%   an idea to return the atom 'end_of_file' instead of the same token list
%   that you'd have got from reading "end_of_file. ", but (1) this file is
%   for compatibility, and (b) there are good practical reasons for wanting
%   this behaviour.


read_tokens(TokenList, Dictionary) :-
	read_tokens(32, Dict, ListOfTokens),
	append(Dict, [], Dict), !, %  fill in the "hole" at the end
	Dictionary = Dict,		%  unify explicitly so we'll read and
	TokenList = ListOfTokens.	%  then check even with filled in arguments
read_tokens([atom(end_of_file)], []). %  End Of File is all that can go wrong



read_tokens(-1, _X, _Y) :- !,	%  -1 is the end-of-file character
	fail.			%  in every standard Prolog
read_tokens(Ch, Dict, Tokens) :-
	Ch =< 32,			%  ignore layout.  CR, LF, and the
	!,				%  ASCII newline character (10)
	get0(NextCh),			%  are all skipped here.
	read_tokens(NextCh, Dict, Tokens).
read_tokens(37, Dict, Tokens) :- !,	%  %comment
	repeat,				%  skip characters to a line
	    get0(Ch),			%  terminator (should we be
	    ( Ch = 10 ; Ch = 13; Ch = -1 ),	%  more thorough, e.g. ^L?)
	!,				%  stop when we find one
	Ch =\= -1,			%  fail on EOF
	get0(NextCh),
	read_tokens(NextCh, Dict, Tokens).
read_tokens(47, Dict, Tokens) :- !, %  /* ... */ comment?
	get0(NextCh),
	read_solidus(NextCh, Dict, Tokens).
read_tokens(33, Dict, [atom(!)|Tokens]) :- !,	%  This is a special case so
	get0(NextCh),			%  that !. reads as two tokens.
	read_after_atom(NextCh, Dict, Tokens).	%  It could be cleverer.
read_tokens(40, Dict, [' ('|Tokens]) :- !,	%  NB!!!
	get0(NextCh),
	read_tokens(NextCh, Dict, Tokens).
read_tokens(41, Dict, [')'|Tokens]) :- !,
	get0(NextCh),
	read_tokens(NextCh, Dict, Tokens).
read_tokens(44, Dict, [','|Tokens]) :- !,
	get0(NextCh),
	read_tokens(NextCh, Dict, Tokens).
read_tokens(59, Dict, [atom((;))|Tokens]) :- !,	% ; is nearly a punctuation
	get0(NextCh),				%  mark but not quite (e.g.
	read_tokens(NextCh, Dict, Tokens).	%  you can :-op declare it).
read_tokens(91, Dict, ['['|Tokens]) :- !,
	get0(NextCh),
	read_tokens(NextCh, Dict, Tokens).
read_tokens(93, Dict, [']'|Tokens]) :- !,
	get0(NextCh),
	read_tokens(NextCh, Dict, Tokens).
read_tokens(123, Dict, ['{'|Tokens]) :- !,
	get0(NextCh),
	read_tokens(NextCh, Dict, Tokens).
read_tokens(124, Dict, ['|'|Tokens]) :- !,
	get0(NextCh),
	read_tokens(NextCh, Dict, Tokens).
read_tokens(125, Dict, ['}'|Tokens]) :- !,
	get0(NextCh),
	read_tokens(NextCh, Dict, Tokens).
read_tokens(46, Dict, Tokens) :- !,		% full stop
	get0(NextCh),				% or possibly .=. &c
	read_fullstop(NextCh, Dict, Tokens).
read_tokens(34, Dict, [string(S)|Tokens]) :- !,	% "string"
	'$rdtok_read_string'(S, 34, NextCh),
	read_tokens(NextCh, Dict, Tokens).
read_tokens(39, Dict, [atom(A)|Tokens]) :- !,	% 'atom'
	'$rdtok_read_string'(S, 39, NextCh),
	%% BUG: '0' = 0 unlike Dec-10 Prolog (FLW: fixed by replacing "name" with "atom_codes")
	atom_codes(A, S),
	read_after_atom(NextCh, Dict, Tokens).
read_tokens(Ch, Dict, [var(Var,Name)|Tokens]) :-
	(  Ch = 95 ; Ch >= 65, Ch =< 90  ),	% _ or A..Z
	!,					% have to watch out for "_"
	read_name(Ch, S, NextCh),
	(  S = "_", Name = '_'			% anonymous variable
	;  name(Name, S),			% construct name
	   read_lookup(Dict, Name=Var)		% lookup/enter in dictionary
	), !,
	read_tokens(NextCh, Dict, Tokens).
read_tokens(Ch, Dict, Tokens) :-
	Ch >= 48, Ch =< 57,
	!,
	read_integer(Ch, IntVal, NextCh),
	read_number(IntVal, NextCh, Dict, Tokens).	   
read_tokens(Ch, Dict, [atom(A)|Tokens]) :-
	Ch >= 97, Ch =< 122,			% a..z
	!,					% no corresponding _ problem
	read_name(Ch, S, NextCh),
	name(A, S),
	read_after_atom(NextCh, Dict, Tokens).
read_tokens(Ch, Dict, [atom(A)|Tokens]) :-	% THIS MUST BE THE LAST CLAUSE
	get0(AnotherCh),
	read_symbol(AnotherCh, Chars, NextCh),	% might read 0 chars
	name(A, [Ch|Chars]),			% so might be [Ch]
	read_after_atom(NextCh, Dict, Tokens).

read_number(IntVal, 46, Dict, [T|Tokens]) :-
	get0(Ch),
	!,
	(  (Ch >= 48, Ch =< 57, read_integer(Ch, IntVal2, NextCh)) ->
	   number_codes(IntVal, IntChars),
	   number_codes(IntVal2, IntChars2),
	   append(IntChars, [46|IntChars2], NumChars),
	   number_codes(N, NumChars),
	   T = number(N),
	   read_tokens(NextCh, Dict, Tokens)
	;  T = integer(IntVal),
	   read_fullstop(Ch, Dict, Tokens)
	).
read_number(IntVal, NextCh, Dict, [integer(IntVal)|Tokens]) :-
	read_tokens(NextCh, Dict, Tokens).


%   The only difference between read_after_atom(Ch, Dict, Tokens) and
%   read_tokens/3 is what they do when Ch is "(".  read_after_atom
%   finds the token to be '(', while read_tokens finds the token to be
%   ' ('.  This is how the parser can tell whether <atom> <paren> must
%   be an operator application or an ordinary function symbol application.
%   See the library file READ.PL for details.

read_after_atom(40, Dict, ['('|Tokens]) :- !,
	get0(NextCh),
	read_tokens(NextCh, Dict, Tokens).
read_after_atom(Ch, Dict, Tokens) :-
	read_tokens(Ch, Dict, Tokens).




%   '$rdtok_read_string'(Chars, Quote, NextCh)
%   reads the body of a string delimited by Quote characters.
%   The result is a list of ASCII codes.  There are two complications.
%   If we hit the end of the file inside the string this predicate FAILS.
%   It does not return any special structure.  That is the only reason
%   it can ever fail.  The other complication is that when we find a Quote
%   we have to look ahead one character in case it is doubled.  Note that
%   if we find an end-of-file after the quote we *don't* fail, we return
%   a normal string and the end of file character is returned as NextCh.
%   If we were going to accept C-like escape characters, as I think we
%   should, this would need changing (as would the code for 0'x).  But
%   the purpose of this module is not to present my ideal syntax but to
%   present something which will read present-day Prolog programs.

'$rdtok_read_string'(Chars, Quote, NextCh) :-
	get0(Ch),
	'$rdtok_read_string'(Ch, Chars, Quote, NextCh).

'$rdtok_read_string'(-1, _N, Quote, -1) :-
	display('! end of file in '), put(Quote),
	display(token), put(Quote), nl,
	!, fail.
'$rdtok_read_string'(Quote, Chars, Quote, NextCh) :- !,
	get0(Ch),				% closing or doubled quote
	'$rdtok_more_string'(Ch, Quote, Chars, NextCh).
'$rdtok_read_string'(92, [Ch1|Chars], Quote, NextCh) :- % (flw) \C handling
	!, get0(Ch),
	( '$rdtok_escape'(Ch, Ch1)
	; '$rdtok_read_string'(-1, Chars, Quote, NextCh) % eof, force error
	),
	'$rdtok_read_string'(Chars, Quote, NextCh).
'$rdtok_read_string'(Char, [Char|Chars], Quote, NextCh) :-
	'$rdtok_read_string'(Chars, Quote, NextCh).	% ordinary character

'$rdtok_escape'(-1, -1) :- !, fail.
'$rdtok_escape'(120, Ch) :- % 'x'
	!,
	get0(Ch1), get0(Ch2),
	'$rdtok_hex_digit'(Ch1, D1), '$rdtok_hex_digit'(Ch2, D2),
	Ch is D1 * 16 + D2.
'$rdtok_escape'(Ch1, Ch) :-
	Ch1 >= 48, Ch1 =< 57,	% '0'...'9'
	!,
	get0(Ch2), Ch2 >= 48, Ch2 =< 57,
	get0(Ch3), Ch3 >= 48, Ch3 =< 57,
	Ch is (Ch1 - 48) * 64 + (Ch2 - 48) * 8 + (Ch3 - 48).
'$rdtok_escape'(110, 10). % \n
'$rdtok_escape'(114, 13). % \r
'$rdtok_escape'(116, 9). % \t
'$rdtok_escape'(C, C). % anything else
	
'$rdtok_hex_digit'(C, N) :-
	C >= 48,		% '0'
	( C =< 57, N is C - 48	% '9'
	; (C >= 97		% 'a'
	  -> C =< 102, N is C - 87 % 'f'
	  ; ( C >= 65		   % 'A'
	    -> C =< 70, N is C - 55 % 'F'
	    )
	  )
	).

'$rdtok_more_string'(Quote, Quote, [Quote|Chars], NextCh) :- !,
	'$rdtok_read_string'(Chars, Quote, NextCh).	% doubled quote
'$rdtok_more_string'(NextCh, _, [], NextCh).		% end


%   read_solidus(Ch, Dict, Tokens)
%   checks to see whether /Ch is a /* ... */ comment or a symbol.  If the
%   former, it skips the comment.  If the latter it just calls read_symbol.
%   We have to take great care with /* ... */ comments to handle end of file
%   inside a comment, which is why read_solidus/2 passes back an end of
%   file character or a (forged) blank that we can give to read_tokens.


read_solidus(42, Dict, Tokens) :- !,
	get0(Ch),
	read_solidus(Ch, NextCh),
	read_tokens(NextCh, Dict, Tokens).
read_solidus(Ch, Dict, [atom(A)|Tokens]) :-
	read_symbol(Ch, Chars, NextCh),	% might read 0 chars
	name(A, [47|Chars]),
	read_tokens(NextCh, Dict, Tokens).

read_solidus(-1, -1) :- !,
	display('! end of file in /* ... */ comment'), nl.
read_solidus(42, LastCh) :-
	get0(NextCh),
	NextCh =\= 47, !,	%  might be ^Z or * though
	read_solidus(NextCh, LastCh).
read_solidus(42, 32) :- !.	%  the / was skipped in the previous clause
read_solidus(_N, LastCh) :-
	get0(NextCh),
	read_solidus(NextCh, LastCh).


%   read_name(Char, String, LastCh)
%   reads a sequence of letters, digits, and underscores, and returns
%   them as String.  The first character which cannot join this sequence
%   is returned as LastCh.

read_name(Char, [Char|Chars], LastCh) :-
	( Char >= 97, Char =< 122	% a..z
	; Char >= 65, Char =< 90	% A..Z
	; Char >= 48, Char =< 57	% 0..9
	; Char = 95			% _
	), !,
	get0(NextCh),
	read_name(NextCh, Chars, LastCh).
read_name(LastCh, [], LastCh).


%   read_symbol(Ch, String, NextCh)
%   reads the other kind of atom which needs no quoting: one which is
%   a string of "symbol" characters.  Note that it may accept 0
%   characters, this happens when called from read_fullstop.

read_symbol(Char, [Char|Chars], LastCh) :-
% #$&*+-./:<=>?@\^`~
    member(Char, [35, 36, 38, 42, 43, 45, 46, 47, 58, 60, 61, 62, 63, 64, 92, 94, 96, 126]),
    get0(NextCh),
    read_symbol(NextCh, Chars, LastCh).
read_symbol(LastCh, [], LastCh).


%   read_fullstop(Char, Dict, Tokens)
%   looks at the next character after a full stop.  There are
%   three cases:
%	(a) the next character is an end of file.  We treat this
%	    as an unexpected end of file.  The reason for this is
%	    that we HAVE to handle end of file characters in this
%	    module or they are gone forever; if we failed to check
%	    for end of file here and just accepted .<EOF> like .<NL>
%	    the caller would have no way of detecting an end of file
%	    and the next call would abort.
%	(b) the next character is a layout character.  This is a
%	    clause terminator.
%	(c) the next character is anything else.  This is just an
%	    ordinary symbol and we call read_symbol to process it.

read_fullstop(-1, _X, _Y) :- !,
	display('! end of file just after full stop'), nl,
	fail.
read_fullstop(Ch, _N, []) :-
	Ch =< 32, !.		% END OF CLAUSE
read_fullstop(Ch, Dict, [atom(A)|Tokens]) :-
	read_symbol(Ch, S, NextCh),
	name(A, [46|S]),
	read_tokens(NextCh, Dict, Tokens).



%   read_integer is complicated by having to understand radix notation.
%   There are three forms of integer:
%	0 ' <any character>	- the ASCII code for that character
%	<digit> ' <digits>	- the digits, read in that base
%	<digits>		- the digits, read in base 10.
%   Note that radix 16 is not understood, because 16 is two digits,
%   and that all the decimal digits are accepted in each base (this
%   is also true of C).  So 2'89 = 25.  I can't say I care for this,
%   but it does no great harm, and that's what Dec-10 Prolog does.
%   The X =\= -1 tests are to make sure we don't miss an end of file
%   character.  The tokeniser really should be in C, not least to
%   make handling end of file characters bearable.  If we hit an end
%   of file inside an integer, read_integer will fail.

read_integer(BaseChar, IntVal, NextCh) :-
	Base is BaseChar - 48,
	get0(Ch),
	Ch =\= -1,
	(   Ch == 120, Base == 0, read_digits(0, 16, IntVal, NextCh)
	;   Ch =\= 39, read_digits(Ch, Base, 10, IntVal, NextCh)
	;   Base >= 1, read_digits(0, Base, IntVal, NextCh)
	;   get0(IntVal), IntVal =\= -1, get0(NextCh)
	),  !.

read_digits(SoFar, Base, Value, NextCh) :-
	get0(Ch),
	Ch =\= -1,
	read_digits(Ch, SoFar, Base, Value, NextCh).

read_digits(Digit, SoFar, Base, Value, NextCh) :-
	Digit >= 48, Digit =< 57,
	!,
	Next is SoFar*Base-48+Digit,
	read_digits(Next, Base, Value, NextCh).
read_digits(Digit, SoFar, Base, Value, NextCh) :-
	Base > 10,
	'$rdtok_hex_digit'(Digit, N),
	!,
	Next is SoFar * Base + N,
	read_digits(Next, Base, Value, NextCh).
read_digits(LastCh, Value, _, Value, LastCh).



%   read_lookup is identical to member except for argument order and
%   mode declaration..

read_lookup([X|_], X) :- !.
read_lookup([_M|T], X) :-
	read_lookup(T, X). 
