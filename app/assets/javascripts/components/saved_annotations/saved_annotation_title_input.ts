import { customElement, property } from "lit/decorators.js";
import { html, TemplateResult } from "lit";
import { savedAnnotationState } from "state/SavedAnnotations";
import { exerciseState } from "state/Exercises";
import { courseState } from "state/Courses";
import { DodonaElement } from "components/meta/dodona_element";
import { i18n } from "i18n/i18n";

@customElement("d-saved-annotation-title-input")
export class SavedAnnotationTitleInput extends DodonaElement {
    @property({ type: String })
    value: string;
    @property({ type: Number, attribute: "saved-annotation-id" })
    savedAnnotationId: number;
    @property({ type: Number, attribute: "exercise-id" })
    exerciseId: number = exerciseState.id;
    @property({ type: Number, attribute: "course-id" })
    courseId: number = courseState.id;

    @property({ state: true })
    _value: string;

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
                ${i18n.t("js.saved_annotation.title_taken")}
            </div>
        `;
    }
}
