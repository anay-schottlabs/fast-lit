class Question {
    constructor({ number, question, options, correctIndex = null }) {
        this.number = number;
        this.question = question;
        this.options = options;
        this.correctIndex = correctIndex;
    }
}

class Passage {
    constructor({ id, text, questions }) {
        this.id = id;
        this.text = text;
        this.questions = questions.map((q) => new Question(q));
    }
}

// Placeholder question set shared by every stub passage below — swapped out
// once real comprehension questions are written per-passage.
function stubQuestions() {
    return [
        {
            number: 1,
            question: '[Placeholder] What was the passage mainly about?',
            options: { A: 'Placeholder option A', B: 'Placeholder option B', C: 'Placeholder option C', D: 'Placeholder option D' },
            correctIndex: 0
        },
        {
            number: 2,
            question: '[Placeholder] Which detail is supported by the passage?',
            options: { A: 'Placeholder option A', B: 'Placeholder option B', C: 'Placeholder option C', D: 'Placeholder option D' },
            correctIndex: 0
        },
        {
            number: 3,
            question: '[Placeholder] What can be inferred from the passage?',
            options: { A: 'Placeholder option A', B: 'Placeholder option B', C: 'Placeholder option C', D: 'Placeholder option D' },
            correctIndex: 0
        }
    ];
}

// Stub passage pool — placeholder text/questions only, kept short so the
// RSVP/timed trial flow is fast to click through during development. Swap
// these for the real study passages + citations separately; LabPage.vue only
// depends on each entry having { id, text, questions }.
const passages = [
    new Passage({
        id: 'stub1',
        text: 'This is placeholder passage one. It exists only to exercise the reading trial flow during development. Replace this text with a real study passage before running any actual sessions. The sentences here are intentionally plain and repetitive, since their content does not matter for testing timing, sequencing, or the comprehension quiz screens that follow a passage.',
        questions: stubQuestions()
    }),
    new Passage({
        id: 'stub2',
        text: 'This is placeholder passage two. Like the others in this stub pool, it stands in for a real passage that will be supplied later. Its word count is similar to its neighbors so that trial durations at each of the study speeds stay roughly comparable while the flow itself is being tested.',
        questions: stubQuestions()
    }),
    new Passage({
        id: 'stub3',
        text: 'This is placeholder passage three. Nothing about its content is meaningful; it is here purely so the trial sequencing logic has something to display and time. Once real passages are added, this entire pool can be replaced without touching any of the surrounding page logic.',
        questions: stubQuestions()
    }),
    new Passage({
        id: 'stub4',
        text: 'This is placeholder passage four. It fills the same role as the passages before it in this stub set: a short, disposable block of text used to verify that trials advance correctly, that timers behave as expected, and that quizzes appear at the right moments.',
        questions: stubQuestions()
    }),
    new Passage({
        id: 'stub5',
        text: 'This is placeholder passage five. Its only purpose is to be readable filler while the reading study flow is under construction. Word choice, tone, and subject matter are all irrelevant here, since none of it will be seen by an actual study participant.',
        questions: stubQuestions()
    }),
    new Passage({
        id: 'stub6',
        text: 'This is placeholder passage six. Along with the five before it, this rounds out a small pool large enough to cover every trial in a full run without repeating a passage. Real content and a real answer key can be dropped in later.',
        questions: stubQuestions()
    }),
    new Passage({
        id: 'stub7',
        text: 'This is placeholder passage seven, an extra entry beyond the six a full run actually needs, kept here as a bit of slack in the pool for testing edge cases like re-running the study multiple times in the same session.',
        questions: stubQuestions()
    }),
    new Passage({
        id: 'stub8',
        text: 'This is placeholder passage eight, the last of the extra slack entries in this stub pool. Everything about it — length, tone, structure — is deliberately unremarkable, since the goal is a working trial flow, not finished study content.',
        questions: stubQuestions()
    })
];

export { Question, Passage, passages };
