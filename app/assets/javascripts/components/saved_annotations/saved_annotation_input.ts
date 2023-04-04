import { customElement, property } from "lit/decorators.js";
import { html, TemplateResult } from "lit";
import { ShadowlessLitElement } from "components/meta/shadowless_lit_element";
import "components/datalist_input";
import { getSavedAnnotation, getSavedAnnotations, SavedAnnotation } from "state/SavedAnnotations";
import { stateMixin } from "state/StateMixin";
import { unsafeHTML } from "lit/directives/unsafe-html.js";
import { getUserId } from "state/Users";
import { courseState } from "state/Courses";
import { exerciseState } from "state/Exercises";

/**
 * This component represents an input for a saved annotation id.
 * The saved annotation can be searched by title using a d-datalist-input.
 *
 * @element d-saved-annotation-input
 *
 * @prop {String} name - name of the input field (used in form submit)
 * @prop {String} value - the initial saved annotation id
 * @prop {String} annotationText - the current text of the real annotation, used to detect if there are manual changes from the selected saved annotation
 *
 * @fires input - on value change, event details contain {title: string, id: string, annotation_text: string}
 */
@customElement("d-saved-annotation-input")
export class SavedAnnotationInput extends stateMixin(ShadowlessLitElement) {
    @property({ type: String })
    name = "";
    @property({ type: String })
    value: string;
    @property( { type: String, attribute: "annotation-text" })
    annotationText: string;

    @property({ state: true })
    __label: string;

    get state(): string[] {
        const state = ["getSavedAnnotations", "getUserId"];
        if (this.value) {
            state.push(`getSavedAnnotation${this.value}`);
        }
        return state;
    }

    get userId(): number {
        return getUserId();
    }

    get label(): string {
        return this.value ? getSavedAnnotation(parseInt(this.value))?.title : this.__label;
    }

    get savedAnnotations(): SavedAnnotation[] {
        return getSavedAnnotations(new Map([
            ["course_id", courseState.id.toString()],
            ["exercise_id", exerciseState.id.toString()],
            ["user_id", this.userId.toString()],
            ["filter", this.__label]
        ]));
    }

    get potentialSavedAnnotationsExist(): boolean {
        return getSavedAnnotations(new Map([
            ["course_id", courseState.id.toString()],
            ["exercise_id", exerciseState.id.toString()],
            ["user_id", this.userId.toString()]
        ])).length > 0;
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
        return this.potentialSavedAnnotationsExist ? html`
            <div class="field form-group">
                <label class="form-label">
                    ${I18n.t("js.saved_annotation.input.title")}
                </label>
                <div class="position-relative">
                    <d-datalist-input
                        name="${this.name}"
                        .options=${this.options}
                        .value=${this.value}
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
                <div class="help-block">
                    ${unsafeHTML(I18n.t("js.saved_annotation.input.help_html"))}
                </div>
            </div>
        ` : html``;
    }
}
