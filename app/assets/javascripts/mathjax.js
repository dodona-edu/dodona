/* globals MathJax */

export function initMathJax() {
    // configure MathJax if loaded
    if (typeof MathJax !== "undefined") {
        MathJax.Hub.Config({
            tex2jax: {
                inlineMath: [
                    ["$$", "$$"],
                    ["\\(", "\\)"],
                ],
                displayMath: [
                    ["\\[", "\\]"],
                ],
                ignoreClass: "feedback-table",
            },
        });
    }
}
