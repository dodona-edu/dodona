import { customElement, property } from "lit/decorators.js";
import { render, html, LitElement, TemplateResult, css } from "lit";
import tippy, { Instance as Tippy, createSingleton } from "tippy.js";
import { Annotation, annotationState, compareAnnotationOrders, isUserAnnotation } from "state/Annotations";
import { StateController } from "state/state_system/StateController";
import { createDelayer } from "utilities";

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
    accessor annotations: Annotation[];

    static styles = css`:host { position: relative; }`;

    state = new StateController(this);

    // we need to keep track of all tippy instances to update the singleton
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

    /**
     * Updates the tippy singleton with the current list of tippy instances.
     * This method is debounced to avoid updating the singleton too often as it is expensive.
     */
    static updateSingletonInstances(): void {
        setInstancesDelayer(() => this.tippySingleton.setInstances(this.tippyInstances), 100);
    }

    /**
     * Adds a tippy instance to the list of instances, which will be used to update the singleton.
     */
    static registerTippyInstance(instance: Tippy): void {
        this.tippyInstances.push(instance);
        this.updateSingletonInstances();
    }

    /**
     * Removes a tippy instance from the list of instances, which will be used to update the singleton.
     */
    static unregisterTippyInstance(instance: Tippy): void {
        this.tippyInstances = this.tippyInstances.filter(i => i !== instance);
        this.updateSingletonInstances();
    }

    // Annotations that are not displayed inline should show up as tooltips.
    get hiddenAnnotations(): Annotation[] {
        return this.annotations.filter(a => !annotationState.isVisible(a)).sort(compareAnnotationOrders);
    }

    tippyInstance: Tippy;

    disconnectedCallback(): void {
        super.disconnectedCallback();
        // before destroying this element, we need to clean up the tippy instance
        // and make sure it is removed from the singleton
        if (this.tippyInstance) {
            AnnotationTooltip.unregisterTippyInstance(this.tippyInstance);
            this.tippyInstance.destroy();
            this.tippyInstance = undefined;
        }
    }

    render(): TemplateResult {
        // Clean up the previous tippy instance if it exists.
        if (this.tippyInstance) {
            AnnotationTooltip.unregisterTippyInstance(this.tippyInstance);
            this.tippyInstance.destroy();
            this.tippyInstance = undefined;
        }

        if (this.hiddenAnnotations.length > 0) {
            const tooltip = document.createElement("div");
            tooltip.classList.add("marker-tooltip");
            render(this.hiddenAnnotations.map(a => isUserAnnotation(a) ?
                html`
                    <d-user-annotation .data=${a}></d-user-annotation>` :
                html`
                    <d-machine-annotation .data=${a}></d-machine-annotation>`), tooltip);

            this.tippyInstance = tippy(this, {
                content: tooltip,
            });
            AnnotationTooltip.registerTippyInstance(this.tippyInstance);
        }

        // if slot is empty, render an empty svg to make sure the tooltip is positioned correctly
        return html`<slot><svg style="position: absolute; top: 9px; left: -7px" width="14" height="14" viewBox="0 0 24 24">
        </svg></slot>`;
    }
}
