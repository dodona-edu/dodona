import { customElement, property } from "lit/decorators.js";
import { render, html, LitElement, TemplateResult } from "lit";
import tippy, { Instance as Tippy, createSingleton } from "tippy.js";
import { AnnotationData, annotationState, compareAnnotationOrders, isUserAnnotation } from "state/Annotations";
import { StateController } from "state/state_system/StateController";
import { createDelayer } from "util.js";

const setInstancesDelayer = createDelayer();
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
    @property({ type: String })
    type: "background" | "tooltip" = "background";

    state = new StateController(this);


    static colors = {
        "error": "var(--error-color, red)",
        "warning": "var(--warning-color, yellow)",
        "info": "var(--info-color, blue)",
        "annotation": "var(--annotation-color, green)",
        "question": "var(--question-color, orange)",
        "annotation-intense": "var(--annotation-intense-color, green)",
        "question-intense": "var(--question-intense-color, orange)",
    };

    static getStyle(annotation: AnnotationData): string {
        if (["error", "warning", "info"].includes(annotation.type)) {
            return `
                text-decoration: wavy underline ${AnnotationMarker.colors[annotation.type]} 1px;
                text-decoration-skip-ink: none;
            `;
        } else {
            return `
                background: ${AnnotationMarker.colors[annotation.type]};
            `;
        }
    }

    static tippyInstances: Tippy[] = [];
    // Using a singleton to avoid multiple tooltips being open at the same time.
    static tippySingleton = createSingleton([], {
        placement: "bottom-start",
        interactive: true,
        interactiveDebounce: 25,
        delay: [500, 25],
        offset: [-10, -2],
        // This transition fixes a bug where overlap with the previous tooltip was taken into account when positioning
        moveTransition: "transform 0.001s ease-out",
        appendTo: () => document.querySelector(".code-table"),
    });
    static updateSingletonInstances(): void {
        setInstancesDelayer(() => this.tippySingleton.setInstances(this.tippyInstances), 100);
    }
    static registerTippyInstance(instance: Tippy): void {
        this.tippyInstances.push(instance);
        this.updateSingletonInstances();
    }
    static unregisterTippyInstance(instance: Tippy): void {
        this.tippyInstances = this.tippyInstances.filter(i => i !== instance);
        this.updateSingletonInstances();
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

    disconnectedCallback(): void {
        super.disconnectedCallback();
        if (this.tippyInstance) {
            AnnotationMarker.unregisterTippyInstance(this.tippyInstance);
            this.tippyInstance.destroy();
            this.tippyInstance = undefined;
        }
    }

    get sortedAnnotations(): AnnotationData[] {
        return this.annotations.sort( compareAnnotationOrders );
    }

    get machineAnnotationMarkerSVG(): TemplateResult | undefined {
        const firstMachineAnnotation = this.sortedAnnotations.find(a => !isUserAnnotation(a));
        const size = 14;
        return firstMachineAnnotation && html`<svg style="position: absolute; top: ${16 - size/2}px; left: -${size/2}px; z-index: 3" width="${size}" height="${size}" viewBox="0 0 24 24">
            <path fill="${AnnotationMarker.colors[firstMachineAnnotation.type]}" d="M7.41 15.41L12 10.83l4.59 4.58L18 14l-6-6l-6 6l1.41 1.41Z"/>
        </svg>`;
    }

    get annotationStyles(): string {
        return this.sortedAnnotations.reverse().map(a => AnnotationMarker.getStyle(a)).join(" ");
    }

    render(): TemplateResult {
        if (this.type === "tooltip") {
            this.renderTooltip();
            return html`<slot></slot>`;
        } else {
            return html`<style>
                    :host {
                        position: relative;
                        ${this.annotationStyles}
                    }
                </style><slot>${this.machineAnnotationMarkerSVG}</slot>`;
        }
    }
}
