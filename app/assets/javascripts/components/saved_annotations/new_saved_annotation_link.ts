import { searchQueryState } from "state/SearchQuery";
import { updateURLParameter } from "utilities";
import { html, TemplateResult } from "lit";
import { customElement } from "lit/decorators.js";
import { DodonaElement } from "components/meta/dodona_element";

/**
 * This component represents a link to the new saved annotations page
 * It is responsible for adding the course_id and exercise_id query parameters to the link
 */
@customElement("d-new-saved-annotation-link")
export class NewSavedAnnotationLink extends DodonaElement {
    get courseId(): string {
        return searchQueryState.queryParams.get("course_id");
    }

    get exerciseId(): string {
        return searchQueryState.queryParams.get("exercise_id");
    }

    get path(): string {
        let path = "/saved_annotations/new";
        if (this.courseId) {
            path = updateURLParameter(path, "course_id", this.courseId);
        }
        if (this.exerciseId) {
            path = updateURLParameter(path, "exercise_id", this.exerciseId);
        }
        return path;
    }

    render(): TemplateResult {
        return html`
            <a href=${this.path} class="btn btn-fab hidden-print">
                <i class="mdi mdi-plus"></i>
            </a>
        `;
    }
}
