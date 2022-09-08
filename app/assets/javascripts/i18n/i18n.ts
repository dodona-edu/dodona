import Polyglot from "node-polyglot";
import translations from "./translations.json";

const forEach = Array.prototype.forEach;
const entries = Object.entries;

export class I18n extends Polyglot {
    extend(morePhrases = {}, prefix: string): void {
        entries(morePhrases || {}).forEach( entry => {
            const key = entry[0];
            const phrase = entry[1];
            const prefixedKey = prefix ? prefix + "." + key : key;
            if (typeof phrase === "object" && !Array.isArray(phrase)) {
                this.extend(phrase, prefixedKey);
            } else {
                this.phrases[prefixedKey] = phrase;
            }
        });
    }

    t(key: string, options?: Record<string, unknown>): string {
        if (Array.isArray(this.phrases[key])) {
            return this.phrases[key];
        }
        return super.t(key, options);
    }

    locale(locale?: string): string {
        if (locale == "en" || locale == "nl") {
            super.replace(translations[locale]);
        }
        return super.locale(locale);
    }

    formatNumber(number: number, options?: Record<string, unknown>): string {
        return new Intl.NumberFormat(this.locale(), options).format(number);
    }
}
