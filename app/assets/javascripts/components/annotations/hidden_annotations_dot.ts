import { ShadowlessLitElement } from "components/meta/shadowless_lit_element";
import { customElement, property } from "lit/decorators.js";
import { html, TemplateResult } from "lit";
import { stateMixin } from "state/StateMixin";
import { getMachineAnnotationsByLine, MachineAnnotationData } from "state/MachineAnnotations";
import { getUserAnnotationsByLine, UserAnnotationData } from "state/UserAnnotations";
import { isAnnotationVisible } from "state/Annotations";

@customElement("d-hidden-annotations-dot")
export class HiddenAnnotationsDot extends stateMixin(ShadowlessLitElement) {
    @property({ type: Number })
    row: number;

    state = ["getUserAnnotations", "getMachineAnnotations", "isAnnotationVisible"];

    get machineAnnotations(): MachineAnnotationData[] {
        return getMachineAnnotationsByLine(this.row);
    }

    get userAnnotations(): UserAnnotationData[] {
        return getUserAnnotationsByLine(this.row);
    }

    get hiddenAnnotations(): (MachineAnnotationData | UserAnnotationData)[] {
        return [...this.machineAnnotations, ...this.userAnnotations].filter(a => !isAnnotationVisible(a));
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

    render(): TemplateResult {
        if (this.hiddenAnnotations.length > 0) {
            return html`
                <span class="dot ${this.infoDotClasses}" title="${this.infoDotTitle}"></span>
            `;
        }

        return html``;
    }
}
