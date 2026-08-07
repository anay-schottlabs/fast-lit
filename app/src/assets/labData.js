class Dataset {
    constructor(totalQuestions, totalPassages) {
        this.totalQuestions = totalQuestions;
        this.totalPassages = totalPassages;
    }
}

class Question {
    constructor({ number, question, options, highlightedText = undefined, correctIndex = null }) {
        this.number = number;
        this.question = question;
        this.options = options;
        this.highlightedText = highlightedText;
        this.correctIndex = correctIndex;
    }
}

class Passage {
    constructor({ id, text, questions }) {
        this.id = id;
        this.text = text;
        this.questions = questions.map(q => new Question(q));
    }
}

// Split out dataset and passages into their own variables using the classes above:
const dataset = new Dataset(72, 8);

const passages = [
    new Passage({
        id: "act1",
        text: "The bowl was perfect. Perhaps it was not what you'd select if you faced a shelf of bowls, and not the sort of thing that would inevitably attract a lot of attention at a crafts fair, yet it had real presence. It was as predictably admired as a mutt who has no reason to suspect he might be funny. Just such a dog, in fact, was often brought out (and in) along with the bowl.\n\nAndrea was a real-estate agent, and when she thought that some prospective buyers might be dog-lovers, she would drop off her dog at the same time she placed the bowl in the house that was up for sale. She would put a dish of water in the kitchen for Mondo, take his squeaking plastic frog out of her purse and drop it on the floor. He would pounce delightedly, just as he did every day at home, batting around his favorite toy. The bowl usually sat on a coffee table, though recently she had displayed it on top of a pine blanket chest and on a lacquered table. It was once placed on a cherry table beneath a glorious still-life painting, where it held its own.\n\nEveryone who has purchased a house or who has wanted to sell a house must be familiar with some of the tricks used to convince a buyer that the house is quite special: a fire in the fireplace in early evening; jonquils in a pitcher on the kitchen counter, where no one ordinarily has space to put flowers; perhaps the slight aroma of spring, made by a single drop of scent vaporizing from a lamp bulb.\n\nThe wonderful thing about the bowl, Andrea thought, was that it was both subtle and noticeable—a paradox of a bowl. Its glaze was the color of cream and seemed to glow no matter what light it was placed in. There were a few bits of color in it—tiny geometric flashes—and some of these were tinged with flecks of silver. They were as mysterious as cells seen under a microscope; it was difficult not to study them, because they shimmered, flashing for a split second, and then resumed their shape. Something about the colors and their random placement suggested motion. People who liked country furniture always commented on the bowl, but then it turned out that people who felt comfortable with opulence loved it just as much. But the bowl was not at all ostentatious, or even so noticeable that anyone would suspect that it had been put in place deliberately. They might notice the height of the ceiling on first entering a room, and only when their eye moved down from that, or away from the refraction of sunlight on a pale wall, would they see the bowl. Then they would go immediately to it and comment. Yet they always faltered when they tried to say something. Perhaps it was because they were in the house for a serious reason, not to notice some object.\n\nOnce, Andrea got a call from a woman who had not put in an offer on a house she had shown her. That bowl, she said—would it be possible to find out where the owners had bought that beautiful bowl? Andrea pretended that she did not know what the woman was referring to. A bowl, somewhere in the house? Oh, on a table under the window. Yes, she would ask, of course. She let a couple of days pass, then called back to say that the bowl had been a present and the people did not know where it had been purchased.\n\nShe was sure that the bowl brought her luck. Bids were often put in on houses where she had displayed the bowl. Sometimes the owners, who were always asked to be away or to step outside when the house was being shown, didn't even know that the bowl had been in their house. Once—she could not imagine how—she left it behind, and then she was so afraid that something might have happened to it that she rushed back to the house and sighed with relief when the owner opened the door. The bowl, Andrea explained—she had purchased a bowl and set it on the chest for safekeeping while she toured the house with the prospective buyers, and she . . . She felt like rushing past the frowning woman and seizing her bowl. The owner stepped aside. In the few seconds before Andrea picked up the bowl, she realized that the owner must have just seen that it had been perfectly placed, that the sunlight struck the bluer part of it. Her pitcher had been moved to the far side of the chest, and the bowl predominated. All the way home, Andrea wondered how she could have left the bowl behind. It was like leaving a friend at an outing—just walking off. Sometimes there were stories in the paper about families forgetting a child somewhere and driving to the next city. Andrea had only gone a mile down the road before she remembered.",
        questions: [
            {
                number: 1,
                question: "The point of view from which the passage is told is best described as that of a:",
                options: {
                    A: "first person narrator, present in the action, who relates events as they happen.",
                    B: "first person narrator, not present in the action, who relates events that happened in the past.",
                    C: "third person narrator, present in the action, who relates the thoughts and feelings of many characters.",
                    D: "third person narrator, not present in the action, who relates the thoughts and feelings of primarily one character.",
                },
                correctIndex: null,
            },
            {
                number: 2,
                question: "The passage as a whole can best be described as an exploration of the:",
                options: {
                    A: "career of a real estate agent and the agent's typically mundane transactions with clients.",
                    B: "special glaze on a bowl and why the glaze makes the bowl both subtle and noticeable.",
                    C: "perceived perfection of an object and that object's effect on people.",
                    D: "problems that can result from a person's unyielding focus on obtaining material goods.",
                },
                correctIndex: null,
            },
            {
                number: 3,
                question: "The passage most strongly suggests that a useful characteristic of the bowl, in terms of Andrea's purpose for the object, is the bowl's:",
                options: {
                    A: "universal appeal.",
                    B: "famous designer.",
                    C: "ostentatious look.",
                    D: "commercial availability.",
                },
                correctIndex: null,
            },
            {
                number: 4,
                question: "In the highlighted text, Andrea responds to an inquiry about her bowl and explains why her bowl was placed in a client's home with statements that can best be described as:",
                highlightedText: "The bowl, Andrea explained—she had purchased a bowl and set it on the chest for safekeeping while she toured the house with the prospective buyers, and she . . .",
                options: {
                    A: "vague generalizations.",
                    B: "absolute truths.",
                    C: "half-truths.",
                    D: "lies.",
                },
                correctIndex: null,
            },
            {
                number: 5,
                question: "In the passage, Andrea is characterized as believing that compared to most tricks used by real estate agents to impress potential buyers, her trick of placing the bowl in a home is:",
                options: {
                    A: "more humorous to potential buyers.",
                    B: "more obvious to potential buyers.",
                    C: "less familiar to potential buyers.",
                    D: "less enticing to potential buyers.",
                },
                correctIndex: null,
            },
            {
                number: 6,
                question: "According to the passage, the random placement of colors in the bowl's glaze creates a surface that:",
                options: {
                    A: "acts as a mirror.",
                    B: "seems to move.",
                    C: "appears cracked in the sunlight.",
                    D: "scatters prisms on the walls of a room.",
                },
                correctIndex: null,
            },
            {
                number: 7,
                question: "One main point of the highlighted paragraph is that:",
                highlightedText: "Once, Andrea got a call from a woman who had not put in an offer on a house she had shown her. That bowl, she said—would it be possible to find out where the owners had bought that beautiful bowl? Andrea pretended that she did not know what the woman was referring to. A bowl, somewhere in the house? Oh, on a table under the window. Yes, she would ask, of course. She let a couple of days pass, then called back to say that the bowl had been a present and the people did not know where it had been purchased.",
                options: {
                    A: "Andrea's bowl sometimes attracts more interest than does the house itself.",
                    B: "Andrea's bowl does not actually belong to her, but she hopes to find its owner.",
                    C: "Andrea is often asked about the bowl when a client puts in an offer on a house.",
                    D: "Andrea sometimes forgets where in a house she has placed the bowl.",
                },
                correctIndex: null,
            },
            
            {
                number: 8,
                question: "In the passage, the admiration the bowl receives is directly compared to the admiration received by:",
                options: {
                    A: "a mutt.",
                    B: "a plastic frog.",
                    C: "a cherry table.",
                    D: "the aroma of spring.",
                },
                correctIndex: null,
            },
            {
                number: 9,
                question: "The passage suggests that one reason prospective home buyers have difficulty sharing their thoughts about the bowl is that they realize:",
                options: {
                    A: "they are not visiting the home for the purpose of noticing decorative objects.",
                    B: "they do not want to reveal that they have the financial means to buy the bowl.",
                    C: "Andrea might start talking about the bowl instead of discussing the home that is for sale.",
                    D: "Andrea might find the bowl even more intriguing than they do.",
                },
                correctIndex: null,
            },
        ]
    }),
    new Passage({
        id: "act2",
        text: "Originally cultivated in the Ottoman Empire, tulips were introduced to Europe at the end of the sixteenth century and became wildly popular in the seventeenth century.\n\nOne crucial element of the beauty of the tulip that intoxicated the Dutch, the Turks, the French, and the English has been lost to us. To them the tulip was a magic flower because it was prone to spontaneous and brilliant eruptions of color. In a planting of a hundred tulips, one of them might be so possessed, opening to reveal the white or yellow ground of its petals painted, as if by the finest brush and steadiest hand, with intricate feathers or flames of a vividly contrasting hue. When this happened, the tulip was said to have \"broken,\" and if a tulip broke in a particularly striking manner—if the flames of the applied color reached clear to the petal's lip, say, and its pigment was brilliant and pure and its pattern symmetrical—the owner of that bulb had won the lottery. For the offsets of that bulb would inherit its pattern and hues and command a fantastic price. The fact that broken tulips for some unknown reason produced fewer and smaller offsets than ordinary tulips drove their prices still higher. Semper Augustus was the most famous such break.\n\nThe closest we have to a broken tulip today is the group known as the Rembrandts—so named because Rembrandt painted some of the most admired breaks of his time. But these latter-day tulips, with their heavy patterning of one or more contrasting colors, look clumsy by comparison, as if painted in haste with a thick brush. To judge from the paintings we have of the originals, the petals of broken tulips could be as fine and intricate as marbleized papers, the extravagant swirls of color somehow managing to seem both bold and delicate at once. In the most striking examples—such as the fiery carmine that Semper Augustus splashed on its pure white ground—the outbreak of color juxtaposed with the orderly, linear form of the tulip could be breathtaking, with the leaping, wayward patterns just barely contained by the petal's edge.\n\nAnna Pavord recounts the extraordinary lengths to which Dutch growers would go to make their tulips break, sometimes borrowing their techniques from alchemists, who faced what must have seemed a comparable challenge. Over the earth above a bed planted with white tulips, gardeners would liberally sprinkle paint powders of the desired hue, on the theory that rainwater would wash the color down to the roots, where it would be taken up by the bulb. Charlatans sold recipes believed to produce the magic color breaks; pigeon droppings were thought to be an effective agent, as was plaster dust taken from the walls of old houses. Unlike the alchemists, whose attempts to change base metals into gold reliably failed, now and then the would-be tulip changers would be rewarded with a good break, inspiring everybody to redouble their efforts.\n\nWhat the Dutch could not have known was that a virus was responsible for the magic of the broken tulip, a fact that, as soon as it was discovered, doomed the beauty it had made possible. The color of a tulip actually consists of two pigments working in concert—a base color that is always yellow or white and a second, laid-on color called an anthocyanin; the mix of these two hues determines the unitary color we see. The virus works by partially and irregularly suppressing the anthocyanin, thereby allowing a portion of the underlying color to show through. It wasn't until the 1920s, after the invention of the electron microscope, that scientists discovered the virus was being spread from tulip to tulip by Myzus persicae, the peach potato aphid. Peach trees were a common feature of seventeenth-century gardens.\n\nBy the 1920s the Dutch regarded their tulips as commodities to trade rather than jewels to display, and since the virus weakened the bulbs it infected (the reason the offsets of broken tulips were so small and few in number), Dutch growers set about ridding their fields of the infection. Color breaks, when they did occur, were promptly destroyed, and a certain peculiar manifestation of natural beauty abruptly lost its claim on human affection.\n\nI can't help thinking that the virus was supplying something the tulip needed, just the touch of abandon the flower's chilly formality called for. Maybe that's why the broken tulip became such a treasure in seventeenth-century Holland: the wayward color loosed on a tulip by a good break perfected the flower, even as the virus responsible set about destroying it.\n\nOn its face the story of the virus and the tulip would seem to throw a wrench into any evolutionary understanding of beauty.",
        questions: [
            {
                number: 10,
                question: "The main purpose of the passage is to:",
                options: {
                    A: "highlight changes in the flower industry from the seventeenth century through today.",
                    B: "examine the way certain plants have been represented in art over the centuries.",
                    C: "provide an overview of plant viruses and the way they affect the flower market.",
                    D: "explain a particular flower variation and how it has been perceived historically.",
                },
                correctIndex: null,
            },
            {
                number: 11,
                question: "The main point of the highlighted paragraph is that:",
                highlightedText: "The closest we have to a broken tulip today is the group known as the Rembrandts—so named because Rembrandt painted some of the most admired breaks of his time. But these latter-day tulips, with their heavy patterning of one or more contrasting colors, look clumsy by comparison, as if painted in haste with a thick brush. To judge from the paintings we have of the originals, the petals of broken tulips could be as fine and intricate as marbleized papers, the extravagant swirls of color somehow managing to seem both bold and delicate at once. In the most striking examples—such as the fiery carmine that Semper Augustus splashed on its pure white ground—the outbreak of color juxtaposed with the orderly, linear form of the tulip could be breathtaking, with the leaping, wayward patterns just barely contained by the petal's edge.",
                options: {
                    A: "modern Rembrandt tulips have been painted by many of today's most famous artists.",
                    B: "compared to seventeenth-century broken tulips, today's multicolored tulips are less visually appealing.",
                    C: "the tulip break known as Semper Augustus was a striking example of the seventeenth-century broken tulip.",
                    D: "Rembrandt was responsible for painting the most famous tulip breaks of his time.",
                },
                correctIndex: null,
            },
            {
                number: 12,
                question: "It can reasonably be inferred from the passage that some seventeenth-century tulip growers believed tulip breaks were mainly caused by:",
                options: {
                    A: "suppliers' storage conditions.",
                    B: "diseased tulip bulbs.",
                    C: "certain growing techniques.",
                    D: "certain weather patterns.",
                },
                correctIndex: null,
            },
            {
                number: 13,
                question: "The information in the highlighted text primarily functions to:",
                highlightedText: "The color of a tulip actually consists of two pigments working in concert—a base color that is always yellow or white and a second, laid-on color called an anthocyanin; the mix of these two hues determines the unitary color we see. The virus works by partially and irregularly suppressing the anthocyanin, thereby allowing a portion of the underlying color to show through.",
                options: {
                    A: "describe the range of potential tulip colors.",
                    B: "explain how the color variation in a broken tulip occurs.",
                    C: "argue that yellow and white are the only natural tulip colors.",
                    D: "indicate why broken tulips contain no anthocyanin.",
                },
                correctIndex: null,
            },
            {
                number: 14,
                question: "The highlighted paragraph differs from the rest of the passage in that it:",
                highlightedText: "I can't help thinking that the virus was supplying something the tulip needed, just the touch of abandon the flower's chilly formality called for. Maybe that's why the broken tulip became such a treasure in seventeenth-century Holland: the wayward color loosed on a tulip by a good break perfected the flower, even as the virus responsible set about destroying it.",
                options: {
                    A: "questions whether the virus that caused broken tulips was harmful to bulbs.",
                    B: "argues that growers should have dealt with broken tulips differently.",
                    C: "challenges the idea that broken tulips were beautiful.",
                    D: "presents a personal meditation on broken tulips.",
                },
                correctIndex: null,
            },
            {
                number: 15,
                question: "According to the passage, in the seventeenth century, the fact that broken tulip bulbs tended to produce fewer and smaller offsets compared to typical tulip bulbs resulted in:",
                options: {
                    A: "a decrease in the demand for broken tulips.",
                    B: "a fear among growers that broken tulips were diseased.",
                    C: "an increase in prices for broken tulips.",
                    D: "a desire among growers to plant a wider variety of crops.",
                },
                correctIndex: null,
            },
            {
                number: 16,
                question: "In the passage, the author compares broken tulips as they are represented in Rembrandt's paintings to:",
                options: {
                    A: "peach-tree blossoms.",
                    B: "paint powders sprinkled on the ground.",
                    C: "a painting hastily done with a thick brush.",
                    D: "intricately marbleized papers.",
                },
                correctIndex: null,
            },
            {
                number: 17,
                question: "The passage author most likely mentions that peach trees were a staple of seventeenth-century gardens to:",
                options: {
                    A: "highlight a crop favored by growers who did not cultivate tulips.",
                    B: "emphasize that peach trees are not as popular in gardens today.",
                    C: "explain how peach potato aphids spread the tulip virus.",
                    D: "compare tulips to another popular seventeenth-century crop.",
                },
                correctIndex: null,
            },
            {
                number: 18,
                question: "As it is used in the passage, the highlighted word \"abandon\" most nearly means:",
                highlightedText: "just the touch of abandon the flower's chilly formality called for",
                options: {
                    A: "uninhibitedness.",
                    B: "relinquishment.",
                    C: "retreat.",
                    D: "denial.",
                },
                correctIndex: null,
            },
        ]
    }),
];

// Compose labData object as before (if needed for backwards compatibility)
const labData = {
    dataset,
    passages,
};
