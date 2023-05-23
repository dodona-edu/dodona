import { customElement, property } from "lit/decorators.js";
import { html, TemplateResult } from "lit";
import { ShadowlessLitElement } from "components/shadowless_lit_element";
import { getSavedAnnotation, SavedAnnotation } from "state/SavedAnnotations";
import "./saved_annotation_form";
import { stateMixin } from "state/StateMixin";

/**
 * Shows a link icon with some info on hover about the linked saved annotation
 *
 * @element d-saved-annotation-icon
 *
 * @prop {Number} savedAnnotationId - the id of the saved annotation
 */
@customElement("d-saved-annotation-icon")
export class SavedAnnotationIcon extends stateMixin(ShadowlessLitElement) {
    @property({ type: Number, attribute: "saved-annotation-id" })
    savedAnnotationId: number;

    get isAlreadyLinked(): boolean {
        return this.savedAnnotationId != undefined;
    }

    get state(): string[] {
        return this.isAlreadyLinked ? [`getSavedAnnotation${this.savedAnnotationId}`] : [];
    }

    get savedAnnotation(): SavedAnnotation {
        return getSavedAnnotation(this.savedAnnotationId);
    }

    render(): TemplateResult {
        return this.isAlreadyLinked && this.savedAnnotation!= undefined ? html`
            <i class="mdi mdi-link-variant mdi-18 annotation-meta-icon" title="${I18n.t("js.saved_annotation.new.linked", { title: this.savedAnnotation.title })}"></i>
        ` : html``;
    }
}
