import { LitElement, PropertyValues } from "lit";

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type Constructor = abstract new (...args: any[]) => LitElement;

export function watchMixin<T extends Constructor>(superClass: T): T {
    /**
     * This mixin makes a LitElement watch properties for changes using the functions defined in the watch object
     */
    abstract class WatchMixinClass extends superClass {
        abstract get watch(): {[key: string]: (old: unknown) => void};

        update(changedProperties: PropertyValues): void {
            for (const [key, f] of Object.entries(this.watch)) {
                if (changedProperties.has(key)) {
                    f.bind(this);
                    f(changedProperties.get(key));
                }
            }
            super.update(changedProperties);
        }
    }

    // Cast return type to the superClass type passed in
    return WatchMixinClass as T;
}
