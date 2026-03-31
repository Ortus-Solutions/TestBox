function debounce( func, wait, immediate ) {
	let timeout;
	return function() {
		let context = this,
			args = arguments;
		let later = function() {
			timeout = null;
			if ( !immediate ) {
				func.apply( context, args );
			}
		};
		let callNow = immediate && !timeout;
		clearTimeout( timeout );
		timeout = setTimeout( later, wait );
		if ( callNow ) {
			func.apply( context, args );
		}
	};
}
$( "##bundleFilter" ).keyup( debounce( function() {
	let targetText = $( this ).val().toLowerCase();
	$( ".bundle" ).each( function( index ) {
		let bundle = $( this ).data( "bundle" ).toLowerCase();
		if ( bundle.search( targetText ) < 0 ) {
			$( this ).hide();
		} else {
			$( this ).removeAttr('style');
		}
	});
}, 100));

$( "##bundleFilter" ).focus();

$( "body" ).on("click", "##collapse-bundles", function() {
	$(".details-panel").collapse("hide");
	$(".bundle-btn > svg.plus-minus").attr("data-icon", "plus-square");
});

$( "body" ).on("click", "##expand-bundles", function() {
	$(".details-panel:not(.show)").collapse("show");
	$(".bundle-btn > svg.plus-minus").attr("data-icon", "minus-square");
});
