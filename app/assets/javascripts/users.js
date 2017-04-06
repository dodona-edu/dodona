function init_make_teacher_buttons() {

    function init() {
        $(".toggleTeacher").click(function () {
            $(this).toggleClass("btn-success");
            $(this).toggleClass("btn-default");
        });
    }

    init();
}