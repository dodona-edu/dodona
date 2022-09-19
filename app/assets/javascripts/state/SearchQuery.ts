import { searchQuery } from "search";
import { events } from "state/PubSub";

/**
 * This file wraps the searchQuery publication subscription system in the more general state events system
 */

const initialisedEvents = new Set<string>();

export function getQueryParams(): Map<string, string> {
    if (!initialisedEvents.has("getQueryParams")) {
        searchQuery.queryParams.subscribe(() => events.publish("getQueryParams"));
        initialisedEvents.add("getQueryParams");
    }
    return new Map(searchQuery.queryParams.params);
}

export function getArrayQueryParams(): Map<string, string[]> {
    if (!initialisedEvents.has("getArrayQueryParams")) {
        searchQuery.arrayQueryParams.subscribe(() => events.publish("getArrayQueryParams"));
        initialisedEvents.add("getArrayQueryParams");
    }
    return new Map(searchQuery.arrayQueryParams.params);
}

export function getQueryParam(key: string): string {
    if (!initialisedEvents.has(`getQueryParam${key}`)) {
        searchQuery.queryParams.subscribeByKey(key, () => events.publish(`getQueryParam${key}`));
        initialisedEvents.add(`getQueryParam${key}`);
    }
    return searchQuery.queryParams.params.get(key);
}

export function getArrayQueryParam(key: string): string[] {
    if (!initialisedEvents.has(`getArrayQueryParam${key}`)) {
        searchQuery.arrayQueryParams.subscribeByKey(key, () => events.publish(`getArrayQueryParam${key}`));
        initialisedEvents.add(`getArrayQueryParam${key}`);
    }
    return searchQuery.arrayQueryParams.params.get(key);
}
