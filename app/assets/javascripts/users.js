function init_make_teacher_buttons() {

    function init() {
        $(".toggleTeacher").click(function () {
        	var $parent = $(this).parent();
            $parent.children(".toggleTeacher").toggleClass("hidden");
        });
    }

    init();
}