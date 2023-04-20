import { customElement, property } from "lit/decorators.js";
import { render, html, LitElement, TemplateResult, PropertyValues } from "lit";
import { MachineAnnotationData } from "state/MachineAnnotations";
import tippy, { Instance as Tippy, createSingleton } from "tippy.js";

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

    protected firstUpdated(_changedProperties: PropertyValues): void {
        super.firstUpdated(_changedProperties);
        const tooltip = document.createElement("div");
        tooltip.classList.add("marker-tooltip");
        render(this.annotations.map(a => html`<d-machine-annotation .data=${a}></d-machine-annotation>`), tooltip);

        const t = tippy(this, {
            content: tooltip,
        });
        MachineAnnotationMarker.registerTippyInstance(t);
    }

    get markColor(): string {
        const types = new Set(this.annotations.map(a => a.type));
        if (types.has("error")) {
            return "var(--error-color, red)";
        } else if (types.has("warning")) {
            return "var(--warning-color, yellow)";
        } else if (types.has("info")) {
            return "var(--info-color, blue)";
        } else {
            return undefined;
        }
    }

    render(): TemplateResult {
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
