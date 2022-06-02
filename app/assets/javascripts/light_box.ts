import GLightbox from "glightbox";

function showLightbox(content: string): void {
    const lightbox = new GLightbox(content);
    lightbox.on("slide_changed", () => {
        // There might have been math in the image captions, so ask
        // MathJax to search for new math (but only in the captions).
        window.MathJax.typeset([".gslide-description"]);
    });
    lightbox.open();

    // Transfer focus back to the document body to allow the lightbox to be closed.
    // https://github.com/dodona-edu/dodona/issues/1759.
    document.body.focus();
}


function onFrameMessage(event: {message: {type: string, content: string}}): void {
    if (event.message.type === "lightbox") {
        showLightbox(event.message.content);
    }
}

export { onFrameMessage };
