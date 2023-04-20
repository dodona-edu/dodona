import { customElement, property } from "lit/decorators.js";
import { ShadowlessLitElement } from "components/meta/shadowless_lit_element";
import { html, TemplateResult } from "lit";
import "./saved_annotation_list";
import { savedAnnotationState } from "state/SavedAnnotations";

/**
 * This component represents a list of saved annotations
 *
 * @element d-saved-annotations-sidecard
 *
 * @prop {Number} courseId - used to fetch saved annotations by course
 * @prop {Number} exerciseId - used to fetch saved annotations by exercise
 * @prop {Number} userId - used to fetch saved annotations by user
 */
@customElement("d-saved-annotations-sidecard")
export class SavedAnnotationList extends ShadowlessLitElement {
    @property({ type: Number, attribute: "course-id" })
    courseId: number;
    @property({ type: Number, attribute: "exercise-id" })
    exerciseId: number;
    @property({ type: Number, attribute: "user-id" })
    userId: number;

    get potentialSavedAnnotationsExist(): boolean {
        return savedAnnotationState.getList(new Map([
            ["course_id", this.courseId.toString()],
            ["exercise_id", this.exerciseId.toString()],
            ["user_id", this.userId.toString()]
        ])).length > 0;
    }

    render(): TemplateResult {
        return this.potentialSavedAnnotationsExist ? html`
            <div class="card">
                <div class="card-supporting-text">
                    <h4 class="ellipsis-overflow" title="${I18n.t("js.saved_annotation.sidecard.title")}">
                        ${I18n.t("js.saved_annotation.sidecard.title")}
                        <p class="small">
                            <a  href="/saved_annotations" target="_blank" >${I18n.t("js.saved_annotation.sidecard.link")}</a>
                        </p>
                    </h4>
                    <d-saved-annotation-list
                        .courseId=${this.courseId}
                        .exerciseId=${this.exerciseId}
                        .userId=${this.userId}
                        small
                    ></d-saved-annotation-list>
                </div>
            </div>
        ` : html``;
    }
}
