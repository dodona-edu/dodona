import { LitElement, PropertyValues } from "lit";
import { render } from "lit-html";
import { customElement } from "lit/decorators.js";

export interface ITemplate extends HTMLElement {
    contentFor?: string;
}

export type Template = HTMLTemplateElement | TemplateLike;

// The native template element doesn't work with frameworks that
// precompile their templates.
@customElement("template-like")
export class TemplateLike extends HTMLElement implements ITemplate {
    contentFor?: string;
}

/**
 * This class removes the shadow dom functionality from lit elements
 * Shadow dom allows for:
 *   - DOM scoping
 *   - Style Scoping
 *   - Composition
 * more info here: https://lit.dev/docs/components/shadow-dom/
 *
 * This class is often used to avoid style scoping. (To be able to use the style as defined in our general css)
 * When shadow dom is required just use a normal LitElement
 *
 * A lot of code has been added to reenable the use of slots in the shadowless lit element
 * All credits for this code go to https://github.com/daniel-nagy
 * The code can be found at https://stackblitz.com/edit/typescript-2ufoty?file=shadowless.ts
 * He also made it into a npm package: https://github.com/Boulevard/vampire
 * but I chose to include the source code because his package is not maintained, so this way it is easier to do bugfixes ourselves
 *
 * Usage in Component:
 *   render() {
 *     return html`
 *       ${this.yield('', 'Default content')}
 *       <div>
 *         ${this.yield('buttons', html`<button ...>Default button</button>`)}
 *       </div>
 *     `;
 *   }
 *
 * Usage in host:
     <awc-my-component>
         My content
         <template .contentFor=${'buttons'}>
             <button ...>Click me</button>
         </template>
     </awc-my-component>
 *
 */
export class ShadowlessLitElement extends LitElement {
    // don't use shadow dom
    createRenderRoot(): Element {
        return this;
    }

    static render = render;

    protected templateMap = new Map<string, DocumentFragment | Template>();

    protected getSlotForTemplate(template: ITemplate): string {
        return template.contentFor || template.getAttribute("content-for") || "";
    }

    protected isEmptyTextNode(child: ChildNode): boolean {
        return child instanceof Text &&
            (!child.textContent || !child.textContent.trim());
    }

    // Save a reference to the templates before lit-element removes them.
    protected saveTemplates(): void {
        const childNodes: ChildNode[] = [];

        Array.from(this.childNodes).forEach(child => {
            if (!(child instanceof TemplateLike) && !(child instanceof HTMLTemplateElement)) {
                return childNodes.push(child);
            }

            const slot = this.getSlotForTemplate(child);

            if (!this.templateMap.has(slot)) {
                this.templateMap.set(slot, child);
            }
        });

        /*
         * It's unknown if an empty text node is from a line break or lit-html. If
         * the number of empty text nodes is greater than 2 then it is likely there
         * is a lit-html placeholder.
         *
         * However, I think this would fall apart if the lit-html binding was on the
         * same line, e.g.
         *
         *   html`<my-component>${this.foo}</my-component>`
         *
         * Assuming the browser doesn’t insert line breaks, the number of Text nodes
         * would be one and this would fail.
         */
        const shouldSlotChildren = childNodes.length > 2 ||
            childNodes.some(child => !this.isEmptyTextNode(child));

        if (shouldSlotChildren) {
            const fragment = document.createDocumentFragment();

            childNodes.forEach(child => {
                fragment.appendChild(child);
            });

            this.templateMap.set("", fragment);
        }
    }

    protected update(changedProperties: PropertyValues): void {
        if (!this.hasUpdated) {
            this.saveTemplates();
        }

        super.update(changedProperties);
    }

    protected yield<T>(slot = "", defaultConent?: T): DocumentFragment | ChildNode[] | T | undefined {
        const slotContent = this.templateMap.get(slot);

        if (slotContent instanceof HTMLTemplateElement) {
            return slotContent.content;
        }

        if (slotContent instanceof TemplateLike) {
            return Array.from(slotContent.childNodes);
        }

        if (slotContent instanceof DocumentFragment) {
            return slotContent;
        }

        return defaultConent;
    }
}
