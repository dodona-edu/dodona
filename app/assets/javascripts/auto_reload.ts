/**
 * Class to call a callback n seconds after the last user interaction with a
 * certain element. To detect user interaction, the class listens to the
 * following events on the interaction element:
 *
 * - "mousemove", detects when the mouse moves inside the element
 * - "touchmove", detects when the user touches inside the element
 * - "scroll", detects when the element scrolls
 *
 * To prevent responding to too many events, they are throttled with requestAnimationFrame.
 */
export class InactiveTimeout {
    timout: number = 0;
    interactionElement: HTMLElement;
    callback: () => void;
    delay: number;
    listener: () => void;
    started: boolean = false;

    /**
     * Initialize an inactive timeout. This will not start the timers.
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
                clearTimeout(this.timout);
                this.startTimeout();
            });
        };
    }

    start(): void {
        if (this.started) {
            return;
        }
        this.started = true;
        this.interactionElement.addEventListener("mousemove", this.listener, { passive: true });
        this.interactionElement.addEventListener("touchmove", this.listener, { passive: true });
        window.addEventListener("scroll", this.listener, { passive: true });
        this.startTimeout();
    }

    end(): void {
        if (!this.started) {
            return;
        }
        this.started = false;
        this.endTimeout();
        this.interactionElement.removeEventListener("mousemove", this.listener);
        this.interactionElement.removeEventListener("touchmove", this.listener);
        window.removeEventListener("scroll", this.listener);
    }

    private startTimeout(): void {
        this.timout = window.setTimeout(() => {
            this.callback();
            this.startTimeout();
        }, this.delay);
    }

    private endTimeout(): void {
        window.clearTimeout(this.timout);
        this.timout = 0;
    }
}
