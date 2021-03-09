import { InactiveTimeout } from "auto_reload";

let visibilityState = "visible";
Object.defineProperty(document, "visibilityState", {
    configurable: true,
    get() {
        return visibilityState;
    },
    set(v) {
        visibilityState = v;
    }
});

// Run frames immediately.
window.requestAnimationFrame = (callback => {
    callback(0);
    return 0;
});

beforeEach(() => {
    jest.useFakeTimers();
    document.body.innerHTML = `
        <div id="tracked">Test</div>
        <div id="untracked">Other</div>
        `;
});

afterEach(() => {
    jest.clearAllMocks();
    jest.clearAllTimers();
});

test("does not schedule before start", () => {
    const callback = jest.fn();
    const tracked = document.getElementById("tracked");
    const timeout = new InactiveTimeout(tracked, 2000, callback);
    jest.advanceTimersByTime(3000);
    expect(callback).not.toBeCalled();
    timeout.start();
    jest.advanceTimersByTime(2000);
    expect(callback).toBeCalledTimes(1);
    timeout.end();
    jest.advanceTimersByTime(2000);
    expect(callback).toBeCalledTimes(1);
});

test("callback is called", () => {
    const callback = jest.fn();
    const tracked = document.getElementById("tracked");
    const time = new InactiveTimeout(tracked, 2000, callback);
    time.start();
    jest.advanceTimersByTime(1000);
    expect(callback).not.toBeCalled();
    jest.advanceTimersByTime(2000);
    expect(callback).toBeCalled();
});

test("scrolling prevents callback", () => {
    const callback = jest.fn();
    const tracked = document.getElementById("tracked");
    const time = new InactiveTimeout(tracked, 2000, callback);
    time.start();
    jest.advanceTimersByTime(1000);
    expect(callback).not.toBeCalled();
    document.dispatchEvent(new window.Event("scroll"));
    jest.advanceTimersByTime(1500);
    expect(callback).not.toBeCalled();
    jest.advanceTimersByTime(1000);
    expect(callback).toBeCalled();
});

describe("backoff works", () => {
    test("hidden page uses backoff", () => {
        visibilityState = "hidden";
        const callback = jest.fn();
        const tracked = document.getElementById("tracked");
        const time = new InactiveTimeout(tracked, 2000, callback);
        time.start();
        Array.from(Array(5).keys()).forEach(() => {
            jest.runOnlyPendingTimers();
        });
        expect(callback).toHaveBeenCalledTimes(5);
        expect(setTimeout).toHaveBeenNthCalledWith(1, expect.any(Function), 3000);
        expect(setTimeout).toHaveBeenNthCalledWith(2, expect.any(Function), 4000);
        expect(setTimeout).toHaveBeenNthCalledWith(3, expect.any(Function), 5000);
        expect(setTimeout).toHaveBeenNthCalledWith(4, expect.any(Function), 6000);
        expect(setTimeout).toHaveBeenNthCalledWith(5, expect.any(Function), 7000);
    });
    test("visible page does not use backoff", () => {
        visibilityState = "visible";
        const callback = jest.fn();
        const tracked = document.getElementById("tracked");
        const time = new InactiveTimeout(tracked, 2000, callback);
        time.start();
        Array.from(Array(5).keys()).forEach(e => {
            jest.runOnlyPendingTimers();
            expect(callback).toHaveBeenCalledTimes(e + 1);
            expect(setTimeout).toHaveBeenLastCalledWith(expect.any(Function), 2000);
        });
    });
});
