/**
 * Class to call a callback n seconds after the last user interaction with a
 * certain element. To detect user interaction, the class listens to the
 * following events on the interaction element:
 *
 * - "mousemove", detects when the mouse moves inside the element
 * - "touchmove", detects when the user touches inside the element
 * - "scroll", detects when the element scrolls
 * - "onkeydown", when the user interacting with an input element
 *
 * To prevent responding to too many events, they are throttled with requestAnimationFrame.
 */
export class InactiveTimeout {
    private timeout: number = 0;
    private interactionElement: HTMLElement;
    private readonly callback: () => void;
    private readonly delay: number;
    private readonly listener: () => void;
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
        this.delay = delay;

        this.listener = () => {
            requestAnimationFrame(() => {
                clearTimeout(this.timeout);
                this.startTimeout();
            });
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
        window.addEventListener("scroll", this.listener, { passive: true });
        this.startTimeout();
    }

    /**
     * Stop the timer. Does nothing if already stopped.
     */
    end(): void {
        if (!this.started) {
            return;
        }
        this.started = false;
        this.endTimeout();
        this.interactionElement.removeEventListener("mousemove", this.listener);
        this.interactionElement.removeEventListener("touchmove", this.listener);
        this.interactionElement.removeEventListener("keydown", this.listener);
        window.removeEventListener("scroll", this.listener);
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

    private startTimeout(): void {
        this.timeout = window.setTimeout(() => {
            this.callback();
            this.startTimeout();
        }, this.delay);
    }

    private endTimeout(): void {
        window.clearTimeout(this.timeout);
        this.timeout = 0;
    }
}
