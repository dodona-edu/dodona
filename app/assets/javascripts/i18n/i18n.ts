import Polyglot from "node-polyglot";
import translations from "./translations.json";
import dayjs, { Dayjs } from "dayjs";
import "dayjs/locale/nl.js";
import warning from "warning";

export class I18n extends Polyglot {
    /**
     * Polyglot does not support arrays of phrases
     * So we store these separately and have a custom function to fetch them
     */
    array_phrases: Record<string, string[]> = {};
    extend(morePhrases = {}, prefix: string): void {
        if (Array.isArray(morePhrases)) {
            this.array_phrases[prefix] = morePhrases as string[];
        }
        super.extend(morePhrases, prefix);
    }
    clear(): void {
        this.array_phrases = {};
        super.clear();
    }
    t_a(key: string): string[] {
        if (Array.isArray(this.array_phrases[key])) {
            return this.array_phrases[key];
        } else {
            warning(false, "Missing array translation for key: '" + key + "'");
            return [];
        }
    }

    constructor() {
        super();
        // set default locale, avoids a lot of errors when the locale is not yet set
        this.loc = "en";
    }

    get loc(): string {
        return this.locale();
    }

    set loc(locale: string) {
        this.locale(locale);
    }

    /**
     * When locale changes we need to switch the list of phrases used by polyglot
     */
    locale(locale?: string): string {
        if (locale == "en" || locale == "nl") {
            super.replace(translations[locale]);
        }
        return super.locale(locale);
    }

    /**
     * Polyglot does not do custom number formatting, thus we use the javascript api
     */
    formatNumber(number: number, options?: Record<string, unknown>): string {
        return new Intl.NumberFormat(this.loc, options).format(number);
    }

    formatDate(date: string | number | Date | Dayjs, format: string): string {
        const d = dayjs(date);
        const f = super.t(format);
        return d.locale(this.loc).format(f);
    }
}

export const i18n = new I18n();
