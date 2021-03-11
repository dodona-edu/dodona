/**
 * Class to repeatedly call a callback n ms after the last user interaction
 * with a certain element. To detect user interaction, the class listens to the
 * following events on the interaction element:
 *
 * - "mousemove", detects when the mouse moves inside the element
 * - "touchmove", detects when the user touches inside the element
 * - "scroll", detects when the element scrolls
 * - "onkeydown", when the user interacting with an input element
 *
 * To prevent responding to too many events, they are throttled with
 * `requestAnimationFrame`.
 *
 * Technically, each callback is scheduled with `setTimeout`. After each
 * callback, the next one is scheduled.
 *
 * Additionally, if the page in inactive, the callback will be called less
 * and less (the initial timeout plus a certain amount). Once the page is
 * active again, the timeout is reset. The detailed "algorithm" works as follows:
 *
 * 1. If the page is visible, the normal refresh rate is used in the
 *    scheduling of the next callback.
 * 2. If the document is "hidden" during the scheduling, the next callback
 *    is scheduled with the initial delay + 1s. For example, with an
 *    initial delay of 2, the next callback will be scheduled after 2s, 3s, 4s, ...
 *    This means the callback is called at 2s, 5s, 9s, 14s, etc.
 * 3. If the page is "hidden", an additional listener is registered. This
 *    will be called when the page becomes visible again. This listener
 *    will cancel the currently scheduled callback, do the callback, and
 *    schedule a new one.
 *
 * Relevant API's:
 * - https://developer.mozilla.org/en-US/docs/Web/API/Document/visibilityState
 * - https://developer.mozilla.org/en-US/docs/Web/API/Document/visibilitychange_event
 */
export class InactiveTimeout {
    /**
     * The timeout element (return value of setTimeout).
     * @private
     */
    private timeout: number = 0;
    private interactionElement: HTMLElement;
    private readonly callback: () => void;
    /**
     * The initial delay for the callback, i.e. every `delay` ms
     * the callback will be called.
     * @private
     */
    private readonly initialDelay: number;
    /**
     * How much ms the delay is increased if the page is inactive.
     * @private
     */
    private readonly inactiveIncrease: number = 1000;
    /**
     * The current delay.
     * @private
     */
    private delay: number;
    private readonly listener: () => void;
    private readonly activeListener: () => void;
    private started: boolean = false;

    /**
     * Initialize an inactive timeout. This will not start the timer.
     *
     * @param {HTMLElement} element The element for detecting user interaction.
     * @param {number} delay The delay in ms.
     * @param {function()} callback Function to call when the timout hits.
     */
    constructor(element: HTMLElement, delay: number, callback: () => void) {
        this.interactionElement = element;
        this.callback = callback;
        this.initialDelay = delay;
        this.delay = delay;

        this.listener = () => {
            requestAnimationFrame(() => {
                this.cancelScheduledExecution();
                this.scheduleExecution();
            });
        };

        this.activeListener = () => {
            // Only do stuff if we are visible again.
            if (document.visibilityState === "visible") {
                // Stop the current timeout.
                this.cancelScheduledExecution();
                // Do the callback now.
                this.callback();
                // Schedule again. The page should be active right now,
                // so it should reset the timeout.
                this.scheduleExecution();
            }
        };
    }

    /**
     * @return {boolean} True if the timer is running.
     */
    isStarted(): boolean {
        return this.started;
    }

    /**
     * Start the timer. Does nothing if they are already started.
     */
    start(): void {
        if (this.started) {
            return;
        }
        this.started = true;
        this.interactionElement.addEventListener("mousemove", this.listener, { passive: true });
        this.interactionElement.addEventListener("touchmove", this.listener, { passive: true });
        this.interactionElement.addEventListener("keydown", this.listener, { passive: true });
        document.addEventListener("scroll", this.listener, { passive: true });
        document.addEventListener("visibilitychange", this.activeListener);
        this.scheduleExecution();
    }

    /**
     * Stop the timer. Does nothing if already stopped.
     */
    end(): void {
        if (!this.started) {
            return;
        }
        this.started = false;
        this.cancelScheduledExecution();
        this.interactionElement.removeEventListener("mousemove", this.listener);
        this.interactionElement.removeEventListener("touchmove", this.listener);
        this.interactionElement.removeEventListener("keydown", this.listener);
        document.removeEventListener("scroll", this.listener);
        // Normally, the page is not hidden, but remove it to be safe.
        document.removeEventListener("visibilitychange", this.activeListener);
    }

    /**
     * Call start if stopped and end if started.
     */
    toggle(): void {
        if (this.started) {
            this.end();
        } else {
            this.start();
        }
    }

    private scheduleExecution(): void {
        if (document.visibilityState === "visible") {
            // Reset the delay to the initial state.
            this.delay = this.initialDelay;
        } else {
            // Increase the delay.
            this.delay = this.delay + this.inactiveIncrease;
        }

        this.timeout = window.setTimeout(() => {
            this.callback();
            this.scheduleExecution();
        }, this.delay);
    }

    private cancelScheduledExecution(): void {
        window.clearTimeout(this.timeout);
        this.timeout = 0;
    }
}
