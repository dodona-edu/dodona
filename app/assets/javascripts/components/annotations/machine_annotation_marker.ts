import { customElement, property } from "lit/decorators.js";
import { render, html, LitElement, TemplateResult } from "lit";
import { MachineAnnotationData } from "state/MachineAnnotations";
import tippy, { Instance as Tippy, createSingleton } from "tippy.js";
import { annotationState, compareAnnotationOrders } from "state/Annotations";
import { StateController } from "state/state_system/StateController";

/**
 * A marker that shows a tooltip with machine annotations.
 *
 * @prop {MachineAnnotationData[]} annotations The annotations to show in the tooltip.
 *
 * @element d-machine-annotation-marker
 */
@customElement("d-machine-annotation-marker")
export class MachineAnnotationMarker extends LitElement {
    @property({ type: Array })
    annotations: MachineAnnotationData[];

    state = new StateController(this);

    static tippyInstances: Tippy[] = [];
    static tippySingleton = createSingleton([], {
        placement: "bottom-start",
        interactive: true,
        interactiveDebounce: 25,
        delay: [500, 25],
        offset: [-10, 2],
        moveTransition: "transform 0.001s ease-out",
        appendTo: () => document.querySelector(".code-table"),
    });
    static registerTippyInstance(instance: Tippy): void {
        this.tippyInstances.push(instance);
        this.tippySingleton.setInstances(this.tippyInstances);
    }
    static unregisterTippyInstance(instance: Tippy): void {
        this.tippyInstances = this.tippyInstances.filter(i => i !== instance);
        this.tippySingleton.setInstances(this.tippyInstances);
    }

    get hiddenAnnotations(): MachineAnnotationData[] {
        return this.annotations.filter(a => !annotationState.isVisible(a)).sort(compareAnnotationOrders);
    }

    tippyInstance: Tippy;

    renderTooltip(): void {
        if (this.tippyInstance) {
            MachineAnnotationMarker.unregisterTippyInstance(this.tippyInstance);
            this.tippyInstance.destroy();
            this.tippyInstance = undefined;
        }

        if (this.hiddenAnnotations.length === 0) {
            return;
        }

        const tooltip = document.createElement("div");
        tooltip.classList.add("marker-tooltip");
        render(this.hiddenAnnotations.map(a => html`<d-machine-annotation .data=${a}></d-machine-annotation>`), tooltip);

        this.tippyInstance = tippy(this, {
            content: tooltip,
        });
        MachineAnnotationMarker.registerTippyInstance(this.tippyInstance);
    }

    get markColor(): string {
        const type = this.annotations.sort(compareAnnotationOrders)[0].type;
        const colors = {
            error: "var(--error-color, red)",
            warning: "var(--warning-color, yellow)",
            info: "var(--info-color, blue)",
        };
        return colors[type];
    }

    render(): TemplateResult {
        this.renderTooltip();

        return html`<style>
            :host {
                position: relative;
                text-decoration: wavy underline ${this.markColor};
            }
        </style><slot><svg style="position: absolute; top: 9px; left: -7px" width="14" height="14" viewBox="0 0 24 24">
            <path fill="${this.markColor}" d="M7.41 15.41L12 10.83l4.59 4.58L18 14l-6-6l-6 6l1.41 1.41Z"/>
        </svg></slot>`;
    }
}
