/**
 * heavily based on https://github.com/hankchizljaw/vanilla-js-state-management/blob/master/src/js/lib/pubsub.js
 * Copyright (c) 2018 Andy Bell
 *
 *
  */
export class PubSub {
    events: Map<string, Array<(...params: Array<any>) => any>>;

    constructor() {
        this.events = new Map<string, Array<(...params: Array<any>) => any>>();
    }

    /**
     * Either create a new event instance for passed `event` name
     * or push a new callback into the existing collection
     *
     * @param {string} event
     * @param {function} callback
     * @memberof PubSub
     */
    subscribe(event: string, callback: (...params: Array<any>) => any): void {
        // If there's not already an event with this name set in our collection
        // go ahead and create a new one and set it with an empty array, so we don't
        // have to type check it later down-the-line
        if (!this.events.has(event)) {
            this.events.set(event, []);
        }

        // We know we've got an array for this event, so push our callback in there with no fuss
        this.events.get(event).push(callback);
    }

    /**
     * If the passed event has callbacks attached to it, loop through each one
     * and call it
     *
     * @param {string} event
     * @param {array} params - function params
     * @memberof PubSub
     */
    publish(event: string, ...params: Array<any>): void {
        // There's no event to publish to, so bail out
        if (!this.events.has(event)) {
            return;
        }

        // Get each subscription and call its callback with the passed data
        this.events.get(event).map(callback => callback(...params));
    }
}

export const events = new PubSub();
