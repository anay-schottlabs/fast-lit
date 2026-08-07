// Configuration for the /lab comprehension pilot study. Everything here is
// plain data on purpose — swap in real passages/questions/trials without
// touching any component code.

// Each trial pairs one passage with one reading speed. Order here is just
// the source order — LabPage.vue randomizes per participant and records the
// order actually shown (see trialOrderIndex in the trial record).
export const trials = [
    { passageId: 'p1', wpm: 250 },
    { passageId: 'p2', wpm: 350 },
    { passageId: 'p3', wpm: 450 },
    { passageId: 'p4', wpm: 550 },
];

// Placeholder passages, ~150-250 words each. Swap in the real, difficulty
// matched passages before running an actual session — these are filler text
// only meant to exercise the trial flow end-to-end.
export const passages = [
    {
        id: 'p1',
        text: `The history of the printing press begins in the fifteenth century, when Johannes Gutenberg
        introduced movable type to Europe. Before this invention, books were copied by hand, a slow and
        expensive process that limited how widely ideas could spread. Gutenberg's press combined oil based
        ink, a wooden press adapted from wine making, and individually cast metal letters that could be
        rearranged and reused. This meant that once a page of type was set, hundreds of identical copies
        could be produced quickly and cheaply. The first major work printed this way was a Latin Bible,
        prized today both for its religious significance and for its craftsmanship. Within decades, printing
        presses had spread across Europe, and the number of books in circulation grew from a few thousand
        to many millions. Scholars often credit the printing press with accelerating the Renaissance and the
        Reformation, since it allowed new ideas to travel faster than any government or institution could
        control. It also standardized spelling and grammar within languages, since printers needed consistent
        rules to set type efficiently. In many ways, the printing press was an early version of the
        information revolution that later came with radio, television, and the internet, each one lowering
        the cost of spreading an idea a little further than the last.`
    },
    {
        id: 'p2',
        text: `Coral reefs are sometimes called the rainforests of the sea because of how much biodiversity
        they support relative to their size. Although reefs cover less than one percent of the ocean floor,
        they are home to roughly a quarter of all known marine species. A reef is built slowly over
        thousands of years as tiny animals called coral polyps secrete calcium carbonate skeletons, layer
        upon layer, forming the hard structure that fish, crustaceans, and countless other organisms depend
        on for shelter and food. Coral polyps live in a close partnership with microscopic algae, which
        live inside their tissue and provide most of their energy through photosynthesis in exchange for a
        protected home. This partnership is delicate, and when water temperatures rise even slightly above
        normal for an extended period, the coral expels the algae in a stress response known as bleaching.
        A bleached coral is not dead, but it is starving, and prolonged bleaching events can kill entire
        reef systems. Because reefs also buffer coastlines from storms and support fishing economies for
        hundreds of millions of people, their decline is considered one of the clearest early warning signs
        of a changing climate.`
    },
    {
        id: 'p3',
        text: `In 1969, a small team of engineers, mathematicians, and astronauts worked together to land the
        first human beings on the surface of the Moon. The Apollo 11 mission required solving problems that
        had never been solved before, from designing a guidance computer with less processing power than a
        modern calculator to figuring out how two spacecraft could safely dock with each other while orbiting
        another world. Neil Armstrong and Buzz Aldrin descended to the lunar surface in the Eagle landing
        module while Michael Collins remained in orbit aboard the command module, ready to bring all three
        of them home. When Armstrong stepped onto the dusty gray surface, he described it as "one small step
        for man, one giant leap for mankind," a phrase that would be remembered for generations. The mission
        was the culmination of a decade long effort sparked partly by geopolitical competition and partly by
        genuine scientific curiosity about what lay beyond Earth. Apollo 11 proved that with enough
        coordination, funding, and willingness to take calculated risks, humanity could accomplish feats that
        had previously belonged only to fiction, opening the door to decades of further space exploration.`
    },
    {
        id: 'p4',
        text: `Honeybees communicate the location of food sources to each other using a behavior known as the
        waggle dance. When a scout bee finds a promising patch of flowers, it returns to the hive and performs
        a figure eight pattern on the vertical surface of the honeycomb, waggling its body rapidly during the
        straight segment of the pattern. The angle of that straight run relative to straight up on the comb
        indicates the direction of the food relative to the sun, while the duration of the waggle indicates
        how far away the food source is. Other bees in the hive crowd around the dancing scout, sensing the
        vibrations and following along to decode the message before flying out to the same location themselves.
        This system allows a colony to quickly redirect its foraging effort toward the richest nearby food
        sources without any single bee needing to understand the colony's overall strategy. Researchers have
        studied the waggle dance for decades as a striking example of complex communication arising from a
        very small brain, and some have even built robotic bees capable of performing a simplified version of
        the dance to influence real hive behavior in experiments.`
    },
];

