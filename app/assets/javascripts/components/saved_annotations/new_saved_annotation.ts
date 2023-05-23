import { customElement, property } from "lit/decorators.js";
import { html, TemplateResult } from "lit";
import { ShadowlessLitElement } from "components/shadowless_lit_element";
import { createSavedAnnotation, getSavedAnnotation, SavedAnnotation } from "state/SavedAnnotations";
import "./saved_annotation_form";
import { modalMixin } from "components/modal_mixin";
import { stateMixin } from "state/StateMixin";

/**
 * This component represents an creation button for a saved annotation
 * It also contains the creation form within a modal, which will be shown upon clicking the button
 *
 * @element d-new-saved-annotation
 *
 * @prop {Number} fromAnnotationId - the id of the annotation which will be saved
 * @prop {String} annotationText - the original text of the annotation which wil be saved
 * @prop {Number} savedAnnotationId - the id of the saved annotation
 */
@customElement("d-new-saved-annotation")
export class NewSavedAnnotation extends stateMixin(modalMixin(ShadowlessLitElement)) {
    @property({ type: Number, attribute: "from-annotation-id" })
    fromAnnotationId: number;
    @property({ type: String, attribute: "annotation-text" })
    annotationText: string;
    @property({ type: Number, attribute: "saved-annotation-id" })
    savedAnnotationId: number;

    @property({ state: true })
    errors: string[];

    savedAnnotation: SavedAnnotation;

    get isAlreadyLinked(): boolean {
        return this.savedAnnotationId != undefined;
    }

    get state(): string[] {
        return this.isAlreadyLinked ? [`getSavedAnnotation${this.savedAnnotationId}`] : [];
    }

    get linkedSavedAnnotation(): SavedAnnotation {
        return getSavedAnnotation(this.savedAnnotationId);
    }

    get newSavedAnnotation(): SavedAnnotation {
        return {
            id: undefined,
            // Take the first five words, with a max of 40 chars as default title
            title: this.annotationText.split(/\s+/).slice(0, 5).join(" ").slice(0, 40),
            annotation_text: this.annotationText
        };
    }

    async createSavedAnnotation(): Promise<void> {
        try {
            this.savedAnnotationId = await createSavedAnnotation({
                from: this.fromAnnotationId,
                saved_annotation: this.savedAnnotation || this.newSavedAnnotation
            });
            this.errors = undefined;
            this.hideModal();
            const event = new CustomEvent("created", {
                detail: { id: this.savedAnnotationId },
                bubbles: true,
                composed: true }
            );
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
            ></d-saved-annotation-form>
        `, html`
            <button class="btn btn-primary btn-text" @click=${() => this.createSavedAnnotation()}>
                ${I18n.t("js.saved_annotation.new.save")}
            </button>
        `);
    }

    render(): TemplateResult {
        return this.isAlreadyLinked && this.linkedSavedAnnotation!= undefined ? html`` : html`
            <a class="btn btn-icon annotation-control-button annotation-edit"
               title="${I18n.t("js.saved_annotation.new.button_title")}"
               @click=${() => this.showModal()}
            >
                <i class="mdi mdi-content-save"></i>
            </a>`;
    }
}
