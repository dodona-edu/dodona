import { updateArrayURLParameter, updateURLParameter, fetch, createDelayer } from "utilities";
import { MapWithDefault } from "map_with_default";
import { userAnnotationState } from "state/UserAnnotations";
import { State } from "state/state_system/State";
import { stateProperty } from "state/state_system/StateProperty";
import { StateMap } from "state/state_system/StateMap";

export type SavedAnnotation = {
    annotations_count?: number;
    title: string,
    id: number,
    annotation_text: string,
    url?: string,
    user?: { name: string, url: string, id: number },
    exercise?: { name: string, url: string, id: number },
    course?: { name: string, url: string, id: number }
};
export type Pagination = { total_pages: number, current_page: number };
const URL = "/saved_annotations";

type Delayer = (f: () => void, ms: number) => void;
const delayerByURL = new MapWithDefault<string, Delayer>(createDelayer);
const delayerByID = new MapWithDefault<number, Delayer>(createDelayer);

function addParametersToUrl(url: string, params?: Map<string, string>, arrayParams?: Map<string, string[]>): string {
    let result = url;
    params?.forEach((v, k) => result = updateURLParameter(result, k, v));
    arrayParams?.forEach((v, k) => result = updateArrayURLParameter(result, k, v));
    return result;
}

class SavedAnnotationState extends State {
    @stateProperty private listByURL = new StateMap<string, SavedAnnotation[]>();
    @stateProperty private paginationByURL = new StateMap<string, Pagination>();
    @stateProperty private byId = new StateMap<number, SavedAnnotation>();

    private async fetchList(url: string): Promise<Array<SavedAnnotation>> {
        const response = await fetch(url);
        this.listByURL.set(url, await response.json());
        this.paginationByURL.set(url, JSON.parse(response.headers.get("X-Pagination")));
        return this.listByURL.get(url);
    }

    private async fetch(id: number): Promise<SavedAnnotation> {
        const url = `${URL}/${id}.json`;
        const response = await fetch(url);
        this.byId.set(id, await response.json());
        return this.byId.get(id);
    }

    async create(data: { from: number, saved_annotation: { title: string, annotation_text: string } }): Promise<number> {
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
        this.invalidate(savedAnnotation.id, savedAnnotation);
        userAnnotationState.invalidate(data.from);
        return savedAnnotation.id;
    }

    getList(params?: Map<string, string>, arrayParams?: Map<string, string[]>): Array<SavedAnnotation> | undefined {
        const url = addParametersToUrl(`${URL}.json`, params, arrayParams);
        delayerByURL.get(url)(() => {
            if (!this.listByURL.has(url)) {
                this.fetchList(url);
            }
        }, 200);
        return this.listByURL.get(url);
    }

    getPagination(params?: Map<string, string>, arrayParams?: Map<string, string[]>): Pagination {
        const url = addParametersToUrl(`${URL}.json`, params, arrayParams);
        delayerByURL.get(url)(() => {
            if (!this.paginationByURL.has(url)) {
                this.fetchList(url);
            }
        }, 200);
        return this.paginationByURL.get(url);
    }

    get(id: number): SavedAnnotation {
        delayerByID.get(id)(() => {
            if (!this.byId.has(id)) {
                this.fetch(id);
            }
        }, 200);
        return this.byId.get(id);
    }

    invalidate(id: number, replacement?: SavedAnnotation): void {
        if (!id) {
            return;
        }
        this.listByURL.clear();
        this.paginationByURL.clear();

        if (replacement) {
            this.byId.set(id, replacement);
        } else {
            this.byId.delete(id);
        }
    }

    isTitleTaken(title: string, exerciseId: number, courseId: number, userId: number, savedAnnotationId: number = undefined): boolean {
        const params = new Map([
            ["filter", title],
            ["exercise_id", exerciseId.toString()],
            ["course_id", courseId.toString()],
            ["user_id", userId.toString()],
        ]);
        const list = this.getList(params);
        return list?.find(annotation => annotation.title === title && annotation.id != savedAnnotationId) !== undefined;
    }
}

export const savedAnnotationState = new SavedAnnotationState();
