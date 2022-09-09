import Polyglot from "node-polyglot";
import translations from "./translations.json";
import dayjs, { Dayjs } from "dayjs";
import "dayjs/locale/nl.js";

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
            super.warn("Missing array translation for key: '" + key + "'");
            return [];
        }
    }

    get locale(): string {
        return super.locale();
    }

    /**
     * When locale changes we need to switch the list of phrases used by polyglot
     */
    set locale(locale: string) {
        if (locale == "en" || locale == "nl") {
            super.replace(translations[locale]);
        }
        super.locale(locale);
    }

    /**
     * Polyglot does not do custom number formatting, thus we use the javascript api
     */
    formatNumber(number: number, options?: Record<string, unknown>): string {
        return new Intl.NumberFormat(this.locale, options).format(number);
    }

    formatDate(date: string | number | Date | Dayjs, format: string): string {
        const d = dayjs(date);
        const f = super.t(format);
        return d.locale(this.locale).format(f);
    }
}
