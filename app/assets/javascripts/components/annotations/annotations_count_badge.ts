import { customElement } from "lit/decorators.js";
import { userAnnotationState } from "state/UserAnnotations";
import { html, TemplateResult } from "lit";
import { machineAnnotationState } from "state/MachineAnnotations";
import { DodonaElement } from "components/meta/dodona_element";

/**
 * This component represents a badge that shows the total number of annotations.
 *
 * @element d-annotations-count-badge
 */
@customElement("d-annotations-count-badge")
export class AnnotationsCountBadge extends DodonaElement {
    get annotationsCount(): number {
        return userAnnotationState.count + machineAnnotationState.count;
    }

    render(): TemplateResult {
        return this.annotationsCount ? html`
            <div class="badge rounded-pill">${this.annotationsCount}</div>
        ` : html``;
    }
}
