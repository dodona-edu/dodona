import { customElement, property } from "lit/decorators.js";
import { html, TemplateResult } from "lit";
import { ShadowlessLitElement } from "components/shadowless_lit_element";
import { SavedAnnotation, updateSavedAnnotation, deleteSavedAnnotation } from "state/SavedAnnotations";
import "./saved_annotation_form";
import { modalMixin } from "components/modal_mixin";

/**
 * This component represents an edit button for a saved annotation
 * It also contains the edit form within a modal, which will be shown upon clicking the button
 *
 * @element d-edit-saved-annotation
 *
 * @prop {SavedAnnotation} savedAnnotation - the saved annotation to be edited
 */
@customElement("d-edit-saved-annotation")
export class EditSavedAnnotation extends modalMixin(ShadowlessLitElement) {
    @property({ type: Object })
    savedAnnotation: SavedAnnotation;

    @property({ state: true })
    errors: string[];

    async updateSavedAnnotation(): Promise<void> {
        try {
            await updateSavedAnnotation(this.savedAnnotation.id, {
                saved_annotation: this.savedAnnotation
            });
            this.errors = undefined;
            this.hideModal();
        } catch (errors) {
            this.errors = errors;
        }
    }

    async deleteSavedAnnotation(): Promise<void> {
        if (confirm(I18n.t("js.saved_annotation.delete.confirm"))) {
            await deleteSavedAnnotation(this.savedAnnotation.id);
            this.hideModal();
        }
    }

    get filledModalTemplate(): TemplateResult {
        return this.modalTemplate(html`
            ${I18n.t("js.saved_annotation.edit.title")}</h4>
        `, html`
            ${this.errors !== undefined ? html`
                <div class="callout callout-danger">
                    <h4>${I18n.t("js.saved_annotation.edit.errors", { count: this.errors.length })}</h4>
                    <ul>
                        ${this.errors.map(error => html`
                            <li>${error}</li>`)}
                    </ul>
                </div>
            ` : ""}
            <d-saved-annotation-form
                .savedAnnotation=${this.savedAnnotation}
                @change=${e => this.savedAnnotation = e.detail}
            ></d-saved-annotation-form>
        `, html`
            <d-delete-saved-annotation .savedAnnotationId=${this.savedAnnotation.id}></d-delete-saved-annotation>
            <button class="btn btn-danger btn-text" @click=${() => this.deleteSavedAnnotation()}>
                ${I18n.t("js.saved_annotation.edit.delete")}
            </button>
            <button class="btn btn-primary btn-text" @click=${() => this.hideModal()}>
                ${I18n.t("js.saved_annotation.edit.cancel")}
            </button>
            <button class="btn btn-primary" @click=${() => this.updateSavedAnnotation()}>
                ${I18n.t("js.saved_annotation.edit.save")}
            </button>
        `);
    }

    render(): TemplateResult {
        return html`
            <a class="btn btn-icon"
               title="${I18n.t("js.saved_annotation.edit.button_title")}"
               @click=${() => this.showModal()}
            >
                <i class="mdi mdi-pencil"></i>
            </a>`;
    }
}
