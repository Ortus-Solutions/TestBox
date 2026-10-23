/** Environment lifecycle. Providers must clean up resources after partial startup, cancellation and failure. */
interface {

	function prepareRun( required struct context );

	struct function startWorker( required struct context );

	struct function pollWorker( required struct worker );

	function stopWorker( required struct worker );

	boolean function isCancelled( required struct context );

	function finishRun( required struct context );

}
