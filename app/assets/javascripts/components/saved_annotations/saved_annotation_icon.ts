import { customElement, property } from "lit/decorators.js";
import { html, TemplateResult } from "lit";
import { ShadowlessLitElement } from "components/meta/shadowless_lit_element";
import { SavedAnnotation, savedAnnotationState } from "state/SavedAnnotations";
import { isBetaCourse } from "saved_annotation_beta";

/**
 * Shows a link icon with some info on hover about the linked saved annotation
 *
 * @element d-saved-annotation-icon
 *
 * @prop {Number} savedAnnotationId - the id of the saved annotation
 */
@customElement("d-saved-annotation-icon")
export class SavedAnnotationIcon extends ShadowlessLitElement {
    @property({ type: Number, attribute: "saved-annotation-id" })
    savedAnnotationId: number | null;

    get isAlreadyLinked(): boolean {
        return this.savedAnnotationId != undefined;
    }

    get savedAnnotation(): SavedAnnotation {
        return savedAnnotationState.get(this.savedAnnotationId);
    }

    render(): TemplateResult {
        return isBetaCourse() && this.isAlreadyLinked && this.savedAnnotation!= undefined ? html`
            <a href="${this.savedAnnotation.url}" target="_blank">
                <i class="mdi mdi-comment-bookmark-outline mdi-18 annotation-meta-icon"
                   title="${I18n.t("js.saved_annotation.new.linked", { title: this.savedAnnotation.title })}"
                ></i>
            </a>
        ` : html``;
    }
}
