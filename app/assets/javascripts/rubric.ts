export function initInlineEditButton(tableElement: HTMLElement): void {
    tableElement.querySelectorAll(".edit-button").forEach(item => {
        item.addEventListener("click", e => {
            e.preventDefault();
            const clicked = (e.target as HTMLElement).closest("a") as HTMLLinkElement;
            console.log(clicked);
            console.log(clicked.dataset);
            const rubricId = clicked.dataset.rubric;
            const row = document.getElementById(`form-row-${rubricId}`);
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
