import { customElement } from "lit/decorators.js";
import { stateMixin } from "state/StateMixin";
import { ShadowlessLitElement } from "components/meta/shadowless_lit_element";
import { getUserAnnotationsCount } from "state/UserAnnotations";
import { getMachineAnnotationsCount } from "state/MachineAnnotations";
import { html, TemplateResult } from "lit";

@customElement("d-annotations-count-badge")
export class AnnotationsCountBadge extends stateMixin(ShadowlessLitElement) {
    state = ["getUserAnnotationsCount", "getMachineAnnotationsCount"];

    get annotationsCount(): number {
        return getUserAnnotationsCount() + getMachineAnnotationsCount();
    }

    render(): TemplateResult {
        return html`
            <div class="badge rounded-pill">${this.annotationsCount}</div>
        `;
    }
}
