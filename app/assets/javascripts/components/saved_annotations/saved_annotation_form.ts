import { customElement, property } from "lit/decorators.js";
import { html, TemplateResult } from "lit";
import { SavedAnnotation } from "state/SavedAnnotations";
import { unsafeHTML } from "lit/directives/unsafe-html.js";
import "components/saved_annotations/saved_annotation_title_input";
import { DodonaElement } from "components/meta/dodona_element";
import { i18n } from "i18n/i18n";

/**
 * This component represents a form for creating or editing saved annotations
 *
 * @element d-saved-annotation-form
 *
 * @prop {SavedAnnotation} savedAnnotation - the saved annotation to be edited in this form
 * @prop {Number} exerciseId - the id of the exercise to which the annotation belongs
 * @prop {Number} courseId - the id of the course to which the annotation belongs
 *
 * @fires change - on user changes in the form, event.detail has the new state of the SavedAnnotation
 */
@customElement("d-saved-annotation-form")
export class SavedAnnotationForm extends DodonaElement {
    @property({ type: Object })
    savedAnnotation: SavedAnnotation;
    @property({ type: Number, attribute: "exercise-id" })
    exerciseId: number;
    @property({ type: Number, attribute: "course-id" })
    courseId: number;

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
                <div class="field form-group">
                    <label class="form-label">
                        ${i18n.t("js.saved_annotation.title")}
                    </label>
                    <d-saved-annotation-title-input
                        .value=${this.savedAnnotation.title}
                        @change=${e => this.updateTitle(e)}
                        .courseId=${this.courseId}
                        .exerciseId=${this.exerciseId}>
                    </d-saved-annotation-title-input>
                </div>
                <div class="field form-group">
                    <label class="form-label">
                        ${i18n.t("js.saved_annotation.annotation_text")}
                    </label>
                    <textarea required="required" class="form-control" rows="4"
                              .value=${this.savedAnnotation.annotation_text} @change=${e => this.updateText(e)}></textarea>
                    <span class="help-block">
                        ${unsafeHTML(i18n.t("js.saved_annotation.form.markdown_html"))}
                        ${i18n.t("js.saved_annotation.form.annotation_text_help")}
                    </span>
                </div>
            </form>`;
    }
}
