import { customElement, property } from "lit/decorators.js";
import { render, html, LitElement, TemplateResult } from "lit";
import tippy, { Instance as Tippy, createSingleton } from "tippy.js";
import { AnnotationData, annotationState, compareAnnotationOrders, isUserAnnotation } from "state/Annotations";
import { StateController } from "state/state_system/StateController";

/**
 * A marker that styles the slotted content and shows a tooltip with annotations.
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

    static getStyle(annotation: AnnotationData): string {
        if (["error", "warning", "info"].includes(annotation.type)) {
            return `text-decoration: wavy underline ${AnnotationMarker.colors[annotation.type]} ${annotationState.isHovered(annotation) ? 2 : 1}px;`;
        } else if (annotationState.isHovered(annotation) || !annotationState.isVisible(annotation)) {
            return `
                background: ${AnnotationMarker.colors[annotation.type]};
                padding-top: 2px;
                padding-bottom: 2px;
                margin-top: -2px;
                margin-bottom: -2px;
            `;
        } else {
            return "";
        }
    }

    static tippyInstances: Tippy[] = [];
    // Using a singleton to avoid multiple tooltips being open at the same time.
    static tippySingleton = createSingleton([], {
        placement: "bottom-start",
        interactive: true,
        interactiveDebounce: 25,
        delay: [500, 25],
        offset: [-10, 2],
        // This transition fixes a bug where overlap with the previous tooltip was taken into account when positioning
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

    // Annotations that are displayed inline should show up as tooltips.
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
        return this.annotations.sort( (a, b) => {
            if (annotationState.isHovered(a)) {
                return -1;
            } else if (annotationState.isHovered(b)) {
                return 1;
            } else {
                return compareAnnotationOrders(a, b);
            }
        });
    }

    get machineAnnotationMarkerSVG(): TemplateResult | undefined {
        const firstMachineAnnotation = this.sortedAnnotations.find(a => !isUserAnnotation(a));
        const size = annotationState.isHovered(firstMachineAnnotation) ? 20 : 14;
        return firstMachineAnnotation && html`<svg style="position: absolute; top: ${16 - size/2}px; left: -${size/2}px" width="${size}" height="${size}" viewBox="0 0 24 24">
            <path fill="${AnnotationMarker.colors[firstMachineAnnotation.type]}" d="M7.41 15.41L12 10.83l4.59 4.58L18 14l-6-6l-6 6l1.41 1.41Z"/>
        </svg>`;
    }

    get annotationStyles(): string {
        return this.sortedAnnotations.reverse().map(a => AnnotationMarker.getStyle(a)).join(" ");
    }

    render(): TemplateResult {
        this.renderTooltip();

        return html`<style>
            :host {
                position: relative;
                ${this.annotationStyles}
            }
        </style><slot>${this.machineAnnotationMarkerSVG}</slot>`;
    }
}
