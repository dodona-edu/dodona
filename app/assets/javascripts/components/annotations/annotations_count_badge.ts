import { customElement } from "lit/decorators.js";
import { stateMixin } from "state/StateMixin";
import { ShadowlessLitElement } from "components/meta/shadowless_lit_element";
import { getUserAnnotationsCount } from "state/UserAnnotations";
import { html, TemplateResult } from "lit";
import { machineAnnotationState } from "state/MachineAnnotations";

/**
 * This component represents a badge that shows the total number of annotations.
 *
 * @element d-annotations-count-badge
 */
@customElement("d-annotations-count-badge")
export class AnnotationsCountBadge extends stateMixin(ShadowlessLitElement) {
    state = ["getUserAnnotationsCount"];

    get annotationsCount(): number {
        return getUserAnnotationsCount() + machineAnnotationState.annotationsCount;
    }

    render(): TemplateResult {
        return html`
            <div class="badge rounded-pill">${this.annotationsCount}</div>
        `;
    }
}
