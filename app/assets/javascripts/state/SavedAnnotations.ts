import { events } from "state/PubSub";
import { updateURLParameter } from "util.js";

/**
 * This file contains all state management functions for saved annotations
 * It uses the PubSub system to make saved annotations responsive to changes
 * anyone subscribed to 'getSavedAnnotations' or `getSavedAnnotation${id}` should be notified if relevant changes happen
 *
 * This file is written in a way that should be applicable to all restfull resources for which we want to manage state in the frontend
 * It should probably be abstracted and or generalized instead of duplicated when another resource requires similar behaviour.
 */

export type SavedAnnotation = {title: string, id: number, annotation_text: string};
const URL = "/saved_annotations";

let fetchParams: Record<string, string>;
let savedAnnotations: SavedAnnotation[];
let savedAnnotationsById: Map<number, SavedAnnotation>;

function getHeaders(): Record<string, string> {
    return ({
        "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").getAttribute("content"),
        "Content-type": "application/json"
    });
}

export async function fetchSavedAnnotations(params?: Record<string, string>): Promise<Array<SavedAnnotation>> {
    if (params !== undefined) {
        fetchParams = params;
    }
    let url = `${URL}.json`;
    for (const param in fetchParams) {
        // eslint-disable-next-line no-prototype-builtins
        if (fetchParams.hasOwnProperty(param)) {
            url = updateURLParameter(url, param, fetchParams[param]);
        }
    }
    const response = await fetch(url);
    savedAnnotations = await response.json();
    events.publish("getSavedAnnotations");
    return savedAnnotations;
}

export async function fetchSavedAnnotation(id: number): Promise<SavedAnnotation> {
    const url = `${URL}/${id}.json`;
    const response = await fetch(url);
    savedAnnotationsById.set(id, await response.json());
    events.publish(`getSavedAnnotation${id}`);
    return savedAnnotationsById.get(id);
}

export async function createSavedAnnotation(data: { from: number, saved_annotation: SavedAnnotation} ): Promise<number> {
    const url = `${URL}.json`;
    const response = await fetch(url, {
        method: "post",
        body: JSON.stringify(data),
        headers: getHeaders(),
    });
    if (response.status === 422) {
        const errors = await response.json();
        throw errors;
    }
    const savedAnnotation: SavedAnnotation = await response.json();
    events.publish("fetchSavedAnnotations");
    events.publish(`fetchSavedAnnotation${savedAnnotation.id}`, savedAnnotation.id);
    return savedAnnotation.id;
}

export async function updateSavedAnnotation(id: number, data: {saved_annotation: SavedAnnotation}): Promise<void> {
    const url = `${URL}/${id}`;
    const response = await fetch(url, {
        method: "put",
        body: JSON.stringify(data),
        headers: getHeaders(),
    });
    if (response.status === 422) {
        const errors = await response.json();
        throw errors;
    }
    events.publish("fetchSavedAnnotations");
    events.publish(`fetchSavedAnnotation${id}`, id);
}

export async function deleteSavedAnnotation(id: number): Promise<void> {
    const url = `${URL}/${id}`;
    await fetch(url, {
        method: "delete",
        headers: getHeaders(),
    });
    events.publish("fetchSavedAnnotations");
    events.publish(`fetchSavedAnnotation${id}`, id);
}

export function getSavedAnnotations(params?: Record<string, string>): Array<SavedAnnotation> {
    if (savedAnnotations === undefined) {
        events.subscribe("fetchSavedAnnotations", fetchSavedAnnotations);
        fetchSavedAnnotations(params);
    }
    return savedAnnotations || [];
}

export function getSavedAnnotation(id: number): SavedAnnotation {
    if (!savedAnnotationsById.has(id)) {
        events.subscribe(`fetchSavedAnnotation${id}`, fetchSavedAnnotation);
        fetchSavedAnnotation(id);
    }
    return savedAnnotationsById.get(id);
}

