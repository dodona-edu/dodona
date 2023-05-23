import { customElement, property } from "lit/decorators.js";
import { html, TemplateResult } from "lit";
import { ShadowlessLitElement } from "components/shadowless_lit_element";
import { getSavedAnnotations, getSavedAnnotationsPagination, Pagination, SavedAnnotation } from "state/SavedAnnotations";
import { stateMixin } from "state/StateMixin";
import "./edit_saved_annotation";
import "components/pagination";
import { getArrayQueryParams, getQueryParams } from "state/SearchQuery";

/**
 * This component represents a list of saved annotations
 *
 * @element d-saved-annotation-list
 *
 * @prop {Number} courseId - used to fetch saved annotations by course
 * @prop {Number} exerciseId - used to fetch saved annotations by exercise
 * @prop {Number} userId - used to fetch saved annotations by user
 * @prop {Boolean} small - When present, less columns and rows will be displayed in the table
 */
@customElement("d-saved-annotation-list")
export class SavedAnnotationList extends stateMixin(ShadowlessLitElement) {
    @property({ type: Number, attribute: "course-id" })
    courseId: number;
    @property({ type: Number, attribute: "exercise-id" })
    exerciseId: number;
    @property({ type: Number, attribute: "user-id" })
    userId: number;
    @property({ type: Boolean })
    small = false;

    state = ["getSavedAnnotations", "getQueryParams", "getArrayQueryParams", "getSavedAnnotationsPagination"];

    get queryParams(): Map<string, string> {
        const params: Map<string, string> = getQueryParams();
        if (this.courseId) {
            params.set("course_id", this.courseId.toString());
        }
        if (this.exerciseId) {
            params.set("exercise_id", this.exerciseId.toString());
        }
        if (this.userId) {
            params.set("user_id", this.userId.toString());
        }
        if (this.small) {
            params.set("per_page", "10");
        }
        return params;
    }

    get arrayQueryParams(): Map<string, string[]> {
        return getArrayQueryParams();
    }

    get savedAnnotations(): SavedAnnotation[] {
        return getSavedAnnotations(this.queryParams, this.arrayQueryParams);
    }

    get pagination(): Pagination {
        return getSavedAnnotationsPagination(this.queryParams, this.arrayQueryParams);
    }

    render(): TemplateResult {
        return this.savedAnnotations.length > 0 ? html`
            <div class="table-scroll-wrapper">
                <table class="table table-index table-resource">
                    ${ this.small ? "" : html`
                        <thead>
                            <th>${I18n.t("js.saved_annotation.title")}</th>
                            <th>${I18n.t("js.saved_annotation.annotation_text")}</th>
                            <th>${I18n.t("js.saved_annotation.user")}</th>
                            <th>${I18n.t("js.saved_annotation.course")}</th>
                            <th>${I18n.t("js.saved_annotation.exercise")}</th>
                            <th></th>
                        </thead>
                    `}
                    <tbody>
                        ${this.savedAnnotations.map(sa => html`
                            <tr>
                                <td class="ellipsis-overflow" style="${this.small ? "max-width: 150px" : ""}" title="${sa.title}">
                                    ${sa.title}
                                    <p class="small text-muted">${I18n.t("js.saved_annotation.list.annotations_count", { count: sa.annotations_count })}</p>
                                </td>
                                ${ this.small ? "" : html`
                                    <td class="ellipsis-overflow" title="${sa.annotation_text}">${sa.annotation_text}</td>
                                    <td><a href="${sa.user.url}">${sa.user.name}</a></td>
                                    <td><a href="${sa.course.url}">${sa.course.name}</a></td>
                                    <td><a href="${sa.exercise.url}">${sa.exercise.name}</a></td>
                                `}
                                <td class="actions">
                                    <d-edit-saved-annotation .savedAnnotation=${sa}></d-edit-saved-annotation>
                                </td>
                            </tr>
                        `)}
                    </tbody>
                </table>
            </div>
            <d-pagination .total=${this.pagination.total_pages} .current=${this.pagination.current_page} .small=${this.small}></d-pagination>
        ` : html``;
    }
}
