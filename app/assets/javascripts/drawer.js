$(() => {
    let $toggleBlocks = $("[data-toggle-group]");
    $toggleBlocks.css("display", "none");

    const setGroup = grp => {
        $toggleBlocks.css("display", "none");
        $(`[data-toggle-group="${grp}"]`).css("display", "block");
        $(".drawer-list a").removeClass("active");
        $(`.drawer-list a[href="#${grp}"]`).addClass("active");
    };

    let groups = $toggleBlocks
        .map((i, e)=>e.attributes["data-toggle-group"].nodeValue).toArray();

    for (let group of groups) {
        if ($(document.location.hash).closest(`[data-toggle-group="${group}"]`).length > 0) {
            setGroup(group);
        }

        $(`[href="#${group}"]`).click(()=>{
            setGroup(group);
            return true;
        });
    }
});
