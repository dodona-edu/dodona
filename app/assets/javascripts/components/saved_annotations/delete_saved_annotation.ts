import { customElement, property } from "lit/decorators.js";
import { html, TemplateResult } from "lit";
import { ShadowlessLitElement } from "components/shadowless_lit_element";
import { deleteSavedAnnotation } from "state/SavedAnnotations";

@customElement("d-delete-saved-annotation")
export class DeleteSavedAnnotation extends ShadowlessLitElement {
    @property({ type: Number })
    savedAnnotationId: number;

    async deleteSavedAnnotation(): Promise<void> {
        if (confirm(I18n.t("js.saved_annotation.delete.confirm"))) {
            await deleteSavedAnnotation(this.savedAnnotationId);
        }
    }

    render(): TemplateResult {
        return html`
            <a class="btn btn-icon btn-icon-filled bg-danger"
               title="${I18n.t("js.saved_annotation.delete.button_title")}"
               @click=${() => this.deleteSavedAnnotation()}
            >
                <i class="mdi mdi-delete"></i>
            </a>`;
    }
}
