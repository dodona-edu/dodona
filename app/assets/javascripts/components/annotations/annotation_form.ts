import { customElement, property } from "lit/decorators.js";
import { html, PropertyValues, TemplateResult } from "lit";
import { watchMixin } from "components/meta/watch_mixin";
import { createRef, Ref, ref } from "lit/directives/ref.js";
import "components/saved_annotations/saved_annotation_input";
import { unsafeHTML } from "lit/directives/unsafe-html.js";
import { annotationState } from "state/Annotations";
import { userAnnotationState } from "state/UserAnnotations";
import { savedAnnotationState } from "state/SavedAnnotations";
import { courseState } from "state/Courses";
import { exerciseState } from "state/Exercises";
import { DodonaElement } from "components/meta/dodona_element";
import { i18n } from "i18n/i18n";

// Min and max of the annotation text is defined in the annotation model.
const maxLength = 10_000;

/**
 * This component represents a form for creating or editing saved annotations
 *
 * @element d-annotation-form
 *
 * @prop {String} annotationText - the text of the annotation
 * @prop {String} savedAnnotationId - the id of the saved annotation
 * @prop {Boolean} disabled - disables all buttons
 * @prop {Boolean} hasErrors - Shows red validation styling
 * @prop {String} submitButtonText - the i18n key of the text for the submit button
 *
 * @fires cancel - if a users uses the cancel button
 * @fires submit - if the users presses the submit button, detail contains {text: string, savedAnnotationId: string}
 */
@customElement("d-annotation-form")
export class AnnotationForm extends watchMixin(DodonaElement) {
    @property({ type: String, attribute: "annotation-text" })
    annotationText: string;
    @property({ type: String, attribute: "saved-annotation-id" })
    savedAnnotationId: string;
    @property({ type: Boolean })
    disabled = false;
    @property({ type: Boolean, attribute: "has-errors" })
    hasErrors = false;
    @property({ type: String, attribute: "submit-button-text" })
    submitButtonText: string;

    @property({ state: true })
    _annotationText = "";
    @property({ state: true })
    _savedAnnotationId = "";
    @property({ state: true })
    _savedAnnotationTitle: string;
    @property({ state: true })
    _savedAnnotationSearchInput = "";
    @property({ state: true })
    saveAnnotation = false;

    get savedAnnotationTitle(): string {
        return this._savedAnnotationTitle || this._annotationText.split(/\s+/).slice(0, 5).join(" ").slice(0, 40);
    }

    set savedAnnotationTitle(title: string) {
        this._savedAnnotationTitle = title;
    }

    inputRef: Ref<HTMLTextAreaElement> = createRef();
    titleRef: Ref<HTMLInputElement> = createRef();

    watch = {
        annotationText: () => {
            this._annotationText = this.annotationText;
        },
        savedAnnotationId: () => {
            this._savedAnnotationId = this.savedAnnotationId || "";
        },
        saveAnnotation: () => {
            this.listenForCloseIfEmpty();
        },
        _annotationText: () => {
            this.listenForCloseIfEmpty();
        },
        _savedAnnotationSearchInput: () => {
            this.listenForCloseIfEmpty();
        }
    };

    get type(): string {
        return annotationState.isQuestionMode ? "user_question" : "user_annotation";
    }

    get rows(): number {
        return Math.max(3, this._annotationText.split("\n").length + 1);
    }


    /**
     * Event callback for when the user clicks anywhere on the page.
     * If the click is not on the annotation form or the annotation button, the annotation form is closed.
     * @param e The click event
     */
    static closeForm(e: MouseEvent): void {
        if (!(e.target as Element).closest("d-annotation-form") && !(e.target as Element).closest(".annotation-button")) {
            userAnnotationState.formShown = false;
            userAnnotationState.selectedRange = undefined;
        }
    }

    isListeningForClose = false;
    listenForClose(): void {
        if (!this.isListeningForClose) {
            document.addEventListener("click", AnnotationForm.closeForm);
            this.isListeningForClose = true;
        }
    }

    stopListeningForClose(): void {
        if (this.isListeningForClose) {
            document.removeEventListener("click", AnnotationForm.closeForm);
            this.isListeningForClose = false;
        }
    }

    get isEmpty(): boolean {
        return this._annotationText.length === 0 && !this.saveAnnotation && this._savedAnnotationSearchInput.length === 0;
    }

    listenForCloseIfEmpty(): void {
        if (this.isEmpty) {
            this.listenForClose();
        } else {
            this.stopListeningForClose();
        }
    }

    connectedCallback(): void {
        super.connectedCallback();
        this.listenForCloseIfEmpty();
    }

    disconnectedCallback(): void {
        super.disconnectedCallback();
        this.stopListeningForClose();
    }

    handleSavedAnnotationInput(e: CustomEvent): void {
        if (e.detail.text) {
            this._annotationText = e.detail.text;
        }
        this._savedAnnotationId = e.detail.id;
        this._savedAnnotationSearchInput = e.detail.title;
    }

