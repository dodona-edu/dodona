import { customElement, property } from "lit/decorators.js";
import { html, TemplateResult } from "lit";
import { ShadowlessLitElement } from "components/meta/shadowless_lit_element";
import { SavedAnnotation, savedAnnotationState } from "state/SavedAnnotations";
import "./saved_annotation_form";
import { modalMixin } from "components/modal_mixin";
import { exerciseState } from "state/Exercises";
import { courseState } from "state/Courses";
import { searchQueryState } from "state/SearchQuery";
import { updateURLParameter } from "utilities";

/**
 * This component represents an creation button for a saved annotation
 * It also contains the creation form within a modal, which will be shown upon clicking the button
 *
 * @element d-new-saved-annotation
 *
 * @prop {Number} fromAnnotationId - the id of the annotation which will be saved
 * @prop {String} annotationText - the original text of the annotation which wil be saved
 * @prop {Number} exerciseId - the id of the exercise to which the annotation belongs
 * @prop {Number} courseId - the id of the course to which the annotation belongs
 */
@customElement("d-new-saved-annotation")
export class NewSavedAnnotation extends modalMixin(ShadowlessLitElement) {
    @property({ type: Number, attribute: "from-annotation-id" })
    fromAnnotationId: number;
    @property({ type: String, attribute: "annotation-text" })
    annotationText: string;
    @property({ type: Number, attribute: "exercise-id" })
    exerciseId: number = exerciseState.id;
    @property({ type: Number, attribute: "course-id" })
    courseId: number = courseState.id;

    @property({ state: true })
    errors: string[];

    savedAnnotation: SavedAnnotation;

    get newSavedAnnotation(): SavedAnnotation {
        return {
            id: undefined,
            // Take the first five words, with a max of 40 chars as default title
            title: this.annotationText.split(/\s+/).slice(0, 5).join(" ").slice(0, 40),
            annotation_text: this.annotationText,
        };
    }

    get isTitleTaken(): boolean {
        const annotation = this.savedAnnotation || this.newSavedAnnotation;
        return savedAnnotationState.isTitleTaken(
            annotation.title, this.exerciseId, this.courseId);
    }

    async createSavedAnnotation(): Promise<void> {
        if (this.isTitleTaken && !confirm(I18n.t("js.saved_annotation.confirm_title_taken"))) {
            return;
        }

        try {
            await savedAnnotationState.create({
                from: this.fromAnnotationId,
                saved_annotation: this.savedAnnotation || this.newSavedAnnotation
            });
            this.errors = undefined;
            this.hideModal();
            const event = new CustomEvent("annotation-saved", { bubbles: true, composed: true });
            this.dispatchEvent(event);
        } catch (errors) {
            this.errors = errors;
        }
    }

    get filledModalTemplate(): TemplateResult {
        return this.modalTemplate(html`
            ${I18n.t("js.saved_annotation.new.title")}
        `, html`
            ${this.errors !== undefined ? html`
                <div class="callout callout-danger">
                    <h4>${I18n.t("js.saved_annotation.new.errors", { count: this.errors.length })}</h4>
                    <ul>
                        ${this.errors.map(error => html`
                            <li>${error}</li>`)}
                    </ul>
                </div>
            ` : ""}
            <d-saved-annotation-form
                .savedAnnotation=${this.newSavedAnnotation}
                @change=${e => this.savedAnnotation = e.detail}
                .courseId=${this.courseId}
                .exerciseId=${this.exerciseId}
            ></d-saved-annotation-form>
        `, html`
            <button class="btn btn-text" @click=${() => this.createSavedAnnotation()}>
                ${I18n.t("js.saved_annotation.new.save")}
            </button>
        `);
    }

    render(): TemplateResult {
        return html`
            <a @click="${() => this.showModal()}">
                <i class="mdi mdi-content-save mdi-18"></i>
                ${I18n.t("js.saved_annotation.new.button_title")}
            </a>
        `;
    }
}

export function initNewSavedAnnotationButtons(path: string): void {
    const newSavedAnnotationElements = document.querySelectorAll("d-new-saved-annotation");
    newSavedAnnotationElements.forEach((element: NewSavedAnnotation) => {
        element.addEventListener("annotation-saved", () => {
            // redirect to the saved annotation list
            window.location.href = path;
        });
    });
}
