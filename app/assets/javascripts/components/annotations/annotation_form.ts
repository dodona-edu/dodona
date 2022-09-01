import { customElement, property } from "lit/decorators.js";
import { html, TemplateResult } from "lit";
import { ShadowlessLitElement } from "components/shadowless_lit_element";
import { Annotation } from "code_listing/annotation";
import { isBetaCourse } from "saved_annotation_beta";
import { watchMixin } from "components/watch_mixin";
import { createRef, Ref, ref } from "lit/directives/ref.js";
import "components/saved_annotations/saved_annotation_input";
import { unsafeHTML } from "lit/directives/unsafe-html.js";
import { getSavedAnnotation, SavedAnnotation } from "state/SavedAnnotations";

// Min and max of the annotation text is defined in the annotation model.
const maxLength = 10_000;

/**
 * This component represents a form for creating or editing saved annotations
 *
 * @element d-annotation-form
 *
 * @prop {Annotation} annotation - the annotation that will be edited (Null for a creation form)
 * @prop {Number} courseId - used to fetch saved annotations by course
 * @prop {Number} exerciseId - used to fetch saved annotations by exercise
 * @prop {Number} userId - used to fetch saved annotations by user
 * @prop {Boolean} questionMode - whether we are editing questions or userAnnotations
 * @prop {Boolean} disabled - disables all buttons
 * @prop {Boolean} hasErrors - Shows red validation styling
 *
 * @fires cancel - if a users uses the cancel button
 * @fires delete - if the user confirms after pressing the delete button
 * @fires submit - if the users presses the submit button, detail contains {text: string, savedAnnotationId: string}
 */
@customElement("d-annotation-form")
export class AnnotationForm extends watchMixin(ShadowlessLitElement) {
    @property({ type: Object })
    annotation: Annotation;
    @property({ type: Boolean })
    questionMode: boolean;
    @property({ type: Number, attribute: "course-id" })
    courseId: number;
    @property({ type: Number, attribute: "exercise-id" })
    exerciseId: number;
    @property({ type: Number, attribute: "user-id" })
    userId: number;
    @property({ type: Boolean })
    disabled = false;
    @property({ type: Boolean, attribute: "has-errors" })
    hasErrors = false;

    @property({ state: true })
    annotationText = "";
    @property({ state: true })
    savedAnnotationId = "";
    @property({ state: true })
    savedAnnotationTitle: string;
    @property({ state: true })
    saveAnnotation = false;

    inputRef: Ref<HTMLTextAreaElement> = createRef();

    watch = {
        annotation: () => {
            this.annotationText = this.annotation?.rawText;
            this.savedAnnotationId = this.annotation?.savedAnnotationId?.toString() || "";
        }
    };

    get type(): string {
        return this.questionMode ? "user_question" : "user_annotation";
    }

    get rows(): number {
        return Math.max(3, this.annotationText.split("\n").length + 1);
    }

    handleSavedAnnotationInput(e: CustomEvent): void {
        if (e.detail.text) {
            this.annotationText = e.detail.text;
        }
        this.savedAnnotationId = e.detail.id;
    }

    handleTextInput(): void {
        this.annotationText = this.inputRef.value.value;
    }

    handleCancel(): void {
        const event = new CustomEvent("cancel", { bubbles: true, composed: true });
        this.dispatchEvent(event);
    }

    handleDelete(): void {
        const confirmText = I18n.t(`js.${this.type}.delete_confirm`);
        if (confirm(confirmText)) {
            const event = new CustomEvent("delete", { bubbles: true, composed: true });
            this.dispatchEvent(event);
        }
    }

    handleSubmit(): void {
        if (!this.disabled) {
            this.hasErrors = false;
            this.disabled = true;

            if (!this.inputRef.value.reportValidity()) {
                return; // Something is wrong, abort.
            }

            const event = new CustomEvent("submit", {
                detail: {
                    text: this.annotationText,
                    savedAnnotationId: this.savedAnnotationId,
                    savedAnnotationTitle: this.savedAnnotationTitle,
                    saveAnnotation: this.saveAnnotation,
                },
                bubbles: true,
                composed: true
            });
            this.dispatchEvent(event);
        }
    }

    handleKeyDown(e: KeyboardEvent): boolean {
        if (e.code === "Enter" && e.shiftKey) {
            // Send using Shift-Enter.
            e.preventDefault();
            this.handleSubmit();
            return false;
        } else if (e.code === "Escape") {
            // Cancel using ESC.
            e.preventDefault();
            this.handleCancel();
            return false;
        }
    }

