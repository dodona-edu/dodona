import { customElement, property } from "lit/decorators.js";
import { html, TemplateResult } from "lit";
import { ShadowlessLitElement } from "components/shadowless_lit_element";
import { createSavedAnnotation, SavedAnnotation } from "state/SavedAnnotations";
import { ref } from "lit/directives/ref.js";
import { Modal } from "bootstrap";
import "./saved_annotation_form";

@customElement("d-new-saved-annotation")
export class NewSavedAnnotation extends ShadowlessLitElement {
    @property({ type: Number, attribute: "from-annotation-id" })
    fromAnnotationId: number;
    @property({ type: String, attribute: "annotation-text" })
    annotationText: string;

    @property({ state: true })
    errors: string[];

    savedAnnotation: SavedAnnotation;
    modal: Modal;

    get newSavedAnnotation(): SavedAnnotation {
        return {
            id: undefined,
            title: "",
            annotation_text: this.annotationText
        };
    }

    async createSavedAnnotation(): Promise<void> {
        try {
            await createSavedAnnotation({
                from: this.fromAnnotationId,
                saved_annotation: this.savedAnnotation
            });
            this.errors = undefined;
            this.modal?.hide();
        } catch (errors) {
            this.errors = errors;
        }
    }

    initModal(el: Element): void {
        if (!this.modal) {
            this.modal = new Modal(el);
        }
    }

    render(): TemplateResult {
        return html`
            <a class="btn btn-icon annotation-control-button annotation-edit"
               title="${I18n.t("js.saved_annotation.new.button_title")}"
               @click=${() => this.modal.show()}
            >
                <i class="mdi mdi-content-save"></i>
            </a>
            <div class="modal fade" ${ref(el => this.initModal(el))} tabindex="-1" role="dialog">
                <div class="modal-dialog" role="document">
                    <div class="modal-content">
                        <div class="modal-header">
                            <h4 class="modal-title">${I18n.t("js.saved_annotation.new.title")}</h4>
                            <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                        </div>
                        <div class="modal-body">
                            ${this.errors !== undefined ? html`
                                <div class="callout callout-danger">
                                    <h4>${I18n.t("js.saved_annotation.new.errors", { count: this.errors.length })}</h4>
                                    <ul>
                                        ${this.errors.map(error => html`<li>${error}</li>`)}
                                    </ul>
                                </div>
                            ` : ""}
                            <d-saved-annotation-form
                                .savedAnnotation=${this.newSavedAnnotation}
                                @change=${e => this.savedAnnotation = e.detail}
                            ></d-saved-annotation-form>
                        </div>
                        <div class="modal-footer">
                            <button class="btn btn-primary btn-text" @click=${() => this.createSavedAnnotation()}>
                                ${I18n.t("js.saved_annotation.new.save")}
                            </button>
                        </div>
                    </div>
                </div>
            </div>`;
    }
}
