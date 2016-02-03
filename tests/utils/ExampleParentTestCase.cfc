component extends="testbox.system.BaseSpec" {

    /**
     * @beforeEach
     */
    function runThisBefore() {
        variables.counter++;
    }

    /**
     * @afterEach
     */
    function runThisAfter(currentSpec) {
        if (arguments.currentSpec == "runs lifecycle annotation hooks just as if they were in the suite") {
            expect(variables.counter).toBe(2);
        } else {
            expect(variables.counter).toBe(5);
        }
    }
}