    handleUpdateTitle(e: Event): void {
        this.savedAnnotationTitle = (e.target as HTMLInputElement).value;
        e.stopPropagation();
    }

    firstUpdated(): void {
        this.inputRef.value.focus();
    }

    toggleSaveAnnotation(): void {
        this.saveAnnotation = !this.saveAnnotation;
        if (this.saveAnnotation && !this.savedAnnotationTitle) {
            // Take the first five words, with a max of 40 chars as default title
            this.savedAnnotationTitle = this.annotationText.split(/\s+/).slice(0, 5).join(" ").slice(0, 40);
        }
    }

    render(): TemplateResult {
        const form = html`
            <form class="annotation-submission form">
                ${this.questionMode || /* REMOVE AFTER CLOSED BETA */ !isBetaCourse(this.courseId) ? "" : html`
                        <d-saved-annotation-input
                            name="saved_annotation_id"
                            course-id="${this.courseId}"
                            exercise-id="${this.exerciseId}"
                            user-id="${this.userId}"
                            class="saved-annotation-input"
                            .value=${this.savedAnnotationId}
                            annotation-text="${this.annotationText}"
                            @input="${e => this.handleSavedAnnotationInput(e)}"
                        ></d-saved-annotation-input>
                    `}
                <div class="field form-group">
                    <label class="form-label">
                        ${I18n.t("js.user_annotation.fields.annotation_text")}
                    </label>
                    <textarea autofocus
                              required
                              class="form-control annotation-submission-input ${this.hasErrors ? "validation-error" : ""}"
                              .rows=${this.rows}
                              minlength="1"
                              .maxlength=${maxLength}
                              .value=${this.annotationText}
                              ${ref(this.inputRef)}
                              @keydown="${e => this.handleKeyDown(e)}"
                              @input="${() => this.handleTextInput()}"
                    ></textarea>
                    <div class="clearfix annotation-help-block">
                        <span class='help-block'>${unsafeHTML(I18n.t("js.user_annotation.help"))}</span>
                        ${this.questionMode ? html`
                            <span class='help-block'>${I18n.t("js.user_annotation.help_student")}</span>
                        ` : ""}
                        <span class="help-block float-end">
                            <span class="used-characters">${I18n.numberToDelimited(this.annotationText.length)}</span> / ${I18n.numberToDelimited(maxLength)}
                        </span>
                    </div>
                </div>
                <div class="field form-group">
                    <div class="form-check">
                        <input class="form-check-input" type="checkbox" @click="${() => this.toggleSaveAnnotation()}" id="check-save-annotation">
                        <label class="form-check-label" for="check-save-annotation">
                            ${I18n.t("js.user_annotation.fields.saved_annotation_title")}
                        </label>
                    </div>
                </div>
                ${ this.saveAnnotation ? html`
                    <div class="field form-group">
                        <label class="form-label">
                            ${I18n.t("js.saved_annotation.title")}
                        </label>
                        <input required="required" class="form-control" type="text"
                               @change=${e => this.handleUpdateTitle(e)} value=${this.savedAnnotationTitle}>
                    </div>
                ` : html``}
                <div class="annotation-submission-button-container">
                    ${this.annotation && this.annotation.removable ? html`
                        <button class="btn btn-text annotation-control-button annotation-delete-button"
                                type="button"
                                @click="${() => this.handleDelete()}"
                                .disabled=${this.disabled}
                        >
                           ${I18n.t("js.user_annotation.delete")}
                        </button>
                    ` : ""}
                    <button class="btn btn-text annotation-control-button annotation-cancel-button"
                            type="button"
                            @click="${() => this.handleCancel()}"
                            .disabled=${this.disabled}
                    >
                        ${I18n.t("js.user_annotation.cancel")}
                    </button>
                    <button class="btn btn-filled annotation-control-button annotation-submission-button"
                            type="button"
                            @click="${() => this.handleSubmit()}"
                            .disabled=${this.disabled}
                    >
                        ${this.annotation !== undefined ? I18n.t(`js.${this.type}.update`) : I18n.t(`js.${this.type}.send`)}
                    </button>
                </div>
            </form>
        `;

        return this.annotation !== undefined ? form : html`
            <div class="annotation user">
                ${form}
            </div>
        `;
    }
}
