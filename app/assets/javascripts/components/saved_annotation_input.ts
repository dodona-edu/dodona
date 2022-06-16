import { customElement, property } from "lit/decorators.js";
import { html, TemplateResult } from "lit";
import { ShadowlessLitElement } from "components/shadowless_lit_element";
import "components/datalist_input";

/**
 * This component represents an input for a saved annotation id.
 * The saved annotation can be searched by title using a d-datalist-input.
 *
 * @element d-saved-annotation-input
 *
 * @prop {String} name - name of the input field (used in form submit)
 * @prop {Number} courseId - used to fetch saved annotations by course
 * @prop {Number} exerciseId - used to fetch saved annotations by exercise
 * @prop {Number} userId - used to fetch saved annotations by user
 * @prop {String} value - the initial saved annotation id
 *
 * @fires input - on value change, event details contain {title: string, id: string, annotation_text: string}
 */
@customElement("d-saved-annotation-input")
export class SavedAnnotationInput extends ShadowlessLitElement {
    @property({ type: String })
    name = "";
    @property({ type: Number, attribute: "course-id" })
    courseId: number;
    @property({ type: Number, attribute: "exercise-id" })
    exerciseId: number;
    @property({ type: Number, attribute: "user-id" })
    userId: number;
    @property({ type: String })
    value: string;

    @property({ state: true })
    savedAnnotations: {title: string, id: string, annotation_text: string}[] = [];

    get options(): {label: string, value: string}[] {
        return this.savedAnnotations.map(sa => ({ label: sa.title, value: sa.id.toString() }));
    }

    connectedCallback(): void {
        super.connectedCallback();
        this.fetchAnnotations();
    }

    async fetchAnnotations(): Promise<void> {
        const url = `/saved_annotations.json?course_id=${this.courseId}&exercise_id=${this.exerciseId}&user_id=${this.userId}`;
        const response = await fetch(url);
        this.savedAnnotations = await response.json();
    }

    processInput(e: CustomEvent): void {
        const annotation = this.savedAnnotations.find(sa => sa.id.toString() === e.detail.value.toString());
        const event = new CustomEvent("input", {
            detail: { id: e.detail.value, title: e.detail.label, text: annotation?.annotation_text },
            bubbles: true,
            composed: true }
        );
        this.dispatchEvent(event);
        e.stopPropagation();
    }

    render(): TemplateResult {
        return html`
            <d-datalist-input
                name="${this.name}"
                .options=${this.options}
                value="${this.value}"
                @input="${e => this.processInput(e)}"
            ></d-datalist-input>
        `;
    }
}
