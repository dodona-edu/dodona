importScripts("../diff.js");

// start evaluation when source code is received
onmessage = function (e) {
    // create new JavaScript Judge for submitted source code
    judge = new Judge(e.data.source, e.data.tests);

    // execute source code and tests
    judge.run();
}

function Judge(sourceCode, tests) {
    // private variables
    var test_cases = [];
    var test_index = 0;
    var evaluate = eval;
    var currentExpression;

    // use timer to avoid infinite loops or source code executing too slow
    var timeout = 10 * 1000; // default timeout after 10 seconds
    var timer;

    // return public interface of Judge
    return {
        // execute source code and tests
        run: run,

        // set new test case
        test: test,

        // set new timeout
        setTimeout: setCustomTimeout
    };

    // add test case to queue of test cases
    function test() {
        test_cases.push(Array.prototype.slice.call(arguments));
    }

    //	// helper function to set new timeout value (in milliseconds)
    //	function setCustomTimeout(ms) {
    //
    //		timeout = ms;
    //
    //	}
    //
    //	// helper function to set custom timeout
    //	function startTimer() {
    //
    //		console.log("timeout will be fired after {ms} ms.".format({ms: timeout}));
    //
    //		// clear previous timer
    //		clearTimeout(timer);
    //
    //	    // set new timeout to abort code execution after ms milliseconds
    //	    timer = setTimeout(function() {
    //
    //			console.log("timeout fired.");
    //
    //			var rows = [];
    //
    //	    	// add current expression to feedback table (if available)
    //	    	if (currentExpression) {
    //
    //	    		rows.push({
    //	    	    	"type": "statement",
    //	    	    	"content": currentExpression
    //	    	    });
    //
    //	    	}
    //
    //	    	// add error message about time limit exceeded to feedback table
    //	    	rows.push({
    //    			"type": "error",
    //        		"eval": "TLE",
    //        		"content": "JudgeError: time limit exceeded"
    //	        });
    //
    //        	// add runtime error to feedback table
    //        	postMessage({
    //        		"rows": rows,
    //        		"eval": "TLE",
    //    			"weight": 1,
    //        		"done": true
    //        	});
    //
    //        	// close();
    //
    //	    }, 1);
    //
    //	}

    // set custom timeout
    function setCustomTimeout(ms) {

        postMessage({
            "type": "setting",
            "name": "timeout",
            "value": ms
        });

    }

    // execute test cases in queued order
    function run() {
        // start timer that will be fired upon timeout
        // startTimer();

        evaluate(tests);

        try {
            // execute source code in the global scope
            evaluate(sourceCode);
        } catch (e) {
            // add runtime error to feedback table
            postMessage({
                "rows": [{
                    "type": "error",
                    "eval": "CE",
                    "content": displayError(e, true)
                }],
                "eval": "CE",
                "weight": 1,
                "done": true
            });

            // stop any further processing of test cases
            return;
        }

        while (test_index < test_cases.length) {
            // execute the next available test case
            exec_test.apply(undefined, test_cases[test_index++]);
        }
    }

    function exec_test(expression, expected, comparison) {
        // set the current expression
        currentExpression = expression;

        // prepare object that will be returned to main thread
        var feedback = {
            "rows": [],
            "eval": "IE",
            "weight": 1,
            "done": test_index == test_cases.length
        }

        //
        // check correctness of submitted solution for this test case
        //

        var correct, str_expected, generated, str_generated;

        // check if exception was expected and adjust expected if this is the
        // case
        var expected_exception = false;
        try {
            // check if expected exception is a string that starts with
            // "expection:" prefix
            expected_exception = (expected.slice(0, 10) === "exception:");

            // remove "expection:" prefix in case of expected exception
            if (expected_exception) {
                str_expected = expected.slice(10);
            }
        } catch (e) {}

        // evaluate expression and set generated result accordingly
        var generated_exception = false;
        try {
            generated = evaluate(expression);

            if (comparison === undefined) {
                comparison = equals;
            }

            // check whether generated result is as expected
            args = [expected, generated]
            args = args.concat([].slice.call(arguments, 3));
            correct = (!expected_exception &&
                comparison.apply(comparison, args)
            );
        } catch (e) {
            // remember that exception was generated
            generated_exception = true;

            // convert exception into string
            generated = e;
            str_generated = displayError(e);

            // check whether generated exception is as expected
            correct = (
                expected_exception &&
                equals(str_expected, str_generated)
            );
        }

        // set evaluation status of feedback
        feedback.eval = correct ? "AC" : "WA";

        //
        // compile feedback that must be added to feedback table
        //

        // add statement/expression tested to feedback table
        feedback.rows.push({
            "type": "statement",
            "content": expression
        });

        // add expected and generated output to feedback table
        if (expected !== undefined || generated !== undefined) {
            // convert expected result to string
            if (!expected_exception) {
                str_expected = display(expected);
            }

            // convert generated result to string
            if (!generated_exception) {
                str_generated = display(generated);
            }

            if (!correct && generated_exception && !expected_exception) {
                feedback.eval = "RE";
                feedback.rows.push({
                    "type": "error",
                    "eval": feedback.eval,
                    "content": str_generated
                });
            } else if (!correct) {
                var diff_expected = '',
                    diff_generated = '';

                // determine whether results should be diffed
                var show_diffed = true;
                if (
                    expected_exception !== generated_exception &&
                    (expected_exception || generated_exception)
                ) {
                    // no diff if only one exception thrown
                    show_diffed = false;
                } else if (
                    expected === undefined || expected === null ||
                    generated === undefined || generated === null
                ) {
                    // no diff if either of the results is undefined or null
                    show_diffed = false;
                }

                // diff results if needed
                if (show_diffed) {
                    // diff string representations of expected and generated
                    // results
                    var diff = JsDiff.diffChars(str_expected, str_generated);

                    // compose diffed representations of expected and generated
                    // results
                    diff.forEach(function (part) {
                        if (part.added) {
                            diff_generated += (
                                '<span class="removed">{part}</span>'.format({
                                    "part": part.value
                                })
                            );
                        } else if (part.removed) {
                            diff_expected += (
                                '<span class="added">{part}</span>'.format({
                                    "part": part.value
                                })
                            );
                        } else {
                            diff_expected += part.value;
                            diff_generated += part.value;
                        }
                    });
                }

                feedback.rows.push({
                    "type": "correct",
                    "content": show_diffed ? diff_expected : str_expected
                });

                feedback.rows.push({
                    "type": "wrong",
                    "content": show_diffed ? diff_generated : str_generated
                });

            } else {

                feedback.rows.push({
                    "type": "correct",
                    "content": str_generated
                });

            }

        }

        // set evaluation status of rows to global evaluation status
        feedback.rows.forEach(function (row) {
            row.eval = feedback.eval;
        });

        // return feedback to the main thread
        postMessage(feedback);

        // clear the current expression
        currentExpression = undefined;
    };

    // helper function for testing the equality of two given values
    function equals(obj1, obj2) {
        var i, key;

        if (Array.isArray(obj1)) {
            // check if second object is also an array
            if (!Array.isArray(obj2)) {
                return false;
            }

            // check if both arrays have the same length
            if (obj1.length !== obj2.length) {
                return false;
            }

            // check if corresponding objects are the same
            for (i = 0; i < obj1.length; ++i) {
                if (!equals(obj1[i], obj2[i])) {
                    return false;
                }
            }

            // both arrays are the same
            return true;
        } else if (typeof obj1 === undefined) {
            return obj2 === undefined;
        } else if (typeof obj1 === 'object') {
            // check if second object is also an object
            if (typeof obj2 !== 'object') {
                return false;
            }

            // check if all keys of obj1 are in obj2 with the same value
            for (key in obj1) {
                if (obj1.hasOwnProperty(key) && !equals(obj1[key], obj2[key])) {
                    return false;
                }
            }

            // check if all keys of obj1 are in obj2 with the same value
            for (key in obj2) {
                if (obj2.hasOwnProperty(key) && !equals(obj1[key], obj2[key])) {
                    return false;
                }
            }

            // both objects are the same
            return true;
        } else {
            // check if both objects are the same using the === operator
            return obj1 === obj2;
        }
    }
}

