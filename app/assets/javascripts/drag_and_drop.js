import dragula from "dragula";

function copyWidth(clone, original, tag=undefined){
    $(clone).width($(original).width());
    let cloneChildren, originalChildren;
    if (tag) {
        cloneChildren = clone.getElementsByTagName(tag);
        originalChildren = original.getElementsByTagName(tag);
    } else {
        cloneChildren = clone.childNodes;
        originalChildren = original.childNodes;
    }
    for(let i = 0; i < cloneChildren.length; i++){ // recursively make all children equally big
        $(cloneChildren[i]).width($(originalChildren[i]).width());
    }
}

/**
 * Initializes drag and drop on the page
 * @param args: a JSON with the following keys:
 * --table_selector: the id used to find the table that is used for drag and drop
 * --item_selector: the id used to find the selected item
 * --item_data_selector: the key used to retrieve data of the item
 * --order_selector: the id used to find the ordered items
 * --order_data_selector: the key used to retrieve data of the order
 * --url_from_id: a function that constructs the URL given an id
 */
function initDragAndDrop(args) {
    const tableBody = $(args.table_selector).get(0);
    dragula([tableBody], {
        moves: function (el, source, handle, sibling) {
            return $(handle).hasClass("drag-handle") || $(handle).parents(".drag-handle").length;
        },
        mirrorContainer: tableBody,
    })
    .on("cloned", function(clone, original, type){
        copyWidth(clone, original, "td");
    })
    .on("drop", function () {
        let id = $(args.item_selector).data(args.item_data_selector);
        let order = $(args.order_selector).map(function () {
            return $(this).data(args.order_data_selector);
        }).get();
        $.post(args.url_from_id(id), {
            order: JSON.stringify(order),
        });
    });
}

export {initDragAndDrop}