// Placeholder comprehension questions, keyed by passage id. Each passage has
// 4-5 multiple choice questions with a zero-based correctIndex into options.
export const quizzes = {
    p1: [
        {
            question: 'Who introduced movable type to Europe in the fifteenth century?',
            options: ['Johannes Gutenberg', 'Martin Luther', 'Leonardo da Vinci', 'William Caxton'],
            correctIndex: 0
        },
        {
            question: 'What was the first major work printed with Gutenberg\'s press?',
            options: ['A dictionary', 'A Latin Bible', 'A collection of poems', 'A newspaper'],
            correctIndex: 1
        },
        {
            question: 'What existing technology was the printing press adapted from?',
            options: ['A weaving loom', 'A grain mill', 'A wine press', 'A pottery wheel'],
            correctIndex: 2
        },
        {
            question: 'According to the passage, what effect did printing have on language?',
            options: [
                'It had no effect on language',
                'It standardized spelling and grammar',
                'It eliminated regional dialects entirely',
                'It replaced Latin with English'
            ],
            correctIndex: 1
        },
        {
            question: 'What two historical movements does the passage say the printing press accelerated?',
            options: [
                'The Industrial Revolution and colonization',
                'The Renaissance and the Reformation',
                'The Enlightenment and the French Revolution',
                'The Crusades and the Renaissance'
            ],
            correctIndex: 1
        }
    ],
    p2: [
        {
            question: 'What percentage of the ocean floor do coral reefs cover?',
            options: ['Less than 1%', 'About 10%', 'About 25%', 'About 50%'],
            correctIndex: 0
        },
        {
            question: 'What do coral polyps use to build a reef\'s hard structure?',
            options: ['Silica', 'Calcium carbonate', 'Collagen', 'Chitin'],
            correctIndex: 1
        },
        {
            question: 'What do the algae living inside coral tissue provide?',
            options: ['Physical protection', 'Most of the coral\'s energy via photosynthesis', 'Reproductive cells', 'Camouflage color only'],
            correctIndex: 1
        },
        {
            question: 'What is coral bleaching a response to?',
            options: ['Prolonged elevated water temperatures', 'Excess sunlight only', 'Predation by fish', 'Low salinity'],
            correctIndex: 0
        },
        {
            question: 'Is a bleached coral necessarily dead?',
            options: ['Yes, bleaching always kills coral instantly', 'No, but it is starving and at risk', 'No, bleaching is purely cosmetic', 'Yes, but only in warm water'],
            correctIndex: 1
        }
    ],
    p3: [
        {
            question: 'Which mission first landed humans on the Moon?',
            options: ['Apollo 8', 'Apollo 11', 'Gemini 12', 'Apollo 13'],
            correctIndex: 1
        },
        {
            question: 'Who remained in orbit aboard the command module?',
            options: ['Buzz Aldrin', 'Neil Armstrong', 'Michael Collins', 'John Glenn'],
            correctIndex: 2
        },
        {
            question: 'What was the name of the lunar landing module?',
            options: ['Eagle', 'Falcon', 'Columbia', 'Intrepid'],
            correctIndex: 0
        },
        {
            question: 'What did Armstrong compare his first step on the Moon to?',
            options: [
                'A giant leap for mankind',
                'A new dawn for science',
                'A victory for his country',
                'The end of a long journey'
            ],
            correctIndex: 0
        },
        {
            question: 'According to the passage, what two forces partly motivated the Apollo program?',
            options: [
                'Military necessity and religion',
                'Geopolitical competition and scientific curiosity',
                'Commercial profit and tourism',
                'Environmental research and education'
            ],
            correctIndex: 1
        }
    ],
    p4: [
        {
            question: 'What behavior do honeybees use to communicate food locations?',
            options: ['The spiral dance', 'The waggle dance', 'The hover dance', 'The circle call'],
            correctIndex: 1
        },
        {
            question: 'What does the angle of the waggle run indicate?',
            options: ['The size of the food source', 'The temperature outside', 'The direction of the food relative to the sun', 'The number of scouts needed'],
            correctIndex: 2
        },
        {
            question: 'What does the duration of the waggle indicate?',
            options: ['The quality of the nectar', 'The distance to the food source', 'The size of the hive', 'The age of the scout bee'],
            correctIndex: 1
        },
        {
            question: 'How do other bees interpret the dance?',
            options: [
                'By tasting the dancer\'s wings',
                'By sensing vibrations and following along',
                'By smelling pheromones released during the dance',
                'By watching from a distance without contact'
            ],
            correctIndex: 1
        },
        {
            question: 'What have some researchers built to study the waggle dance?',
            options: ['Robotic bees', 'Miniature hives', 'Synthetic pollen', 'Bee translation software'],
            correctIndex: 0
        }
    ]
};
