import { customElement, property } from "lit/decorators.js";
import { html, TemplateResult } from "lit";
import { ShadowlessLitElement } from "components/meta/shadowless_lit_element";
import { Pagination, SavedAnnotation, savedAnnotationState } from "state/SavedAnnotations";
import "./edit_saved_annotation";
import "components/pagination";
import { searchQueryState } from "state/SearchQuery";

/**
 * This component represents a list of saved annotations
 *
 * @element d-saved-annotation-list
 */
@customElement("d-saved-annotation-list")
export class SavedAnnotationList extends ShadowlessLitElement {
    get queryParams(): Map<string, string> {
        return searchQueryState.queryParams;
    }

    get arrayQueryParams(): Map<string, string[]> {
        return searchQueryState.arrayQueryParams;
    }

    get savedAnnotations(): SavedAnnotation[] {
        return savedAnnotationState.getList(this.queryParams, this.arrayQueryParams);
    }

    get pagination(): Pagination {
        return savedAnnotationState.getPagination(this.queryParams, this.arrayQueryParams);
    }

    render(): TemplateResult {
        return this.savedAnnotations.length > 0 ? html`
            <div class="table-scroll-wrapper">
                <table class="table table-index table-resource">
                    <thead>
                        <th title="${I18n.t("js.saved_annotation.annotations_count")}">#</th>
                        <th>${I18n.t("js.saved_annotation.title")}</th>
                        <th>${I18n.t("js.saved_annotation.annotation_text")}</th>
                        <th>${I18n.t("js.saved_annotation.course")}</th>
                        <th>${I18n.t("js.saved_annotation.exercise")}</th>
                        <th></th>
                    </thead>
                    <tbody>
                        ${this.savedAnnotations.map(sa => html`
                            <tr>
                                <td>${sa.annotations_count}</td>
                                <td class="ellipsis-overflow" title="${sa.title}">${sa.title}</td>
                                <td class="ellipsis-overflow" title="${sa.annotation_text}">${sa.annotation_text}</td>
                                <td><d-filter-button param="course_id" value="${sa.course.id}">${sa.course.name}</td></td>
                                <td><d-filter-button param="exercise_id" value="${sa.exercise.id}">${sa.exercise.name}</td></td>
                            </tr>
                        `)}
                    </tbody>
                </table>
            </div>
            <d-pagination .total=${this.pagination.total_pages} .current=${this.pagination.current_page}></d-pagination>
        ` : html``;
    }
}
