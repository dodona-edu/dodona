// helper function to dynamically attach method to Function prototype
function dynamicMethodLoader(name, func) {

    // attach given function to prototype attribute having the given name, in
    // case prototype did not had attribute with the given name
    if (!this.prototype.hasOwnProperty(name)) {
        Object.defineProperty(
            this.prototype,
            name, {
                value: func,
                enumerable: false
            }
        );
    }

    // return Function instance to allow chaining of method calls
    return this;
}

// attach helper function to Function prototype as method with name "method"
dynamicMethodLoader.call(Function, 'method', dynamicMethodLoader);

// new string method that replaces in a string all placeholders having format
// {name} by the value mapped from "name" by the object that is passed as an
// argument to the method; the placeholder is not replaced if the passed object
// has not property "name"
String.method('format', function (dict) {
    return this.replace(/{([^{}]*)}/g, function (match, naam) {
        var waarde = dict[naam];
        return waarde !== undefined ? waarde.toString() : match;
    });
});

// helper function for pretty printing values
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
