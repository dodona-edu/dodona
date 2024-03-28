import { customElement } from "lit/decorators.js";
import { html, TemplateResult } from "lit";
import { Pagination, SavedAnnotation, savedAnnotationState } from "state/SavedAnnotations";
import "components/pagination";
import { searchQueryState } from "state/SearchQuery";
import { DodonaElement } from "components/meta/dodona_element";
import { i18n } from "i18n/i18n";

/**
 * This component represents a list of saved annotations
 *
 * @element d-saved-annotation-list
 */
@customElement("d-saved-annotation-list")
export class SavedAnnotationList extends DodonaElement {
    get queryParams(): Map<string, string> {
        return searchQueryState.queryParams;
    }

    get arrayQueryParams(): Map<string, string[]> {
        return searchQueryState.arrayQueryParams;
    }

    lastSavedAnnotations: SavedAnnotation[] = [];
    get savedAnnotations(): SavedAnnotation[] {
        const savedAnnotations = savedAnnotationState.getList(this.queryParams, this.arrayQueryParams);
        if (savedAnnotations === undefined) {
            // return last saved annotations if the updated list is not yet available
            return this.lastSavedAnnotations;
        }
        this.lastSavedAnnotations = savedAnnotations;
        return savedAnnotations;
    }

    lastPagination: Pagination = { current_page: 1, total_pages: 1 };
    get pagination(): Pagination {
        const pagination = savedAnnotationState.getPagination(this.queryParams, this.arrayQueryParams);
        if (pagination === undefined) {
            // return last pagination if the updated pagination is not yet available
            return this.lastPagination;
        }
        this.lastPagination = pagination;
        return pagination;
    }

    render(): TemplateResult {
        return this.savedAnnotations.length > 0 ? html`
            <div class="table-scroll-wrapper">
                <table class="table table-index table-resource">
                    <thead>
                        <th title="${i18n.t("js.saved_annotation.annotations_count")}">
                            <d-sort-button column="annotations_count" default="DESC">#</d-sort-button>
                        </th>
                        <th>
                            <d-sort-button column="title">
                                ${i18n.t("js.saved_annotation.title")}
                            </d-sort-button>
                        </th>
                        <th>
                            <d-sort-button column="annotation_text">
                                ${i18n.t("js.saved_annotation.annotation_text")}
                            </d-sort-button>
                        </th>
                        <th>${i18n.t("js.saved_annotation.course")}</th>
                        <th>${i18n.t("js.saved_annotation.exercise")}</th>
                        <th></th>
                    </thead>
                    <tbody>
                        ${this.savedAnnotations.map(sa => html`
                            <tr>
                                <td>${sa.annotations_count}</td>
                                <td class="ellipsis-overflow" title="${sa.title}">
                                    <a href="${sa.url}">${sa.title}</a>
                                </td>
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
