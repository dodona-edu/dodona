function showInfoModal(title, content, options) {
    options = options || {};
    if (options.allowFullscreen) {
        $("#info-modal .modal-header #fullscreen-button").css("display", "inline");
    } else {
        $("#info-modal .modal-header #fullscreen-button").css("display", "none");
    }
    $("#info-modal .modal-title")
        .empty()
        .append(title);

    $("#info-modal .modal-body")
        .empty()
        .append("<p>" + content + "</p>");
    $("#info-modal").modal("show");
}

export { showInfoModal };
