function init_lightboxes() {
    $("img[class=lightbox]").click(function() {
        var imagesrc = $(this).attr('src');
        var alttext = $(this).attr('alt')
        alttext = alttext ? alttext : imagesrc.split("/").pop();
        Strip.show({
            url: imagesrc,
            caption: alttext,
            options: {
                side: 'top',
                maxHeight: 10
            },
        });
    });
};