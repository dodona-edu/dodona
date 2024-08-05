import dragula from "dragula";
import { fetch, getParentByClassName } from "utilities";

/**
 * Custom type for arguments of the drag and drop initialization
 * --table_selector: the id used to find the table that is used for drag and drop
 * --item_selector: the id used to find the selected item
 * --item_data_selector: the key used to retrieve data of the item
 * --order_selector: the id used to find the ordered items
 * --order_data_selector: the key used to retrieve data of the order
 * --url_from_id: a function that constructs the URL given an id
 */
type DragAndDropArguments = {
    table_selector: string,
    item_selector: string,
    item_data_selector: string,
    order_selector: string,
    order_data_selector: string,
    url_from_id: (courseId: string) => string;
}

function copyWidth(clone: Element, original: Element, tag: string): void {
    const cloneChildren = clone.getElementsByTagName(tag);
    const originalChildren = original.getElementsByTagName(tag);
    for (let i = 0; i < cloneChildren.length; i++) { // make all children equally big
        (cloneChildren[i] as HTMLElement).style.width = `${originalChildren[i].clientWidth.toString()}px`;
    }
}

function initDragAndDrop(args: DragAndDropArguments): void {
    const tableBody = document.querySelectorAll(args.table_selector)[0];

    dragula([tableBody], {
        moves: (el, source, handle) => {
            return handle.classList.contains("drag-handle") || getParentByClassName(handle, "drag-handle") !== null;
        },
        mirrorContainer: tableBody,
    })
        .on("cloned", (clone, original) => {
            copyWidth(clone, original, "td");
        })
        .on("drop", () => {
            const id = (document.querySelector(args.item_selector) as HTMLElement).dataset[args.item_data_selector];
            const order = Array.from(document.querySelectorAll(args.order_selector)).map( (el: HTMLElement) => {
                return parseInt(el.dataset[args.order_data_selector]);
            });

            fetch(args.url_from_id(id), {
                method: "POST",
                body: JSON.stringify({ order: JSON.stringify(order) }),
                headers: { "Content-type": "application/json" },
            });
        });
}

export { initDragAndDrop };
