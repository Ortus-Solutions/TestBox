// Runs in <head> before first paint so the page never flashes the wrong theme.
(function () {
	var mode = "system";
	try {
		mode = localStorage.getItem( "testbox-theme" ) || "system";
	} catch ( e ) {}
	var dark = mode === "dark" || ( mode === "system" && window.matchMedia && window.matchMedia( "(prefers-color-scheme: dark)" ).matches );
	document.documentElement.setAttribute( "data-bs-theme", dark ? "dark" : "light" );
})();