    handleTextInput(): void {
        this._annotationText = this.inputRef.value.value;
    }

    handleCancel(): void {
        const event = new CustomEvent("cancel", { bubbles: true, composed: true });
        this.dispatchEvent(event);
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

            if (this.saveAnnotation && this.isTitleTaken &&
                !confirm(i18n.t("js.saved_annotation.confirm_title_taken"))) {
                this.disabled = false;
                return; // User cancelled.
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
        if (e.code === "Enter" && (e.shiftKey || e.ctrlKey)) {
            // Send using Shift-Enter or Ctrl-Enter.
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

    updated(changedProperties: PropertyValues): void {
        // Focus the newly shown title input if the user wants to save the annotation.
        if (changedProperties.has("saveAnnotation") && this.saveAnnotation) {
            this.titleRef.value.focus();
            this.titleRef.value.select();
        }
    }

    toggleSaveAnnotation(): void {
        this.saveAnnotation = !this.saveAnnotation;
    }

    get canSaveAnnotation(): boolean {
        return !annotationState.isQuestionMode;
    }

    get potentialSavedAnnotationsExist(): boolean {
        return (savedAnnotationState.getList(new Map([
            ["course_id", courseState.id.toString()],
            ["exercise_id", exerciseState.id.toString()]
        ])) || []).length > 0;
    }

    get isTitleTaken(): boolean {
        return savedAnnotationState.isTitleTaken(
            this.savedAnnotationTitle, exerciseState.id, courseState.id);
    }

    render(): TemplateResult {
        return html`
            <form class="annotation-submission form">
                <div class="row">
                    <div class="col-lg-${this.canSaveAnnotation && this.potentialSavedAnnotationsExist ? 8 : 12}">
                        <div class="field form-group">
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
                                <span class='help-block'>${unsafeHTML(i18n.t("js.user_annotation.help"))}</span>
                                ${annotationState.isQuestionMode ? html`
                                    <span class='help-block'>${unsafeHTML(i18n.t("js.user_annotation.help_student"))}</span>
                                ` : ""}
                                <span class="help-block float-end">
                                    <span class="used-characters">${i18n.formatNumber(this._annotationText.length)}</span> / ${i18n.formatNumber(maxLength)}
                                </span>
                            </div>
                        </div>
                    </div>
                    ${ this.canSaveAnnotation && this.potentialSavedAnnotationsExist ? html`
                        <div class="col-lg-4">
                            <d-saved-annotation-input
                                name="saved_annotation_id"
                                class="saved-annotation-input"
                                .value=${this._savedAnnotationId}
                                annotation-text="${this._annotationText}"
                                @input="${e => this.handleSavedAnnotationInput(e)}"
                                .disabled=${this.saveAnnotation}
                            ></d-saved-annotation-input>
                        </div>
                    ` : ""}
                </div>
                <div class="row mb-1">
                    <div class="col-xxl-8 align-items-center d-inline-flex">
                        ${ this.canSaveAnnotation && this._savedAnnotationId == "" ? html`
                            <div class="field form-group mb-0">
                                <div class="form-check save-annotation-check">
                                    <input class="form-check-input mt-2"
                                           type="checkbox"
                                           @click="${() => this.toggleSaveAnnotation()}"
                                           id="check-save-annotation"
                                           .checked=${this.saveAnnotation}
                                    >
                                    <label class="form-check-label mt-2" for="check-save-annotation">
                                        ${i18n.t("js.user_annotation.fields.saved_annotation_title")}
                                    </label>
                                </div>
                                ${this.saveAnnotation ? html`
                                    <div class="saved-annotation-title">
                                        <input required="required"
                                               class="form-control ${this.isTitleTaken ? "is-invalid" : ""}"
                                               type="text"
                                               ${ref(this.titleRef)}
                                               @keydown="${e => this.handleKeyDown(e)}"
                                               @input=${() => this.handleUpdateTitle()}
                                               value=${this.savedAnnotationTitle}
                                               id="saved-annotation-title"
                                               title="${this.isTitleTaken ? i18n.t("js.saved_annotation.title_taken") : ""}"
                                        >
                                        <label for="saved-annotation-title">${i18n.t("js.saved_annotation.title")}:</label>
                                    </div>
                                `: ""}
                            </div>
                        ` : ""}
                    </div>
                    <div class="col-xxl-4 mt-2 mt-xxl-0" style="text-align: right">
                        <button class="btn btn-text"
                                type="button"
                                @click="${() => this.handleCancel()}"
                                .disabled=${this.disabled}
                        >
                            ${i18n.t("js.user_annotation.cancel")}
                        </button>
                        <button class="btn btn-filled"
                                type="button"
                                @click="${() => this.handleSubmit()}"
                                .disabled=${this.disabled}
                        >
                            ${i18n.t(`js.${this.type}.${this.submitButtonText}`)}
                        </button>
                    </div>
                </div>
            </form>
        `;
    }
}
