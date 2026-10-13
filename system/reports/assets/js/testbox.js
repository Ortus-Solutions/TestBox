/*
 * Behavior of the TestBox HTML reports, built on Alpine.
 *
 * The server renders all the markup (and works without this file). Alpine adds filtering,
 * collapsing, theming, keyboard shortcuts and the Ask AI menu on top of it.
 *
 * Markup contract:
 *   [data-spec][data-status][data-search][data-bundle]  one spec (a row, or a dot). With data-dim it is dimmed instead of hidden
 *   .tb-suite                                         a suite, hidden when it has no visible spec
 *   .tb-bundle[data-bundle]                           a bundle card
 *   .tb-failure                                       a failure card, target of "next failure"
 *   template[data-prompt="ID"] / template[data-agent="ID"]   the Ask AI payloads, per failed spec
 *   script#tb-config                                  JSON: { aiAssist, providers, maxUrlLength, bundles: { id: openByDefault } }
 */
document.addEventListener( "alpine:init", function () {
	Alpine.data( "tbReport", function () {
		return {
			// ---- state
			config: {},
			theme: "system",
			q: "",
			statuses: [],
			bundleStatus: {},
			open: {},
			focusId: null,
			aiOk: false,
			toast: "",
			toastTimer: null,
			failureIndex: -1,
			drawer: null,

			init() {
				var node = document.getElementById( "tb-config" );
				this.config = node ? JSON.parse( node.textContent ) : {};
				this.open = Object.assign( {}, this.config.bundles || {} );
				try {
					this.theme = localStorage.getItem( "testbox-theme" ) || "system";
					this.aiOk = localStorage.getItem( "testbox-ai-ok" ) === "1";
				} catch ( e ) {}
				this.applyTheme();
				this.highlightCode();
				var self = this;
				this.$watch( "q", function () {
					self.revealMatches();
				} );
				if ( window.matchMedia ) {
					window.matchMedia( "(prefers-color-scheme: dark)" ).addEventListener( "change", function () {
						if ( self.theme === "system" ) self.applyTheme();
					} );
				}
			},

			// ---- theme
			setTheme( mode ) {
				this.theme = mode;
				try {
					localStorage.setItem( "testbox-theme", mode );
				} catch ( e ) {}
				this.applyTheme();
			},
			applyTheme() {
				var dark =
					this.theme === "dark" ||
					( this.theme === "system" && window.matchMedia && window.matchMedia( "(prefers-color-scheme: dark)" ).matches );
				document.documentElement.setAttribute( "data-bs-theme", dark ? "dark" : "light" );
			},

			// ---- bundles
			isOpen( id ) {
				return !!this.open[ id ];
			},
			toggle( id ) {
				this.open[ id ] = !this.open[ id ];
			},
			setAll( value ) {
				var self = this;
				document.querySelectorAll( ".tb-bundle[data-bundle]" ).forEach( function ( el ) {
					self.open[ el.dataset.bundle ] = value;
				} );
			},

			// ---- filtering (one pass over the DOM, cheap even with thousands of specs)
			get filtering() {
				return this.q.trim() !== "" || this.statuses.length > 0 || Object.values( this.bundleStatus ).some( Boolean );
			},
			toggleStatus( status ) {
				var i = this.statuses.indexOf( status );
				i < 0 ? this.statuses.push( status ) : this.statuses.splice( i, 1 );
				this.revealMatches();
			},
			toggleBundleStatus( bundle, status ) {
				this.bundleStatus[ bundle ] = this.bundleStatus[ bundle ] === status ? null : status;
			},
			resetFilters() {
				this.q = "";
				this.statuses = [];
				this.bundleStatus = {};
			},
			// open the bundles that have matches so a filter never hides its own results
			revealMatches() {
				var self = this;
				this.$nextTick( function () {
					document.querySelectorAll( ".tb-bundle[data-bundle]" ).forEach( function ( el ) {
						if ( el.querySelector( "[data-spec]:not([hidden]):not(.tb-dim)" ) ) self.open[ el.dataset.bundle ] = true;
					} );
				} );
			},
			applyFilters() {
				var q = this.q.trim().toLowerCase();
				var statuses = this.statuses.slice();
				var perBundle = Object.assign( {}, this.bundleStatus );
				var globalActive = q !== "" || statuses.length > 0;
				var shown = "[data-spec]:not([hidden]):not(.tb-dim)";

				document.querySelectorAll( "[data-spec]" ).forEach( function ( spec ) {
					var show = true;
					if ( q && ( spec.dataset.search || "" ).indexOf( q ) < 0 ) show = false;
					if ( show && statuses.length && statuses.indexOf( spec.dataset.status ) < 0 ) show = false;
					var bundle = spec.closest( ".tb-bundle" );
					var own = perBundle[ bundle ? bundle.dataset.bundle : spec.dataset.bundle ];
					if ( show && own && own !== spec.dataset.status ) show = false;
					if ( spec.hasAttribute( "data-dim" ) ) {
						spec.classList.toggle( "tb-dim", !show );
					} else {
						spec.hidden = !show;
					}
				} );

				// suites: deepest first so a parent sees its children's final state
				Array.from( document.querySelectorAll( ".tb-suite" ) )
					.reverse()
					.forEach( function ( suite ) {
						var bundle = suite.closest( ".tb-bundle" );
						var own = bundle && perBundle[ bundle.dataset.bundle ];
						suite.hidden = ( globalActive || own ) && !suite.querySelector( shown );
					} );

				document.querySelectorAll( "[data-bundle].tb-bundle" ).forEach( function ( bundle ) {
					var hasMatch = !!bundle.querySelector( shown );
					bundle.hidden = globalActive && !hasMatch;
					var empty = bundle.querySelector( ".tb-empty" );
					if ( empty ) empty.hidden = !( ( globalActive || perBundle[ bundle.dataset.bundle ] ) && !hasMatch );
				} );

				document.querySelectorAll( ".tb-doc-nav a[data-bundle]" ).forEach( function ( link ) {
					var target = document.querySelector( ".tb-bundle[data-bundle='" + link.dataset.bundle + "']" );
					link.hidden = globalActive && !!( target && target.hidden );
				} );

				var none = document.getElementById( "tb-no-matches" );
				if ( none ) none.hidden = !( globalActive && !document.querySelector( ".tb-bundle:not([hidden])" ) );
			},

			// ---- failures
			nextFailure() {
				// Simple has failure cards, Dot has dots, Doc has spec entries
				var targets = Array.from( document.querySelectorAll( ".tb-failure" ) );
				if ( !targets.length ) {
					targets = Array.from( document.querySelectorAll( "[data-spec][data-status='failed'], [data-spec][data-status='error']" ) ).filter( function ( el ) {
						return !el.hidden && !el.classList.contains( "tb-dim" );
					} );
				}
				if ( !targets.length ) return;
				this.failureIndex = ( this.failureIndex + 1 ) % targets.length;
				var el = targets[ this.failureIndex ];
				document.querySelectorAll( ".tb-focus" ).forEach( function ( old ) {
					old.classList.remove( "tb-focus" );
				} );
				el.classList.add( "tb-focus" );
				if ( el.hasAttribute( "data-dim" ) ) {
					this.openSpec( el );
				} else {
					var calm = window.matchMedia( "(prefers-reduced-motion: reduce)" ).matches;
					el.scrollIntoView( { behavior: calm ? "auto" : "smooth", block: "center" } );
				}
			},
			onKey( event ) {
				var tag = ( event.target.tagName || "" ).toLowerCase();
				if ( tag === "input" || tag === "textarea" || tag === "select" || event.metaKey || event.ctrlKey || event.altKey ) return;
				if ( event.key === "f" || event.key === "F" ) {
					event.preventDefault();
					this.nextFailure();
				} else if ( event.key === "Escape" && this.drawer ) {
					this.closeSpec();
				} else if ( event.key === "/" ) {
					var input = document.getElementById( "tb-filter" );
					if ( input ) {
						event.preventDefault();
						input.focus();
					}
				}
			},

			// ---- spec drawer (Dot): details of one dot without leaving the page
			openSpec( el ) {
				var d = el.dataset;
				this.drawer = { id: d.specId, name: d.name, status: d.status, ms: d.ms, bundle: d.bundleName, crumb: d.crumb, runUrl: d.runUrl };
								var self = this;
				this.$nextTick( function () {
					var body = document.getElementById( "tb-drawer-body" );
					if ( !body ) return;
					body.replaceChildren();
					var tpl = document.querySelector( "template[data-panel='" + d.specId + "']" );
					if ( tpl ) body.appendChild( tpl.content.cloneNode( true ) );
					self.highlightCode();
				} );
			},
			dotClick( event ) {
				var el = event.target.closest( "[data-spec]" );
				if ( el ) this.openSpec( el );
			},
			closeSpec() {
				this.drawer = null;
			},

			// ---- code highlighting (Prism is optional: plain text is fine)
			highlightCode() {
				if ( !window.Prism ) return;
				document.querySelectorAll( ".tb-code[data-lang]" ).forEach( function ( block ) {
					var lang = block.dataset.lang;
					var grammar = Prism.languages[ lang ];
					if ( !grammar ) return;
					block.querySelectorAll( ".tb-code__line" ).forEach( function ( line ) {
						line.innerHTML = Prism.highlight( line.textContent, grammar, lang );
					} );
				} );
			},

			// ---- Ask AI
			payload( kind, id ) {
				var node = document.querySelector( "template[data-" + kind + "='" + id + "']" );
				return node ? node.content.textContent : "";
			},
			say( html ) {
				this.toast = html;
				clearTimeout( this.toastTimer );
				var self = this;
				this.toastTimer = setTimeout( function () {
					self.toast = "";
				}, 4200 );
			},
			escape( text ) {
				return String( text ).replace( /&/g, "&amp;" ).replace( /</g, "&lt;" );
			},
			zoom( event ) {
				var thumb = event.currentTarget.querySelector( "img" );
				if ( !thumb || !this.$refs.zoom || typeof this.$refs.zoom.showModal !== "function" ) {
					return;
				}
				this.$refs.zoomImg.src = thumb.src;
				this.$refs.zoomImg.alt = thumb.alt;
				this.$refs.zoom.showModal();
			},
			copy( text, message ) {
				var self = this;
				var fallback = function () {
					var area = document.createElement( "textarea" );
					area.value = text;
					area.setAttribute( "readonly", "" );
					area.style.position = "fixed";
					area.style.opacity = "0";
					document.body.appendChild( area );
					area.select();
					var ok = false;
					try {
						ok = document.execCommand( "copy" );
					} catch ( e ) {}
					document.body.removeChild( area );
					self.say( ok ? message : "Copy is blocked here. Use Preview and select the text." );
				};
				try {
					navigator.clipboard.writeText( text ).then( function () { self.say( message ); }, fallback );
				} catch ( e ) {
					fallback();
				}
			},
			aiCopy( id ) {
				var text = this.payload( "prompt", id );
				this.copy( text, "Prompt copied (" + text.length + " characters). Nothing left this page." );
			},
			aiCopyAgent( id ) {
				this.copy( this.payload( "agent", id ), "Copied JSON for a coding agent." );
			},
			aiCopyAll() {
				var self = this;
				var prompts = Array.from( document.querySelectorAll( "template[data-prompt]" ) ).map( function ( node ) {
					return node.content.textContent;
				} );
				if ( !prompts.length ) return;
				var body = prompts
					.map( function ( text, i ) {
						return "--- " + ( i + 1 ) + " ---\n" + text.split( "\n" ).slice( 2 ).join( "\n" );
					} )
					.join( "\n\n" );
				var intro = prompts[ 0 ].split( "\n" )[ 0 ].replace( /One spec .*$/, prompts.length + " specs did not pass." );
				this.copy( intro + " Group them by likely shared cause and suggest fixes.\n\n" + body, "Copied one prompt covering " + prompts.length + " failures." );
			},
			aiPreview( id ) {
				return this.payload( "prompt", id );
			},
			aiConfirm() {
				this.aiOk = true;
				try {
					localStorage.setItem( "testbox-ai-ok", "1" );
				} catch ( e ) {}
			},
			aiOpen( providerId, id ) {
				var provider = ( this.config.providers || [] ).find( function ( p ) {
					return p.id === providerId;
				} );
				if ( !provider ) return;
				var text = this.payload( "prompt", id );
				var max = this.config.maxUrlLength || 6000;
				var build = function ( body ) {
					return provider.url.replace( "{prompt}", encodeURIComponent( body ) );
				};
				var url = build( text );
				var trimmed = false;
				// a long stack can push the link past what sites accept: drop stack frames from the bottom until it fits
				var lines = text.split( "\n" );
				var start = lines.indexOf( "Stack (your code first):" );
				var end = lines.indexOf( "Re-run only this spec:" );
				while ( url.length > max && start > -1 && end - start > 2 ) {
					lines.splice( end - 2, 1 );
					end--;
					trimmed = true;
					url = build( lines.join( "\n" ) );
				}
				// an anchor click inside the user's gesture is not treated as a blocked popup, and noopener keeps the new tab detached
				var link = document.createElement( "a" );
				link.href = url;
				link.target = "_blank";
				link.rel = "noopener noreferrer";
				document.body.appendChild( link );
				link.click();
				document.body.removeChild( link );
				// some sites ignore the prefilled link, so the prompt is on the clipboard too
				this.copy(
					text,
					"Opened " + this.escape( provider.name ) + ( trimmed ? " (stack trimmed to fit the link)" : "" ) + ". The prompt is also on your clipboard in case the site ignores the link."
				);
			}
		};
	} );
} );
