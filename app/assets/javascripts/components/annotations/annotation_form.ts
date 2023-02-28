import { customElement, property } from "lit/decorators.js";
import { html, TemplateResult } from "lit";
import { ShadowlessLitElement } from "components/meta/shadowless_lit_element";
import { isBetaCourse } from "saved_annotation_beta";
import { watchMixin } from "components/meta/watch_mixin";
import { createRef, Ref, ref } from "lit/directives/ref.js";
import "components/saved_annotations/saved_annotation_input";
import { unsafeHTML } from "lit/directives/unsafe-html.js";
import { getCourseId } from "state/Courses";
import { stateMixin } from "state/StateMixin";
import { getQuestionMode } from "state/Annotations";

// Min and max of the annotation text is defined in the annotation model.
const maxLength = 10_000;

/**
 * This component represents a form for creating or editing saved annotations
 *
 * @element d-annotation-form
 *
 * @prop {Annotation} annotation - the annotation that will be edited (Null for a creation form)
 * @prop {Boolean} questionMode - whether we are editing questions or userAnnotations
 * @prop {Boolean} disabled - disables all buttons
 * @prop {Boolean} hasErrors - Shows red validation styling
 *
 * @fires cancel - if a users uses the cancel button
 * @fires delete - if the user confirms after pressing the delete button
 * @fires submit - if the users presses the submit button, detail contains {text: string, savedAnnotationId: string}
 */
@customElement("d-annotation-form")
export class AnnotationForm extends stateMixin(watchMixin(ShadowlessLitElement)) {
    @property({ type: String, attribute: "annotation-text" })
    annotationText: string;
    @property({ type: String, attribute: "saved-annotation-id" })
    savedAnnotationId: string;
    @property({ type: Boolean })
    removable = false;
    @property({ type: Boolean })
    disabled = false;
    @property({ type: Boolean, attribute: "has-errors" })
    hasErrors = false;

    @property({ state: true })
    _annotationText = "";
    @property({ state: true })
    _savedAnnotationId = "";
    @property({ state: true })
    savedAnnotationTitle: string;
    @property({ state: true })
    saveAnnotation = false;

    inputRef: Ref<HTMLTextAreaElement> = createRef();
    titleRef: Ref<HTMLInputElement> = createRef();

    watch = {
        annotationText: () => {
            this._annotationText = this.annotationText;
        },
        savedAnnotationId: () => {
            this._savedAnnotationId = this.savedAnnotationId || "";
        }
    };

    state = ["getCourseId"/* REMOVE AFTER CLOSED BETA */, "getQuestionMode"];

    /* REMOVE AFTER CLOSED BETA */
    get courseId(): number {
        return getCourseId();
    }

    get questionMode(): boolean {
        return getQuestionMode();
    }

    get type(): string {
        return this.questionMode ? "user_question" : "user_annotation";
    }

    get rows(): number {
        return Math.max(3, this._annotationText.split("\n").length + 1);
    }

    handleSavedAnnotationInput(e: CustomEvent): void {
        if (e.detail.text) {
            this._annotationText = e.detail.text;
        }
        this._savedAnnotationId = e.detail.id;
    }

    handleTextInput(): void {
        this._annotationText = this.inputRef.value.value;
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
                this.hasErrors = true;
                this.disabled = false;
                return; // Something is wrong, abort.
            }

            const event = new CustomEvent("submit", {
                detail: {
                    text: this._annotationText,
                    savedAnnotationId: this._savedAnnotationId,
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

    handleUpdateTitle(): void {
        this.savedAnnotationTitle = this.titleRef.value.value;
    }

    firstUpdated(): void {
        this.inputRef.value.focus();
    }

    toggleSaveAnnotation(): void {
        this.saveAnnotation = !this.saveAnnotation;
        if (this.saveAnnotation && !this.savedAnnotationTitle) {
            // Take the first five words, with a max of 40 chars as default title
            this.savedAnnotationTitle = this._annotationText.split(/\s+/).slice(0, 5).join(" ").slice(0, 40);
        }
    }

    render(): TemplateResult {
        const form = html`
            <form class="annotation-submission form">
                ${this.questionMode || /* REMOVE AFTER CLOSED BETA */ !isBetaCourse(this.courseId) ? "" : html`
                        <d-saved-annotation-input
                            name="saved_annotation_id"
                            class="saved-annotation-input"
                            .value=${this._savedAnnotationId}
                            annotation-text="${this._annotationText}"
                            @input="${e => this.handleSavedAnnotationInput(e)}"
                        ></d-saved-annotation-input>
                    `}
                <div class="field form-group">
                    ${ false ? html`<label class="form-label" for="annotation-text">
                        ${I18n.t("js.user_annotation.fields.annotation_text")}
                    </label>` : ""}
                    <textarea id="annotation-text"
                              autofocus
                              required
                              class="form-control annotation-submission-input ${this.hasErrors ? "validation-error" : ""}"
                              .rows=${this.rows}
                              minlength="1"
                              maxlength="${maxLength}"
                              .value=${this._annotationText}
                              ${ref(this.inputRef)}
                              @keydown="${e => this.handleKeyDown(e)}"
                              @input="${() => this.handleTextInput()}"
                    ></textarea>
                    <div class="clearfix annotation-help-block">
                        <span class='help-block'>${unsafeHTML(I18n.t("js.user_annotation.help"))}</span>
                        ${this.questionMode ? html`
                            <span class='help-block'>${unsafeHTML(I18n.t("js.user_annotation.help_student"))}</span>
                        ` : ""}
                        <span class="help-block float-end">
                            <span class="used-characters">${I18n.formatNumber(this._annotationText.length)}</span> / ${I18n.formatNumber(maxLength)}
                        </span>
                    </div>
                </div>
                ${this.questionMode || /* REMOVE AFTER CLOSED BETA */ !isBetaCourse(this.courseId) ? "" : html`
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
                            <label class="form-label" for="saved-annotation-title">
                                ${I18n.t("js.saved_annotation.title")}
                            </label>
                            <input required="required"
                                   class="form-control"
                                   type="text"
                                   ${ref(this.titleRef)}
                                   @keydown="${e => this.handleKeyDown(e)}"
                                   @input=${() => this.handleUpdateTitle()}
                                   value=${this.savedAnnotationTitle}
                                   id="saved-annotation-title"
                            >
                        </div>
                    ` : html``}
                `}
                <div class="annotation-submission-button-container">
                    ${this.annotationText && this.removable ? html`
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
                        ${this.annotationText ? I18n.t(`js.${this.type}.update`) : I18n.t(`js.${this.type}.send`)}
                    </button>
                </div>
            </form>
        `;

        return this.annotationText ? form : html`
            <div class="annotation ${this.questionMode ? "question" : "user" }">
                ${form}
            </div>
        `;
    }
}
