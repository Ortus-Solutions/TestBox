/**
 * ********************************************************************************
 * Copyright Ortus Solutions, Corp
 * www.ortussolutions.com
 * ********************************************************************************
 * I am the BoxLang coverage provider. I capture per-line coverage via BoxLang's
 * built-in {@code ortus.boxlang.runtime.services.CodeProfilerService}, which is
 * exposed natively to a running BoxLang server (no Java interop needed).
 *
 * Auto-detected when {@code server.keyExists( "boxlang" )} is true AND the runtime
 * config flag {@code codeProfilerEnabled} is enabled (marks are only baked into
 * bytecode at compile time when that flag is on). All query-building and path
 * filtering lives in my {@link CoverageGenerator} base class; I only translate
 * BoxLang's native coverage struct into the per-line count map the base class
 * consumes.
 */
component extends="CoverageGenerator" accessors=true {

	/**
	 * Constructor
	 */
	function init(){
		super.init();

		// Cache the java interop handles once (not per-call)
		variables.runnableLoader   = createObject( "java", "ortus.boxlang.runtime.runnables.RunnableLoader" ).getInstance();
		variables.boxpiler         = variables.runnableLoader.getBoxpiler();
		variables.resolvedFilePath = createObject( "java", "ortus.boxlang.runtime.util.ResolvedFilePath" );

		return this;
	}

	/**
	 * Whether we're running on a BoxLang version that actually exposes the profiler
	 * service AND has code profiling enabled in its runtime config.
	 * <p>
	 * Old BoxLang releases don't have {@code getCodeProfilerService()}, so we probe
	 * for it (try/catch) rather than assume it's there just because the
	 * {@code server.boxlang} key exists. We ALSO require the runtime config flag
	 * {@code codeProfilerEnabled} to be true — the boxpiler only emits profiler
	 * marks at compile time when that flag is on, so without it there'd be no spans
	 * to capture even though the service is present.
	 *
	 *         enabled in the runtime config, false otherwise
	 *
	 * @return true if the profiler service is reachable and code profiling is
	 */
	boolean function isProviderAvailable(){
		if ( !server.keyExists( "boxlang" ) ) {
			return false;
		}

		try {
			variables.profiler = getBoxRuntime().getCodeProfilerService();
			// Marks are only baked in at compile time when the config flag is on.
			return getBoxRuntime().getConfiguration().codeProfilerEnabled ?: false;
		} catch ( Any e ) {
			// Older BoxLang without the profiler service or config flag
			return false;
		}
	}

	/**
	 * BoxLang captures continuously while the profiler is enabled, but marks are
	 * ONLY emitted at COMPILE time and only when the runtime config flag
	 * {@code codeProfilerEnabled} is true (checked by {@link #isProviderAvailable()}).
	 * Here we clear the page pool + compiled classes so everything recompiles WITH
	 * instrumentation under this capture, and set live capture active.
	 *
	 */
	CoverageGenerator function beginCapture(){
		// Fresh capture session: drop the span execution counts and blueprints the
		// previous session left behind, otherwise they accumulate across runs.
		variables.profiler.reset();
		// Clear the in-memory page pool. We do NOT wipe the compiled class files: an
		// unchanged file is not recompiled, so its blueprint is recovered from the
		// already-compiled class by compileAndLoad() instead of by recompiling it.
		pagePoolClear();
		variables.profiler.setActive( true );

		return this;
	}

	/**
	 * BoxLang has no fragile instrumentation to leave on/off. We just stop live
	 * capture; leave the compile-time flag as the user configured it.
	 *
	 * @leaveLineProfilingOn Ignored on BoxLang.
	 */
	CoverageGenerator function endCapture( leaveLineProfilingOn = false ){
		variables.profiler.setActive( false );
		return this;
	}

	/**
	 * Return per-line coverage for a single file, keyed by 1-based line number.
	 *
	 * The BoxLang profiler reports lines touched by an executable span; each entry
	 * is {@code { covered, count, totalNanos }}. We surface the raw run count,
	 * matching the shape FusionReactor's provider produces so the base class is
	 * provider-agnostic.
	 *
	 * @filePath the absolute path to the file to gather coverage for
	 *
	 * @return struct of lineNum -> count (only executable lines)
	 */
	struct function getLineMetricsMap( required string filePath ){
		// Ask the profiler for THIS file's live per-line data directly (a sorted
		// Map<Integer, LineCoverage>). Do NOT build the whole-runtime coverage report
		// here — this method runs once per file, so that would be O(files^2).
		// fileLines() resolves the path itself (exact, normalized, then
		// case/separator-insensitive) and returns an empty map if it isn't tracked.
		var lines  = variables.profiler.fileLines( arguments.filePath );
		// Return a NATIVE struct, NOT a java.util.Map. The base class probes this map
		// once per source line (existence check + index read), and every one of those
		// probes against a raw Java Map pays dynamic-interop overhead — which is what
		// made report generation crawl on large captures. A native struct keeps the
		// entire per-line loop on BoxLang's fast path.
		var result = structNew( "linked" );
		for ( var entry in lines.entrySet() ) {
			var lineCoverage = entry.getValue();
			if ( !isNull( lineCoverage ) ) {
				result[ entry.getKey() ] = javacast( "int", lineCoverage.count() );
			}
		}

		return result;
	}

	/**
	 * Force a file to be compiled and loaded so the boxpiler registers an
	 * instrumented blueprint for it, even if it was never hit during the tests.
	 * Without this, a file that never ran has no blueprint, so getLineMetricsMap
	 * returns nothing and the base class's no-data fallback would mark every line
	 * executable (all-red) instead of using the real compiled span map. This
	 * mirrors what the FusionReactor/Lucee/Adobe providers do with their template
	 * compilers.
	 *
	 * An unchanged file is NOT recompiled by the boxpiler, and the class's static
	 * initializer (which registers its blueprint) has already run, so compiling alone
	 * does not bring the blueprint back. Every instrumented class carries its own
	 * blueprint in a static field, so we hand that back to the profiler instead of
	 * wasting a recompile.
	 *
	 * A file that does not compile (a syntax error, for example) has no blueprint,
	 * so we log the failure and throw a "coverage.failureToCompile" error for the
	 * base class to flag the file with an error status instead of reporting a bogus
	 * 100% for a file we could not measure.
	 *
	 * @filePath the absolute path to the file to compile and load
	 */
	void function compileAndLoad( required string filePath ){
		// Compilation differs by file type: .cfc/.bx are CLASSES (compiled via the
		// boxpiler's compileClass), everything else is a TEMPLATE (compiled via the
		// boxpiler's compileTemplate). Compile ONLY — never load/run the file, or
		// report generation would execute arbitrary application code.
		//
		// Use the handles cached in init() rather than createObject() per file: this
		// runs once for every file that had no captured metrics, so re-resolving the
		// same Java classes thousands of times is pure overhead.
		try {
			var resolved  = variables.resolvedFilePath.of( arguments.filePath );
			var lowerPath = lCase( arguments.filePath );
			var compiled  = ( lowerPath.endsWith( ".cfc" ) || lowerPath.endsWith( ".bx" ) )
			 ? variables.boxpiler.compileClass( resolved )
			 : variables.boxpiler.compileTemplate( resolved );

			registerBlueprintFromClass( compiled, arguments.filePath );
		} catch ( any e ) {
			throwCompileFailure( arguments.filePath, e );
		}
	}

	/**
	 * Register the coverage blueprint an ALREADY COMPILED class carries.
	 *
	 * Every instrumented class keeps its own blueprint in the public static
	 * {@code codeProfilerBlueprint} field, and the profiler exposes
	 * {@code registerBlueprintForFile()} to take it back. This is how we recover a
	 * blueprint for a file the boxpiler did not recompile (its source has not
	 * changed) and whose static initializer already ran, without a wasteful
	 * recompile. Registration is idempotent, so calling it again is harmless.
	 *
	 * @compiledClass the class the boxpiler compiled and loaded for the file
	 * @filePath      the absolute path of the file the class was compiled from
	 */
	private void function registerBlueprintFromClass( required any compiledClass, required string filePath ){
		var blueprint = arguments.compiledClass::codeProfilerBlueprint ?: null;

		if ( !isNull( blueprint ) ) {
			variables.profiler.registerBlueprintForFile( arguments.filePath, blueprint );
		}
	}

	/**
	 * Normalize a path to match BoxLang's profiler key: forward slashes, lowercase.
	 *
	 * @filePath the absolute path to normalize
	 *
	 * @return the normalized path
	 */
	private string function normalizeFilePath( required string filePath ){
		return lCase( arguments.filePath.replace( "\", "/", "all" ) );
	}

	/**
	 * BoxLang registers a compile-time blueprint for every file it compiles, and the
	 * blueprint holds the file's executable SPANS. A file with no executable code at
	 * all — for example a template or class that holds nothing but a comment —
	 * compiles to a blueprint with an EMPTY span list, so we can tell it apart from a
	 * file we simply have no data for and not report it as a misleading 0%.
	 *
	 * An empty span list only means "no executable code" when the file is actually
	 * REGISTERED: the profiler reports no spans for an unregistered file too, and a
	 * file we could not register (a class already loaded before this capture, for
	 * example) is not a file without code. Those fall back to true.
	 *
	 *         registered with none
	 *
	 * @filePath the absolute path to the file to inspect
	 *
	 * @return true if the file has at least one executable span, false if it is
	 */
	boolean function hasExecutableCode( required string filePath ){
		var spans = variables.profiler.fileSpans( arguments.filePath );
		return isNull( spans ) ? true : ( spans.size() > 0 || !isFileRegistered( arguments.filePath ) );
	}

	/**
	 * Is this file registered with the profiler?
	 *
	 * @filePath the absolute path to check
	 */
	private boolean function isFileRegistered( required string filePath ){
		var normalized = normalizeFilePath( arguments.filePath );
		for ( var key in variables.profiler.trackedBlueprints().keySet() ) {
			if ( normalizeFilePath( key ) == normalized ) {
				return true;
			}
		}
		return false;
	}

}
