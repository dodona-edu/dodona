import { ShadowlessLitElement } from "components/meta/shadowless_lit_element";
import { customElement, property } from "lit/decorators.js";
import { html, TemplateResult } from "lit";
import { stateMixin } from "state/StateMixin";
import { getMachineAnnotationsByLine, MachineAnnotationData } from "state/MachineAnnotations";
import { createUserAnnotation, getUserAnnotationsByLine, UserAnnotationData } from "state/UserAnnotations";
import { AnnotationVisibilityOptions, getAnnotationVisibility, getQuestionMode } from "state/Annotations";
import { unsafeHTML } from "lit/directives/unsafe-html.js";
import "components/annotations/machine_annotation";
import "components/annotations/user_annotation";
import "components/annotations/annotation_form";
import { UserAnnotationFormData } from "code_listing/user_annotation";
import { invalidateSavedAnnotation } from "state/SavedAnnotations";
import { getEvaluationId } from "state/Evaluations";
import { getSubmissionId } from "state/Submissions";
import { createSavedAnnotation } from "state/SavedAnnotations";

@customElement("d-code-listing-row")
export class CodeListingRow extends stateMixin(ShadowlessLitElement) {
    @property({ type: Number })
    row: number;
    @property({ type: String })
    renderedCode: string;

    @property({ state: true })
    showForm: boolean;

    state = ["getUserAnnotations", "getMachineAnnotations", "getAnnotationVisibility"];

    get machineAnnotations(): MachineAnnotationData[] {
        return getMachineAnnotationsByLine(this.row);
    }

    get userAnnotations(): UserAnnotationData[] {
        return getUserAnnotationsByLine(this.row);
    }

    get annotationVisibility(): AnnotationVisibilityOptions {
        return getAnnotationVisibility();
    }

    getVisibleMachineAnnotationsOfType(type: string): TemplateResult[] {
        return this.machineAnnotations
            .filter(a => this.isVisible(a))
            .filter(a => a.type === type).map(a => html`
                <d-machine-annotation .data=${a}></d-machine-annotation>
        `);
    }

    isVisible(annotation: MachineAnnotationData | UserAnnotationData): boolean {
        if (this.annotationVisibility === "none") {
            return false;
        }

        if (this.annotationVisibility === "important") {
            return annotation.type === "error" || annotation.type === "annotation" || annotation.type === "question";
        }

        return true;
    }

    get hiddenAnnotations(): (MachineAnnotationData | UserAnnotationData)[] {
        return [...this.machineAnnotations, ...this.userAnnotations].filter(a => !this.isVisible(a));
    }

    get infoDotClasses(): string {
        const hiddenTypes = this.hiddenAnnotations.map(a => a.type);
        return [...new Set(hiddenTypes)].map(t => `dot-${t}`).join(" ");
    }

    get infoDotTitle(): string {
        const count = this.hiddenAnnotations.length;
        if (count === 1) {
            return I18n.t("js.annotation.hidden.single");
        } else {
            return I18n.t("js.annotation.hidden.plural", { count: count });
        }
    }

    async createSavedAnnotation(from: UserAnnotationData, eventDetail: { savedAnnotationTitle: string, text: string, saveAnnotation: boolean }): Promise<void> {
        if (eventDetail.saveAnnotation) {
            try {
                from.saved_annotation_id = await createSavedAnnotation({
                    from: from.id,
                    saved_annotation: {
                        title: eventDetail.savedAnnotationTitle,
                        annotation_text: eventDetail.text,
                    }
                });
            } catch (errors) {
                alert(I18n.t("js.saved_annotation.new.errors", { count: errors.length }) + "\n\n" + errors.join("\n"));
            }
        }
    }

    async createAnnotation(e: CustomEvent): Promise<void> {
        const annotationData: UserAnnotationFormData = {
            "annotation_text": e.detail.text,
            "line_nr": this.row,
            "evaluation_id": getEvaluationId(),
            "saved_annotation_id": e.detail.savedAnnotationId || undefined,
        };

        try {
            const mode = getQuestionMode() ? "question" : "annotation";
            const annotation = await createUserAnnotation(annotationData, getSubmissionId(), mode);
            await this.createSavedAnnotation(annotation, e.detail);
            invalidateSavedAnnotation(e.detail.savedAnnotationId);
            this.showForm = false;
        } catch (err) {
            // annotationForm.hasErrors = true;
            // annotationForm.disabled = false;
        }
    }

    render(): TemplateResult {
        console.log("rendering row", this.row);
        return html`
                <td class="rouge-gutter gl">
                    <button class="btn btn-icon btn-icon-filled bg-primary annotation-button"
                            @click=${() => this.showForm = !this.showForm}
                            title="Toevoegen">
                        <i class="mdi mdi-comment-plus-outline mdi-18"></i>
                    </button>
                    ${this.hiddenAnnotations.length > 0 ? html`
                        <span class="dot ${this.infoDotClasses}" title="${this.infoDotTitle}"></span>
                    ` : ""}
                    <pre>${this.row}</pre>
                </td>
                <td class="rouge-code">
                    <pre>${unsafeHTML(this.renderedCode)}</pre>
                    <div class="annotation-cell">
                        ${this.showForm ? html`
                            <d-annotation-form @cancel=${() => this.showForm = false}
                                               @submit=${e => this.createAnnotation(e)}
                            ></d-annotation-form>
                        ` : ""}
                        <div class="annotation-group-error">
                            ${this.getVisibleMachineAnnotationsOfType("error")}
                        </div>
                        <div class="annotation-group-conversation">
                            ${this.userAnnotations.filter(a => this.isVisible(a)).map(a => html`
                                <d-user-annotation .data=${a}></d-user-annotation>
                            `)}
                        </div>
                        <div class="annotation-group-warning">
                            ${this.getVisibleMachineAnnotationsOfType("warning")}
                        </div>
                        <div class="annotation-group-info">
                            ${this.getVisibleMachineAnnotationsOfType("info")}
                        </div>
                    </div>
                </td>
        `;
    }
}
