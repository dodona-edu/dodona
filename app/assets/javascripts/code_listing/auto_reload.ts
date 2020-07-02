function timerWithoutUserInteraction(element, delay, callback, pollingInterval= 10): object {
    element.pollingInterval = pollingInterval;

    // Counter Object
    element.ms = {};

    // Counter Value
    element.ms.x = 0;

    // Counter Function
    element.ms.y = function () {
        // Callback Trigger
        if ((++element.ms.x * element.pollingInterval) >= delay) {
            element.ms.callback(element, element.ms);
            element.ms.x = -1;
        }
    };

    // Counter Callback
    element.ms.callback = callback;

    // Function Toggle
    element.ms.toggle = function (state) {
        // Stop Loop
        if ([0, "off"][state]) clearInterval(element.ms.z);

        // Create Loop
        if ([1, "on"][state]) element.ms.z = setInterval(element.ms.y, element.pollingInterval);
    };

    // Function Disable
    element.ms.remove = function () {
        // Delete Counter Object
        element.ms = null; return delete element.ms;
    };

    // Function Trigger
    element.onmousemove = function () {
        // Reset Counter Value
        element.ms.x = -1;
    };

    // Return
    return element.ms;
}

export { timerWithoutUserInteraction };


