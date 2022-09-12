import { events } from "state/PubSub";
import { updateArrayURLParameter, updateURLParameter, fetch, createDelayer } from "util.js";
import { MapWithDefault } from "map_with_default";

/**
 * This file contains all state management functions for saved annotations
 * It uses the PubSub system to make saved annotations responsive to changes
 * anyone subscribed to 'getSavedAnnotations' or `getSavedAnnotation${id}` should be notified if relevant changes happen
 *
 * This file is written in a way that should be applicable to all restfull resources for which we want to manage state in the frontend
 * It should probably be abstracted and or generalized instead of duplicated when another resource requires similar behaviour.
 */

export type SavedAnnotation = {
    annotations_count?: number;
    title: string,
    id: number,
    annotation_text: string,
    user?: {name: string, url: string},
    exercise?: {name: string, url: string},
    course?: {name: string, url: string}
};
export type Pagination = { total_pages: number, current_page: number };
const URL = "/saved_annotations";

const savedAnnotationsByURL = new Map<string, SavedAnnotation[]>();
const savedAnnotationsPaginationByURL = new Map<string, Pagination>();
const savedAnnotationsById = new Map<number, SavedAnnotation>();

type Delayer = (f: ()=>void, ms: number)=>void;
const delayerByURL = new MapWithDefault<string, Delayer>(createDelayer);
const delayerByID = new MapWithDefault<number, Delayer>(createDelayer);

function addParametersToUrl(url: string, params?: Map<string, string>, arrayParams?: Map<string, string[]>): string {
    let result = url;
    params?.forEach((v, k) => result = updateURLParameter(result, k, v));
    arrayParams?.forEach((v, k) => result = updateArrayURLParameter(result, k, v));
    return result;
}

export async function fetchSavedAnnotations(params?: Map<string, string>, arrayParams?: Map<string, string[]>): Promise<Array<SavedAnnotation>> {
    const url = addParametersToUrl(`${URL}.json`, params, arrayParams);
    const response = await fetch(url);
    savedAnnotationsByURL.set(url, await response.json());
    savedAnnotationsPaginationByURL.set(url, JSON.parse(response.headers.get("X-Pagination")));
    events.publish("getSavedAnnotations");
    events.publish("getSavedAnnotationsPagination");
    return savedAnnotationsByURL.get(url);
}

export async function fetchSavedAnnotation(id: number): Promise<SavedAnnotation> {
    const url = `${URL}/${id}.json`;
    const response = await fetch(url);
    savedAnnotationsById.set(id, await response.json());
    events.publish(`getSavedAnnotation${id}`);
    return savedAnnotationsById.get(id);
}

export async function createSavedAnnotation(data: { from: number, saved_annotation: {title: string, annotation_text: string}} ): Promise<number> {
    const url = `${URL}.json`;
    const response = await fetch(url, {
        method: "post",
        body: JSON.stringify(data),
        headers: { "Content-type": "application/json" },
    });
    if (response.status === 422) {
        const errors = await response.json();
        throw errors;
    }
    const savedAnnotation: SavedAnnotation = await response.json();
    invalidateSavedAnnotation(savedAnnotation.id, savedAnnotation);
    return savedAnnotation.id;
}

export async function updateSavedAnnotation(id: number, data: {saved_annotation: SavedAnnotation}): Promise<void> {
    const url = `${URL}/${id}`;
    const response = await fetch(url, {
        method: "put",
        body: JSON.stringify(data),
        headers: { "Content-type": "application/json" },
    });
    if (response.status === 422) {
        const errors = await response.json();
        throw errors;
    }
    const savedAnnotation: SavedAnnotation = await response.json();
    invalidateSavedAnnotation(savedAnnotation.id, savedAnnotation);
}

export async function deleteSavedAnnotation(id: number): Promise<void> {
    const url = `${URL}/${id}`;
    await fetch(url, {
        method: "delete",
    });
    invalidateSavedAnnotation(id);
}

export function getSavedAnnotations(params?: Map<string, string>, arrayParams?: Map<string, string[]>): Array<SavedAnnotation> {
    const url = addParametersToUrl(`${URL}.json`, params, arrayParams);
    delayerByURL.get(url)(() => {
        if (!savedAnnotationsByURL.has(url)) {
            fetchSavedAnnotations(params, arrayParams);
        }
    }, 200);
    return savedAnnotationsByURL.get(url) || [];
}

export function getSavedAnnotationsPagination(params?: Map<string, string>, arrayParams?: Map<string, string[]>): Pagination {
    const url = addParametersToUrl(`${URL}.json`, params, arrayParams);
    delayerByURL.get(url)(() => {
        if (!savedAnnotationsPaginationByURL.has(url)) {
            fetchSavedAnnotations(params, arrayParams);
        }
    }, 200);
    return savedAnnotationsPaginationByURL.get(url);
}

export function getSavedAnnotation(id: number): SavedAnnotation {
    delayerByID.get(id)(() => {
        if (!savedAnnotationsById.has(id)) {
            fetchSavedAnnotation(id);
        }
    }, 200);
    return savedAnnotationsById.get(id);
}

export function invalidateSavedAnnotation(id: number, replacement?: SavedAnnotation): void {
    if (!id) {
        return;
    }
    savedAnnotationsByURL.clear();
    savedAnnotationsPaginationByURL.clear();
    events.publish("getSavedAnnotations");

    if (replacement) {
        savedAnnotationsById.set(id, replacement);
    } else {
        savedAnnotationsById.delete(id);
    }
    events.publish(`getSavedAnnotation${id}`, id);
}

