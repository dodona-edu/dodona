import { customElement, property } from "lit/decorators.js";
import { render, html, LitElement, TemplateResult } from "lit";
import tippy, { Instance as Tippy, createSingleton } from "tippy.js";
import { AnnotationData, annotationState, compareAnnotationOrders, isUserAnnotation } from "state/Annotations";
import { StateController } from "state/state_system/StateController";

/**
 * A marker that shows a tooltip with machine annotations.
 *
 * @prop {AnnotationData[]} annotations The annotations to show in the tooltip.
 *
 * @element d-annotation-marker
 */
@customElement("d-annotation-marker")
export class AnnotationMarker extends LitElement {
    @property({ type: Array })
    annotations: AnnotationData[];

    state = new StateController(this);


    static colors = {
        error: "var(--error-color, red)",
        warning: "var(--warning-color, yellow)",
        info: "var(--info-color, blue)",
        annotation: "var(--annotation-color, green)",
        question: "var(--question-color, orange)",
    };

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

    get hiddenAnnotations(): AnnotationData[] {
        return this.annotations.filter(a => !annotationState.isVisible(a)).sort(compareAnnotationOrders);
    }

    tippyInstance: Tippy;

    renderTooltip(): void {
        if (this.tippyInstance) {
            AnnotationMarker.unregisterTippyInstance(this.tippyInstance);
            this.tippyInstance.destroy();
            this.tippyInstance = undefined;
        }

        if (this.hiddenAnnotations.length === 0) {
            return;
        }

        const tooltip = document.createElement("div");
        tooltip.classList.add("marker-tooltip");
        render(this.hiddenAnnotations.map(a => isUserAnnotation(a) ?
            html`<d-user-annotation .data=${a}></d-user-annotation>` :
            html`<d-machine-annotation .data=${a}></d-machine-annotation>`), tooltip);

        this.tippyInstance = tippy(this, {
            content: tooltip,
        });
        AnnotationMarker.registerTippyInstance(this.tippyInstance);
    }

    get sortedAnnotations(): AnnotationData[] {
        return this.annotations.sort(compareAnnotationOrders);
    }

    get machineAnnotationColor(): string | undefined {
        const firstMachineAnnotation = this.sortedAnnotations.find(a => !isUserAnnotation(a));
        return firstMachineAnnotation && AnnotationMarker.colors[firstMachineAnnotation.type];
    }

    get machineAnnotationMarkStyle(): string | undefined {
        return this.machineAnnotationColor && `text-decoration: wavy underline ${this.machineAnnotationColor};`;
    }

    get machineAnnotationMarkerSVG(): TemplateResult | undefined {
        return this.machineAnnotationColor && html`<svg style="position: absolute; top: 9px; left: -7px" width="14" height="14" viewBox="0 0 24 24">
            <path fill="${this.machineAnnotationColor}" d="M7.41 15.41L12 10.83l4.59 4.58L18 14l-6-6l-6 6l1.41 1.41Z"/>
        </svg>`;
    }

    get userAnnotationMarkStyle(): string {
        const firstUserAnnotation = this.sortedAnnotations.find(a => isUserAnnotation(a));
        if (firstUserAnnotation) {
            return `background: ${AnnotationMarker.colors[firstUserAnnotation.type]};`;
        }
        return "";
    }

    render(): TemplateResult {
        this.renderTooltip();

        return html`<style>
            :host {
                position: relative;
                ${this.userAnnotationMarkStyle}
                ${this.machineAnnotationMarkStyle}
            }
        </style><slot>${this.machineAnnotationMarkerSVG}</slot>`;
    }
}