function display(obj) {
    var str = '',
        keys = [],
        key, i;

    if (obj === undefined) {
        return 'undefined';
    } else if (obj === null) {
        return 'null';
    } else if (Array.isArray(obj)) {
        for (i = 0; i < obj.length; ++i) {
            if (str) {
                str += ', ';
            }
            str += display(obj[i]);
        }
        return '[' + str + ']';
    } else if (typeof obj === 'object') {
        // pretty print object
        for (key in obj) {
            if (obj.hasOwnProperty(key)) {
                keys.push(key);
            }
        }
        keys.sort();
        for (i = 0; i < keys.length; ++i) {
            if (str) {
                str += ', ';
            }
            str += display(keys[i]) + ': ' + display(obj[keys[i]]);
        }
        return '{' + str + '}';
    } else {
        if (typeof obj === 'string') {
            // return "'" + obj + "'";
            var repr = JSON.stringify(obj);
            if (
                repr.indexOf("'") === -1 &&
                repr.slice(1, -1).indexOf('\\"') >= 0
            ) {
                repr = "'{repr}'".format({
                    repr: repr.slice(1, -1).replace('\\"', '"', "g")
                });
            }
            return repr;
        } else {
            // pretty print general object
            return obj.toString();
        }
    }
}

// helper function for converting Error objects to string
function displayError(e, showLine) {
    try {
        if (typeof e === "string") {
            return e;
        } else {
            // format message
            if (e.name !== undefined && e.message !== undefined) {
                // add line number if available
                if (
                    // check if line number is available
                    e.lineNumber &&
                    // check if stack trace is available
                    e.stack &&
                    // check if stack trace goes deeper than error in statement
                    // that is being executed (in other words: in the submitted
                    // source code)
                    e.stack.split("\n").length != 5
                ) {
                    message = "{name} (line {line}): {message}";
                } else {
                    message = "{name}: {message}";
                }
                message = message.format({
                    name: e.name,
                    message: e.message,
                    line: e.lineNumber
                });
            } else {
                message = "JudgeError: ill-formed Error";
                if (display(e) !== "") {
                    message += ": " + display(e)
                }
            }
            return message;
        }
    } catch (e) {
        return e.toString();
    }
}

String.prototype.format = function (dict) {
    return this.replace(/{([^{}]*)}/g, function (match, naam) {
        var waarde = dict[naam];
        return waarde !== undefined ? waarde.toString() : match;
    });
};
