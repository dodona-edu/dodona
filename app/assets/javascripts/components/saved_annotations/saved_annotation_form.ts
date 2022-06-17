import { customElement, property } from "lit/decorators.js";
import { html, TemplateResult } from "lit";
import { ShadowlessLitElement } from "components/shadowless_lit_element";
import { SavedAnnotation } from "state/SavedAnnotations";
import {unsafeHTML} from "lit/directives/unsafe-html.js";

@customElement("d-saved-annotation-form")
export class SavedAnnotationForm extends ShadowlessLitElement {
    @property({ type: Object })
    savedAnnotation: SavedAnnotation;

    savedAnnotationChanged(): void {
        const event = new CustomEvent("change", {
            detail: this.savedAnnotation,
            bubbles: true,
            composed: true }
        );
        this.dispatchEvent(event);
    }

    updateTitle(e: Event): void {
        this.savedAnnotation.title = (e.target as HTMLInputElement).value;
        e.stopPropagation();
        this.savedAnnotationChanged();
    }

    updateText(e: Event): void {
        this.savedAnnotation.annotation_text = (e.target as HTMLTextAreaElement).value;
        e.stopPropagation();
        this.savedAnnotationChanged();
    }

    render(): TemplateResult {
        return html`
            <form class="form">
                <div class="field form-group row">
                    <label class="col-sm-4 col-form-label">
                        ${I18n.t("js.saved_annotation.title")}
                    </label>
                    <div class="col-sm-8">
                        <input required="required" class="form-control" type="text"
                               .value=${this.savedAnnotation.title} @change=${e => this.updateTitle(e)}>
                    </div>
                </div>
                <div class="field form-group row">
                    <label class="col-sm-4 col-form-label">
                        ${I18n.t("js.saved_annotation.annotation_text")}
                    </label>
                    <div class="col-sm-8">
                        <textarea required="required" class="form-control" rows="4"
                                  .value=${this.savedAnnotation.annotation_text} @change=${e => this.updateText(e)}></textarea>
                    </div>
                    <span class="help-block offset-sm-4 col-sm-8">
                        ${unsafeHTML(I18n.t("js.saved_annotation.form.markdown_html"))}
                    </span>
                </div>
            </form>`;
    }
}
