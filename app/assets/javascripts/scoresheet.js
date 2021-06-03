function initScoresheetLinks() {
    $("#scoresheet-selector").on("change", function () {
        window.location.href = $(this.options[this.selectedIndex]).data("url");
    });
}

export { initScoresheetLinks };

