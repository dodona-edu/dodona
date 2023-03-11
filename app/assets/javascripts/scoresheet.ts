function initScoresheetLinks(): void {
    document.querySelector("#scoresheet-selector").addEventListener("change", e => {
        window.location.href = e.currentTarget.options[e.currentTarget.selectedIndex].dataset.url + window.location.search;
    });
}

export { initScoresheetLinks };

