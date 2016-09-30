function showInfoModal(title, content, options) {
    var options = options || {};
    if (options.wide) {
        $("#info-modal .modal-dialog").addClass("modal-lg");
    }
    $("#info-modal .modal-title")
        .empty()
        .append(title);

    $("#info-modal .modal-body")
        .empty()
        .append("<p>" + content + "</p>");
    $("#info-modal").modal("show");
}