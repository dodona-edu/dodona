/*
 * Set up a repeating timer that call the given 'callback' every 'delay' seconds, but only when
 * there was no user interaction detected
 */
function timerWithoutUser(element, delay, cb): NodeJS.Timeout {
    let hasCursorMovement = false;
    const listener = (): void => {
        hasCursorMovement = true;
    };
    element.addEventListener("mouseover", listener);

    const uponEndTimeout = (): void => {
        element.removeEventListener("mouseover", listener);
        requestAnimationFrame(() => {
            timerWithoutUser(element, delay, cb);
            if (!hasCursorMovement) {
                cb(element, delay);
                hasCursorMovement = false;
            }
        });
    };

    return setTimeout(uponEndTimeout, delay);
}

export { timerWithoutUser };
