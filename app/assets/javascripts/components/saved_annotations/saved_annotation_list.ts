import { customElement, property } from "lit/decorators.js";
import { html, TemplateResult } from "lit";
import { ShadowlessLitElement } from "components/shadowless_lit_element";
import { getSavedAnnotations, SavedAnnotation } from "state/SavedAnnotations";
import { stateMixin } from "state/StateMixin";
import "./edit_saved_annotation";
import "./delete_saved_annotation";
import { getArrayQueryParams, getQueryParams } from "state/SearchQuery";

/**
 * This component represents a list of saved annotations
 *
 * @element d-saved-annotation-list
 *
 * @prop {Number} courseId - used to fetch saved annotations by course
 * @prop {Number} exerciseId - used to fetch saved annotations by exercise
 * @prop {Number} userId - used to fetch saved annotations by user
 */
@customElement("d-saved-annotation-list")
export class SavedAnnotationList extends stateMixin(ShadowlessLitElement) {
    @property({ type: Number, attribute: "course-id" })
    courseId: number;
    @property({ type: Number, attribute: "exercise-id" })
    exerciseId: number;
    @property({ type: Number, attribute: "user-id" })
    userId: number;
    @property({ type: Boolean, attribute: "use-query-params" })
    useQueryParams: boolean;

    state = ["getSavedAnnotations", "getQueryParams", "getArrayQueryParams"];

    get queryParams(): Map<string, string> {
        const params: Map<string, string> = this.useQueryParams ? getQueryParams() : new Map<string, string>();
        if (this.courseId) {
            params.set("course_id", this.courseId.toString());
        }
        if (this.exerciseId) {
            params.set("exercise_id", this.exerciseId.toString());
        }
        if (this.userId) {
            params.set("user_id", this.userId.toString());
        }
        return params;
    }

    get arrayQueryParams(): Map<string, string[]> {
        return this.useQueryParams ? getArrayQueryParams() : new Map<string, string[]>();
    }

    get savedAnnotations(): SavedAnnotation[] {
        return getSavedAnnotations(this.queryParams, this.arrayQueryParams);
    }

    render(): TemplateResult {
        return this.savedAnnotations.length > 0 ? html`
                <table class="table table-index table-resource">
                    <tbody>
                        ${this.savedAnnotations.map(sa => html`
                            <tr>
                                <td>${sa.title}</td>
                                <td class="actions">
                                    <d-edit-saved-annotation .savedAnnotation=${sa}></d-edit-saved-annotation>
                                    <d-delete-saved-annotation .savedAnnotationId=${sa.id}></d-delete-saved-annotation>
                                </td>
                            </tr>
                        `)}
                    </tbody>
                </table>
        ` : html``;
    }
}
