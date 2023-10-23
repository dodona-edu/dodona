import { customElement, property } from "lit/decorators.js";
import { html, TemplateResult } from "lit";
import { ShadowlessLitElement } from "components/meta/shadowless_lit_element";
import { savedAnnotationState } from "state/SavedAnnotations";
import { exerciseState } from "state/Exercises";
import { courseState } from "state/Courses";

@customElement("d-saved-annotation-title-input")
export class SavedAnnotationTitleInput extends ShadowlessLitElement {
    @property({ type: String })
    accessor value: string;
    @property({ type: Number, attribute: "saved-annotation-id" })
    accessor savedAnnotationId: number;
    @property({ type: Number, attribute: "exercise-id" })
    accessor exerciseId: number = exerciseState.id;
    @property({ type: Number, attribute: "course-id" })
    accessor courseId: number = courseState.id;

    @property({ state: true })
    accessor _value: string;

    get isTitleTaken(): boolean {
        return savedAnnotationState.isTitleTaken(
            this._value ?? this.value, this.exerciseId, this.courseId, this.savedAnnotationId);
    }

    render(): TemplateResult {
        return html`<input required="required"
                           class="form-control ${this.isTitleTaken ? "is-invalid" : ""}"
                           type="text"
                           name="saved_annotation[title]"
                           .value=${this.value}
                           @input=${e => this._value = (e.target as HTMLInputElement).value}>
            <div class="invalid-feedback">
                ${I18n.t("js.saved_annotation.title_taken")}
            </div>
        `;
    }
}
