import { customElement, property } from "lit/decorators.js";
import { html, TemplateResult } from "lit";
import { SavedAnnotation, savedAnnotationState } from "state/SavedAnnotations";
import { DodonaElement } from "components/meta/dodona_element";
import { i18n } from "i18n/i18n";

/**
 * Shows a link icon with some info on hover about the linked saved annotation
 *
 * @element d-saved-annotation-icon
 *
 * @prop {Number} savedAnnotationId - the id of the saved annotation
 */
@customElement("d-saved-annotation-icon")
export class SavedAnnotationIcon extends DodonaElement {
    @property({ type: Number, attribute: "saved-annotation-id" })
    savedAnnotationId: number | null;

    get isAlreadyLinked(): boolean {
        return this.savedAnnotationId != undefined;
    }

    get savedAnnotation(): SavedAnnotation {
        return savedAnnotationState.get(this.savedAnnotationId);
    }

    render(): TemplateResult {
        return this.isAlreadyLinked && this.savedAnnotation!= undefined ? html`
            <a href="${this.savedAnnotation.url}" target="_blank">
                <i class="mdi mdi-comment-bookmark-outline mdi-18 annotation-meta-icon"
                   title="${i18n.t("js.saved_annotation.new.linked", { title: this.savedAnnotation.title })}"
                ></i>
            </a>
        ` : html``;
    }
}
