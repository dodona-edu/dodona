function initAddScoreTemplates(): void {
    document.querySelectorAll(".add-new-button").forEach(e => {
        e.addEventListener("click", event => {
            const evaluationExerciseId = (event.target as HTMLButtonElement).dataset.exerciseId;
            document.getElementById(`new-template-exercise-${evaluationExerciseId}`)
                .classList.toggle("hidden");
        });
    });
}

export { initAddScoreTemplates };
