function initScoresheetLinks() {
    $("#scoresheet-selector").change(function () {
        window.location.href = $(this.options[this.selectedIndex]).data("url");
    });
}

export { initScoresheetLinks };

