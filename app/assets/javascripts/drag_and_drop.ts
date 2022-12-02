import dragula from "dragula";
import { fetch } from "util.js";

type DragAndDropArguments = {
    table_selector: string,
    item_selector: string,
    item_data_selector: string,
    order_selector: string,
    order_data_selector: string,
    url_from_id: (courseId: string) => string;
}

function copyWidth(clone, original, tag=undefined): void {
    $(clone).width($(original).width());
    let cloneChildren;
    let originalChildren;
    if (tag) {
        cloneChildren = clone.getElementsByTagName(tag);
        originalChildren = original.getElementsByTagName(tag);
    } else {
        cloneChildren = clone.childNodes;
        originalChildren = original.childNodes;
    }
    for (let i = 0; i < cloneChildren.length; i++) { // make all children equally big
        $(cloneChildren[i]).width($(originalChildren[i]).width());
    }
}

/**
 * Initializes drag and drop on the page
 * @param { Object } args: a JSON with the following keys:
 * --table_selector: the id used to find the table that is used for drag and drop
 * --item_selector: the id used to find the selected item
 * --item_data_selector: the key used to retrieve data of the item
 * --order_selector: the id used to find the ordered items
 * --order_data_selector: the key used to retrieve data of the order
 * --url_from_id: a function that constructs the URL given an id
 */
function initDragAndDrop(args: DragAndDropArguments): void {
    const tableBody = document.querySelectorAll(args.table_selector)[0];

    dragula([tableBody], {
        moves: function (el, source, handle, sibling) {
            let containsDragHandle = handle.classList.contains("drag-handle");
            // if needed, search parents of handle for "drag-handle"
            let next = handle;
            while (next.parentElement && !containsDragHandle) {
                next = next.parentElement;
                containsDragHandle = next.classList.contains("drag-handle");
            }
            return containsDragHandle;
        },
        mirrorContainer: tableBody,
    })
        .on("cloned", function (clone, original, type) {
            copyWidth(clone, original, "td");
        })
        .on("drop", function () {
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
