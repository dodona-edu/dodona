export function initInlineEditButton(tableElement: HTMLElement): void {
    tableElement.querySelectorAll(".edit-button").forEach(item => {
        item.addEventListener("click", e => {
            e.preventDefault();
            const clicked = (e.target as HTMLElement).closest("a") as HTMLAnchorElement;
            const scoreItemId = clicked.dataset.scoreItem;
            const row = document.getElementById(`form-row-${scoreItemId}`);
            if (row.classList.contains("hidden")) {
                row.classList.remove("hidden");
                clicked.innerHTML = "<i class='mdi mdi-close mdi-18' aria-hidden='true'></i>";
            } else {
                row.classList.add("hidden");
                clicked.innerHTML = "<i class='mdi mdi-pencil mdi-18' aria-hidden='true'></i>";
            }
        });
    });
}
