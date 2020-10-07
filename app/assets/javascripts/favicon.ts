/**
 * Manager for the favicon.
 */
export class FaviconManager {
    private readonly tags: Set<string> = new Set<string>();

    public constructor(initial: string[]) {
        initial.forEach(e => this.tags.add(e));
    }

    /**
     * Request that you want to show a dot in the favicon. This will always
     * result in a dot being shown.
     *
     * @param {string} tag The tag you want to add.
     */
    public requestDot(tag: string): void {
        // Thread safe, since JS is single threaded in the browser.
        this.tags.add(tag);
        FaviconManager.showDot();
    }

    /**
     * Indicate you no longer want to show a dot in the favicon. If you were the
     * last one requesting the dot, the dot will be hidden.
     *
     * @param {string} tag The tag you want to release.
     */
    public releaseDot(tag: string): void {
        this.tags.delete(tag);
        if (this.tags.size === 0) {
            FaviconManager.hideDot();
        }
    }

    private static showDot(): void {
        document.querySelector("link[rel=\"shortcut icon\"][href=\"/icon.png\"]")
            ?.setAttribute("href", "/icon-not.png");
        document.querySelector("link[rel=\"shortcut icon\"][href=\"/favicon.ico\"]")
            ?.setAttribute("href", "/favicon-not.ico");
    }

    private static hideDot(): void {
        document.querySelector("link[rel=\"shortcut icon\"][href=\"/icon-not.png\"]")
            ?.setAttribute("href", "/icon.png");
        document.querySelector("link[rel=\"shortcut icon\"][href=\"/favicon-not.ico\"]")
            ?.setAttribute("href", "/favicon.ico");
    }
}
