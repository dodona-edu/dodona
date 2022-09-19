export class MapWithDefault<K, V> extends Map<K, V> {
    default: () => V;

    get(key: K): V {
        if (!this.has(key)) {
            this.set(key, this.default());
        }
        return super.get(key);
    }

    constructor(defaultFunction: () => V, ...args) {
        super(...args);
        this.default = defaultFunction;
    }
}
