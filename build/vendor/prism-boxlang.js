/**
 * BoxLang grammar for Prism.
 * Keyword, scope and operator lists follow the Ortus `brush-boxlang` SyntaxHighlighter brush
 * (https://github.com/ortus-boxlang/brush-boxlang). Update them there first, then here.
 */
( function ( Prism ) {
	var keywords =
		"abstract|as|assert|break|case|castas|catch|class|component|continue|default|do|does|else|extends|final|finally|for|function|greater|if|imp|import|implements|in|include|instanceof|interface|is|less|lock|new|package|param|private|property|public|remote|required|return|static|switch|than|thread|throw|to|transaction|try|var|when|while";
	var scopes =
		"application|arguments|attributes|caller|client|cgi|form|local|request|server|session|super|url|this|variables";
	var operators = "and|or|not|xor|mod|eq|neq|lt|le|gt|ge|equal|contains|eqv";

	Prism.languages.boxlang = Prism.languages.extend( "clike", {
		comment : [
			{ pattern : /<!---[\s\S]*?--->/, greedy : true },
			{ pattern : /\/\*[\s\S]*?\*\//, greedy : true },
			{ pattern : /\/\/.*/, greedy : true }
		],
		string : {
			pattern : /(["'])(?:\\.|(?!\1)[^\\\r\n])*\1/,
			greedy  : true,
			inside  : { interpolation : { pattern : /#[^#\r\n]+#/, alias : "number" } }
		},
		annotation : { pattern : /@\w+/, alias : "atrule" },
		keyword    : new RegExp( "\\b(?:" + keywords + ")\\b", "i" ),
		builtin    : new RegExp( "\\b(?:" + scopes + ")\\b", "i" ),
		boolean    : /\b(?:true|false|yes|no|null)\b/i,
		operator   : new RegExp( "->|=>|\\?:|\\?\\.|&&|\\|\\||[!=]==?|[<>]=?|[-+*/%&|^]|\\b(?:" + operators + ")\\b", "i" )
	} );
} )( Prism );
