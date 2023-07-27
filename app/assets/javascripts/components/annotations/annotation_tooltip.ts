import { customElement, property } from "lit/decorators.js";
import { render, html, LitElement, TemplateResult, css } from "lit";
import tippy, { Instance as Tippy, createSingleton } from "tippy.js";
import { AnnotationData, annotationState, compareAnnotationOrders, isUserAnnotation } from "state/Annotations";
import { StateController } from "state/state_system/StateController";
import { createDelayer } from "util.js";

const setInstancesDelayer = createDelayer();
/**
 * Adds tooltips with annotations to slotted content
 *
 * @prop {AnnotationData[]} annotations The annotations to show in the tooltip.
 *
 * @element d-annotation-tooltip
 */
@customElement("d-annotation-tooltip")
export class AnnotationTooltip extends LitElement {
    @property({ type: Array })
    annotations: AnnotationData[];

    static styles = css`:host { position: relative; }`;

    state = new StateController(this);

    static tippyInstances: Tippy[] = [];
    // Using a singleton to avoid multiple tooltips being open at the same time.
    static tippySingleton = createSingleton([], {
        placement: "bottom-start",
        interactive: true,
        interactiveDebounce: 25,
        delay: [500, 25],
        offset: [-10, 0],
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
            AnnotationTooltip.unregisterTippyInstance(this.tippyInstance);
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
        AnnotationTooltip.registerTippyInstance(this.tippyInstance);
    }

    disconnectedCallback(): void {
        super.disconnectedCallback();
        if (this.tippyInstance) {
            AnnotationTooltip.unregisterTippyInstance(this.tippyInstance);
            this.tippyInstance.destroy();
            this.tippyInstance = undefined;
        }
    }

    render(): TemplateResult {
        this.renderTooltip();

        // if slot is empty, render an empty svg to make sure the tooltip is positioned correctly
        return html`<slot><svg style="position: absolute; top: 9px; left: -7px" width="14" height="14" viewBox="0 0 24 24">
        </svg></slot>`;
    }
}
