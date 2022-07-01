import { customElement, property } from "lit/decorators.js";
import { html, TemplateResult } from "lit";
import { ShadowlessLitElement } from "components/shadowless_lit_element";
import "components/datalist_input";
import {getSavedAnnotation, getSavedAnnotations, SavedAnnotation} from "state/SavedAnnotations";
import { stateMixin } from "state/StateMixin";

/**
 * This component represents an input for a saved annotation id.
 * The saved annotation can be searched by title using a d-datalist-input.
 *
 * @element d-saved-annotation-input
 *
 * @prop {String} name - name of the input field (used in form submit)
 * @prop {Number} courseId - used to fetch saved annotations by course
 * @prop {Number} exerciseId - used to fetch saved annotations by exercise
 * @prop {Number} userId - used to fetch saved annotations by user
 * @prop {String} value - the initial saved annotation id
 * @prop {String} annotationText - the current text of the real annotation, used to detect if there are manual changes from the selected saved annotation
 *
 * @fires input - on value change, event details contain {title: string, id: string, annotation_text: string}
 */
@customElement("d-saved-annotation-input")
export class SavedAnnotationInput extends stateMixin(ShadowlessLitElement) {
    @property({ type: String })
    name = "";
    @property({ type: Number, attribute: "course-id" })
    courseId: number;
    @property({ type: Number, attribute: "exercise-id" })
    exerciseId: number;
    @property({ type: Number, attribute: "user-id" })
    userId: number;
    @property({ type: String })
    value: string;
    @property( { type: String, attribute: "annotation-text" })
    annotationText: string;

    @property({ state: true })
    __label: string;

    get state(): string[] {
        return this.value ? [`getSavedAnnotation${this.value}`, "getSavedAnnotations"] : ["getSavedAnnotations"];
    }

    get label(): string {
        return this.value ? getSavedAnnotation(parseInt(this.value))?.title : this.__label;
    }

    get savedAnnotations(): SavedAnnotation[] {
        return getSavedAnnotations(new Map([
            ["course_id", this.courseId.toString()],
            ["exercise_id", this.exerciseId.toString()],
            ["user_id", this.userId.toString()],
            ["filter", this.label]
        ]));
    }

    get selectedAnnotation(): SavedAnnotation {
        return this.savedAnnotations.find(sa => sa.id.toString() === this.value);
    }

    get options(): {label: string, value: string}[] {
        return this.savedAnnotations.map(sa => ({ label: sa.title, value: sa.id.toString(), extra: sa.annotation_text }));
    }

    get icon(): string {
        if (this.selectedAnnotation == undefined) {
            return "";
        }

        return this.selectedAnnotation.annotation_text === this.annotationText ? "equal" : "not-equal-variant";
    }

    processInput(e: CustomEvent): void {
        this.value = e.detail.value.toString();
        const annotation = this.selectedAnnotation;
        this.__label = e.detail.label;
        const event = new CustomEvent("input", {
            detail: { id: this.value, title: this.label, text: annotation?.annotation_text },
            bubbles: true,
            composed: true }
        );
        this.dispatchEvent(event);
        e.stopPropagation();
    }

    render(): TemplateResult {
        return html`
            <div class="position-relative">
                <d-datalist-input
                    name="${this.name}"
                    .options=${this.options}
                    value="${this.value}"
                    @input="${e => this.processInput(e)}"
                    placeholder="${I18n.t("js.saved_annotation.input.placeholder")}"
                ></d-datalist-input>
                ${ this.selectedAnnotation && this.selectedAnnotation.annotation_text !== this.annotationText ? html`
                    <i
                        class="mdi mdi-not-equal-variant colored-info position-absolute"
                        style="left: 165px; top: 3px;"
                        title="${I18n.t("js.saved_annotation.input.edited")}"
                    ></i>
                ` : ""}
            </div>
            <span class="help-block">
                <a  href="/saved_annotations" target="_blank">${I18n.t("js.saved_annotation.input.link")}</a>
            </span>
        `;
    }
}
