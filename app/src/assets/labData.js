// Configuration for the /lab comprehension pilot study. Everything here is
// plain data on purpose — swap in real passages/questions/trials without
// touching any component code.
//
// Passages/questions are drawn from the ACT official free online practice
// test (PSI-hosted sample exam). correctIndex is null for every question
// until the answer key is supplied — fill in 0=A, 1=B, 2=C, 3=D once known.

// Reading speeds (wpm) used in the study. Each speed gets trialsPerSpeed
// trials; which of the 8 passages fills each trial slot is chosen at random
// per participant in LabPage.vue, not fixed here — see beginRun().
export const wpmLevels = [250, 400, 550];
export const trialsPerSpeed = 2;

export const passages = [
    {
        id: 'act1',
        type: 'LITERARY NARRATIVE',
        title: 'Janus',
        attribution: 'This passage is adapted from the short story "Janus" by Ann Beattie (©1985 by The New Yorker Magazine, Inc.).',
        text: `The bowl was perfect. Perhaps it was not what you'd select if you faced a shelf of bowls, and not the sort of thing that would inevitably attract a lot of attention at a crafts fair, yet it had real presence. It was as predictably admired as a mutt who has no reason to suspect he might be funny. Just such a dog, in fact, was often brought out (and in) along with the bowl.

Andrea was a real-estate agent, and when she thought that some prospective buyers might be dog-lovers, she would drop off her dog at the same time she placed the bowl in the house that was up for sale. She would put a dish of water in the kitchen for Mondo, take his squeaking plastic frog out of her purse and drop it on the floor. He would pounce delightedly, just as he did every day at home, batting around his favorite toy. The bowl usually sat on a coffee table, though recently she had displayed it on top of a pine blanket chest and on a lacquered table. It was once placed on a cherry table beneath a glorious still-life painting, where it held its own.

Everyone who has purchased a house or who has wanted to sell a house must be familiar with some of the tricks used to convince a buyer that the house is quite special: a fire in the fireplace in early evening; jonquils in a pitcher on the kitchen counter, where no one ordinarily has space to put flowers; perhaps the slight aroma of spring, made by a single drop of scent vaporizing from a lamp bulb.

The wonderful thing about the bowl, Andrea thought, was that it was both subtle and noticeable—a paradox of a bowl. Its glaze was the color of cream and seemed to glow no matter what light it was placed in. There were a few bits of color in it—tiny geometric flashes—and some of these were tinged with flecks of silver. They were as mysterious as cells seen under a microscope; it was difficult not to study them, because they shimmered, flashing for a split second, and then resumed their shape. Something about the colors and their random placement suggested motion. People who liked country furniture always commented on the bowl, but then it turned out that people who felt comfortable with opulence loved it just as much. But the bowl was not at all ostentatious, or even so noticeable that anyone would suspect that it had been put in place deliberately. They might notice the height of the ceiling on first entering a room, and only when their eye moved down from that, or away from the refraction of sunlight on a pale wall, would they see the bowl. Then they would go immediately to it and comment. Yet they always faltered when they tried to say something. Perhaps it was because they were in the house for a serious reason, not to notice some object.

Once, Andrea got a call from a woman who had not put in an offer on a house she had shown her. That bowl, she said—would it be possible to find out where the owners had bought that beautiful bowl? Andrea pretended that she did not know what the woman was referring to. A bowl, somewhere in the house? Oh, on a table under the window. Yes, she would ask, of course. She let a couple of days pass, then called back to say that the bowl had been a present and the people did not know where it had been purchased.

She was sure that the bowl brought her luck. Bids were often put in on houses where she had displayed the bowl. Sometimes the owners, who were always asked to be away or to step outside when the house was being shown, didn't even know that the bowl had been in their house. Once—she could not imagine how—she left it behind, and then she was so afraid that something might have happened to it that she rushed back to the house and sighed with relief when the owner opened the door. The bowl, Andrea explained—she had purchased a bowl and set it on the chest for safekeeping while she toured the house with the prospective buyers, and she . . . She felt like rushing past the frowning woman and seizing her bowl. The owner stepped aside. In the few seconds before Andrea picked up the bowl, she realized that the owner must have just seen that it had been perfectly placed, that the sunlight struck the bluer part of it. Her pitcher had been moved to the far side of the chest, and the bowl predominated. All the way home, Andrea wondered how she could have left the bowl behind. It was like leaving a friend at an outing—just walking off. Sometimes there were stories in the paper about families forgetting a child somewhere and driving to the next city. Andrea had only gone a mile down the road before she remembered.`
    },
    {
        id: 'act2',
        type: 'INFORMATIONAL',
        title: 'The Botany of Desire',
        attribution: 'This passage is from the book The Botany of Desire: A Plant\'s-Eye View of the World by Michael Pollan (©2001 by Michael Pollan). Used by permission of Random House, an imprint and division of Penguin Random House LLC. All rights reserved.',
        text: `Originally cultivated in the Ottoman Empire, tulips were introduced to Europe at the end of the sixteenth century and became wildly popular in the seventeenth century.

One crucial element of the beauty of the tulip that intoxicated the Dutch, the Turks, the French, and the English has been lost to us. To them the tulip was a magic flower because it was prone to spontaneous and brilliant eruptions of color. In a planting of a hundred tulips, one of them might be so possessed, opening to reveal the white or yellow ground of its petals painted, as if by the finest brush and steadiest hand, with intricate feathers or flames of a vividly contrasting hue. When this happened, the tulip was said to have "broken," and if a tulip broke in a particularly striking manner—if the flames of the applied color reached clear to the petal's lip, say, and its pigment was brilliant and pure and its pattern symmetrical—the owner of that bulb had won the lottery. For the offsets of that bulb would inherit its pattern and hues and command a fantastic price. The fact that broken tulips for some unknown reason produced fewer and smaller offsets than ordinary tulips drove their prices still higher. Semper Augustus was the most famous such break.

The closest we have to a broken tulip today is the group known as the Rembrandts—so named because Rembrandt painted some of the most admired breaks of his time. But these latter-day tulips, with their heavy patterning of one or more contrasting colors, look clumsy by comparison, as if painted in haste with a thick brush. To judge from the paintings we have of the originals, the petals of broken tulips could be as fine and intricate as marbleized papers, the extravagant swirls of color somehow managing to seem both bold and delicate at once. In the most striking examples—such as the fiery carmine that Semper Augustus splashed on its pure white ground—the outbreak of color juxtaposed with the orderly, linear form of the tulip could be breathtaking, with the leaping, wayward patterns just barely contained by the petal's edge.

Anna Pavord recounts the extraordinary lengths to which Dutch growers would go to make their tulips break, sometimes borrowing their techniques from alchemists, who faced what must have seemed a comparable challenge. Over the earth above a bed planted with white tulips, gardeners would liberally sprinkle paint powders of the desired hue, on the theory that rainwater would wash the color down to the roots, where it would be taken up by the bulb. Charlatans sold recipes believed to produce the magic color breaks; pigeon droppings were thought to be an effective agent, as was plaster dust taken from the walls of old houses. Unlike the alchemists, whose attempts to change base metals into gold reliably failed, now and then the would-be tulip changers would be rewarded with a good break, inspiring everybody to redouble their efforts.

What the Dutch could not have known was that a virus was responsible for the magic of the broken tulip, a fact that, as soon as it was discovered, doomed the beauty it had made possible. The color of a tulip actually consists of two pigments working in concert—a base color that is always yellow or white and a second, laid-on color called an anthocyanin; the mix of these two hues determines the unitary color we see. The virus works by partially and irregularly suppressing the anthocyanin, thereby allowing a portion of the underlying color to show through. It wasn't until the 1920s, after the invention of the electron microscope, that scientists discovered the virus was being spread from tulip to tulip by Myzus persicae, the peach potato aphid. Peach trees were a common feature of seventeenth-century gardens.

By the 1920s the Dutch regarded their tulips as commodities to trade rather than jewels to display, and since the virus weakened the bulbs it infected (the reason the offsets of broken tulips were so small and few in number), Dutch growers set about ridding their fields of the infection. Color breaks, when they did occur, were promptly destroyed, and a certain peculiar manifestation of natural beauty abruptly lost its claim on human affection.

I can't help thinking that the virus was supplying something the tulip needed, just the touch of abandon the flower's chilly formality called for. Maybe that's why the broken tulip became such a treasure in seventeenth-century Holland: the wayward color loosed on a tulip by a good break perfected the flower, even as the virus responsible set about destroying it.

On its face the story of the virus and the tulip would seem to throw a wrench into any evolutionary understanding of beauty.`
    },
    {
        id: 'act3',
        type: 'INFORMATIONAL',
        title: 'Passage A and B: Hip-Hop Culture',
        attribution: 'Passage A is from the book Foundation: B-Boys, B-Girls, and Hip-Hop Culture in New York by Joseph G. Schloss (©2009 by Oxford University Press). Passage B is from the book The Tanning of America: How Hip-Hop Created a Culture That Rewrote the Rules of the New Economy by Steve Stoute with Mim Eichler Rivas (©2011 by Steve Stoute).',
        text: `Passage A by Joseph G. Schloss

[The term b-boying refers to break dancing.]

In the first sense of the term, hip-hop refers collectively to a group of related art forms in different media (visual, sound, movement) that were practiced in Afro-Caribbean, African American, and Latino neighborhoods in New York City in the 1970s. The term, when used in this sense, also refers to the events at which these forms were practiced, the people who practiced them, their shared aesthetic sensibility, and contemporary activities that maintain those traditions.

Perhaps the most important aspect of this variety of hip-hop is that it is unmediated, in the sense that most of the practices associated with it are both taught and performed in the context of face-to-face interactions between human beings. To some degree, this constitutes an intentional rejection of the mass media by its practitioners, but to a great extent it is just the natural result of the practices themselves. Activities like b-boying and graffiti writing are simply not well suited to the mass media. Although in both cases, brief attempts were made to bring these forms of expression into mainstream contexts (b-boying in a series of low-budget "breaksploition" movies in the early 1980s and graffiti as part of a short-lived gallery trend around the same time), neither developed substantially in those environments. This, it has been suggested, was not so much because the forms lacked appeal, but because—on an economic level—b-boying was an advertisement with no product. This reality is reflected in the phrase that is often used to refer to this branch of hip-hop: "hip-hop culture," which suggests something that is lived rather than bought and sold.

The second sense of the term hip-hop refers to a form of popular music that developed, or was developed, out of hip-hop culture. This hip-hop, also known as "rap music," resulted from the interaction between hip-hop culture and the preexisting music industry. As we would expect, this hip-hop features elements of both sensibilities. My students are often surprised when I point out that, even when hip-hop lyrics seem to reject every aspect of mainstream culture and morality, the one thing they almost never reject is a strict 16-bar verse structure derived from Tin Pan Alley pop music. But this should not be surprising. This hip-hop, in contrast to hip-hop culture, is deeply intertwined with the mass media and its needs, largely because it does have a product: records, CDs, MP3s, and ringtones.

Passage B by Steve Stoute

It wasn't until I was nine years old, late in 1979, that I even heard the words "hip" and "hop" strung together or was able to grasp the notion of what being a rapper actually meant. That was when, fatefully, I heard a record that changed my life (and pop culture) forever.

Like it's yesterday, I can still remember that moment over at my aunt's home in Brooklyn—where it seemed there was always a party under way with relatives and neighbors hanging out, a great spread of food, and new, hot music on the record player. Most stereo systems in those days could be adapted for the single two-sided records that were smaller and had the big hole in the middle (45 RPM) as well as the bigger records with the small holes (33⅓ RPM)—which were the full albums that had several songs on each side.

But as the intro plays to what I recognize as "Good Times" by the group Chic and I'm drawn into the living room because it's a familiar hit song from the previous summer, I encounter a record on the turntable that defies categorization. Instead of the sweet female lead vocals of that disco smash, I hear something totally different and spot a baby-blue label on the black vinyl record I've never seen before. Even though it's a twelve-inch disc, the size of an album, as I listen to the rhyming words being spoken—"Singin' on 'n' 'n' on 'n' on / The beat don't stop until the break of dawn / Singin' on 'n' 'n' on 'n' on on 'n' on / Like a hot buttered a pop da pop da pop dibbie dibbie pop da pop pop / Ya don't dare stop"—it hits me that this entire side is one long song.

Almost fifteen minutes long as it turns out. Or, to be exact, fourteen minutes and thirty-six seconds of pure fun laid over the thumping bass beat from the break of "Good Times" with sing-along words easy to remember and repeat. The record, I discover, is by an unknown group, the Sugarhill Gang, and is called "Rapper's Delight."

From then on, nobody ever has to tell me what rap is. It's whatever words are spoken, chanted, or talk-sung, or whatever philosophies, stories, or ideas are espoused, by the house party Master of Ceremonies.`
    },
    {
        id: 'act4',
        type: 'NATURAL SCIENCE',
        title: 'The Rise and Fall of the Living Fossil',
        attribution: 'This passage is from the article "The Rise and Fall of the Living Fossil" by Ferris Jabr (©2015 by Nautilus).',
        text: `The term "living fossil" refers to creatures that had emerged long ago and seemed to have stopped evolving.

Like all living fossils, crocodiles were thought to have emerged in the distant past and then stayed largely unchanged. The standard theory held that the crocodilian species we know today originated in Africa during the Cretaceous (145 to 66 million years ago), when the seven continents were much closer together. As the continents drifted apart, the crocodilians went with them, explaining how they ended up in a band of tropics encircling the globe. If that were true, then modern crocodilian species should be very different from one another at the level of genes and molecules, because there would have been more than enough time for substantial mutations to accumulate. By the 1990s, however, molecular analysis revealed that immune system molecules conserved across living crocodilian species were remarkably similar in structure and behavior.

Intrigued by this puzzle, a post-doctoral research fellow at the University of Washington named Jamie Oaks began collecting DNA samples from all 23 living crocodilian species, comparing sections of the genome where mutations were most likely to have appeared. Oaks did not find nearly as many differences between the modern crocodilian genomes as one would expect had those species diverged all the way back in the Cretaceous. He concluded that modern crocodilian species split from their last common ancestor between 8 and 13 million years ago, not long before ancient hominins split from their last common ancestor with chimpanzees. The living fossil theory of crocodiles had overestimated their evolutionary age by about a factor of 10.

Oaks also noticed something odd about the DNA samples he had acquired from the iconic Nile crocodiles (Crocodylus niloticus): they did not match up with each other. In fact, the variation between them was great enough to suggest that he was looking at two distinct species. If so, then not only were modern crocodiles much too young to be living fossils, but they had also continued to speciate after diverging from their basal ancestor—something living fossils are not supposed to do. On its own, Oaks' study was intriguing, but not enough to convince the larger scientific community to cleave the Nile crocodile into two species.

Unbeknownst to him, however, a separate team of scientists was preparing to corroborate his results. In the early 2000s, on an excursion to Chad, the wildlife conservationist Michael Klemens encountered some odd little crocodiles in a desert oasis. They were so docile that he and his companions could swim beside them without concern. He took a tissue sample from one that had recently perished and sent it to the American Museum of Natural History in New York City, where Evon Hekkala, an assistant professor at Fordham University studying crocodilian diversity, sequenced its genome. When she compared the docile croc's DNA to other Nile crocodiles, she noticed some rather striking differences. Could these tame crocs be an entirely distinct species?

DNA analysis of 123 African crocodiles—as well as 57 separate samples from museum specimens, including crocodiles mummified in ancient Egypt—confirmed her suspicion. In a few sections of their respective genomes, all the mild-mannered crocs would have one DNA sequence, and all the typical Nile crocs another. They even had different numbers of chromosomes. "That made us very confident that there were actually two different populations and they were not mixing their DNA," Hekkala says. The two different species had diverged between 3 and 6 million years ago: Crocodylus niloticus in the East and the smaller, less aggressive Crocodylus suchus in the West. The vast majority of mummified crocodiles were C. suchus, suggesting that ancient Egyptians had recognized the difference.

Together, Hekkala, Oaks, and other scientists helped redraw the map of how crocodilians evolved in space and time, and conclusively removed them from the category of living fossils.`
    },
    {
        id: 'act5',
        type: 'LITERARY NARRATIVE',
        title: 'Passage A and B: Brooklyn Was Mine',
        attribution: 'Passage A is from the essay "A Windstorm in Downtown Brooklyn" by Robert Sullivan, and Passage B is from the essay "Down the Manhole" by Elizabeth Gaffney, both from the collection Brooklyn Was Mine, edited by Chris Knutsen and Valerie Steiker (©2008 by Chris Knutsen and Valerie Steiker).',
        text: `Passage A by Robert Sullivan

The Hebrew word for wind is also the Hebrew word for spirit, ruah, and when I look at the wind I look at something immeasurable, spiritlike, a climactic feature of a soul or souls. Try as I may, I still can't predict the wind in downtown Brooklyn, nor can I even imagine how the wind blew when Walt Whitman stepped out on the corner of Cranberry Street that is no longer there, or how it will feel when downtown Brooklyn is redeveloped, or "utilized." I can feel it though. Especially I can feel the vortex, which draws me, calls to me. When it is windy elsewhere in New York or the world and I am far from the vortex, I think of it, imagine the swirl. Often I walk my daughter, who is eleven, through the vortex on her way back and forth to school, even though it's a little out of our way—after years of forced wind-watching, her older brother walks alone now, noticing, I hope, the wind on his own. On Saturday mornings, if we go to the farmer's market, we buy doughnuts and cider and sit on the benches in Columbus Park at the steps of Borough Hall, and wait and see what the wind will blow up. We face the Court-Montague Building and a London plane tree whose branches are notable among Brooklyn trees for their lack of plastic shopping bags. The wind rips the bags away.

Six years ago, I was with my son, who was ten at the time, and we were on our way to his school when I saw an entire stack of newspapers go up into the air, a trashy celebration! We were on Court Street, just about to the corner of Montague, when we passed a newsstand. The man selling the papers was doing a pretty good job holding down copies of the Times and the Post considering he had the not-so-good idea of setting up a newsstand inside the vortex, but he was having trouble with the Daily News, which eventually escaped, almost the whole stack, and was then whipped quickly and frantically into the vortex. In a second, the corner of Court and Montague had headlines all over it, the pages doing flip-flops, and then floating out into the street. In another second the sheets of paper began flying up, up, up. My son and I stepped back from the building and waited and watched as, at last, one sheet slowly climbed all forty-two stories of the Court-Montague Building. (A couple of days later, the newsstand relocated two blocks away.)

Passage B by Elizabeth Gaffney

My parents, as artists, were eager to have their children out discovering beauty in the pedestrian, complexity in the mundane, and they understood child psychology pretty well. Looking for these things underfoot, where few expected to find anything of value, was just the right kind of fun and worked better than yet another trip to the MoMA. We didn't have to behave. We were allowed, nay required, to touch. My parents believed that embedding beautiful designs in the asphalt and the sidewalks was a quintessentially democratic, political act. When we went out, we considered not just manhole covers but fire hydrants, alarm boxes, street and traffic lights, signage. They were interested in urban renewal and preservation, and so the ideas of street furniture and the livability of the street were important to them. We rated what we saw, and talked about why we did or didn't like it. To me, the very idea of street furniture was thrilling—it conjured images of nestling in the cushions of imaginary street-corner sofas and jumping on nonexistent double beds. My mother in particular was also a history buff, and so the connection of the manhole covers to Brooklyn's past was important. Most of them were old; we tried to figure out exactly how old from the names on them and the wear they had undergone. Some were rubbed so smooth there was nothing to make a rubbing of, and my mind boggled to think of the forces that could scrape such heavy metal down to nothing. When my mother explained that the metal wheels of horse-drawn vehicles wore the street down harder than modern rubber tires filled with air, I was catapulted into a new understanding of a previous era. The past had never seemed very believable to me, until then. People might have gone around riding horses and wearing bonnets somewhere out West, say where Little House on the Prairie had transpired, but not on the streets I inhabited. But thanks to manhole covers and several stretches of street still paved with Belgian blocks, not asphalt—also pointed out by my mother—I could suddenly fathom that Brooklyn had been something different once too. History had happened here.`
    },
    {
        id: 'act6',
        type: 'INFORMATIONAL',
        title: 'Welcome to Subirdia',
        attribution: 'This passage is from the book Welcome to Subirdia: Sharing Our Neighborhoods with Wrens, Robins, Woodpeckers, and Other Wildlife by John M. Marzluff (©2014 by John M. Marzluff, reproduced with permission of Yale University Press).',
        text: `Do not covet your neighbor's lawn. Having a "perfect" lawn is an original sin of most Americans. Our love of lawn is rooted in our history as a former British colony, and perhaps even in our evolution on short-grass savannahs, where ancestral hominids found safety from predators. I mowed lawns for a living as a kid. So did my brothers and most of our friends. When we weren't cutting them, we played or relaxed on them. Frederick Law Olmsted, the father of suburbia, espoused the value of lawns as giving his neighborhoods a "sense of ampleness, greenness, and community." Many suburbanites foster lawns to boost the value of their homes, as safe havens for their kids, or as firebreaks. Some see lawns as art, as proof of our domination over nature, or as a way to gain prestige among their neighbors. Whatever the reason, most ecologists agree that the ubiquity of the lawn has outstripped its benefits. Domination of suburbia by lawn constrains the diversity of birds that could be supported. Robins, starlings, crows, wagtails, oystercatchers, and a few other birds forage in lawns, but to my knowledge, not a single species of bird, mammal, reptile, or amphibian reproduces and carries out its other life functions in the modern lawn.

In 2005, 2 percent of the coterminous United States, some forty million acres of land, was lawn. Nearly every bit was composed of only a few nonnative grass species. These invaders are regularly mowed to a low, even height and kept continuously green and free of weeds and pests. To maintain this sea of grass Americans annually spend $30 billion. They use eight hundred million gallons of gas, seven billion gallons of water, three million tons of nitrogen fertilizer, and thirty thousand tons of pesticide. The use of pesticides alone is ten times greater than used by the average farmer and includes chemicals that disrupt normal hormone function and reproduction, are suspected to cause cancer, and are banned in other countries. Simply filling up gas-powered lawnmowers is an ecological disaster of the highest order; seventeen million gallons of gas are spilled annually.

Concern about lawns has sparked a great deal of debate, creative thought, and neighbor-to-neighbor strife. In 1991, a savvy group of graduate students and faculty from Yale University's School of Forestry and Environmental Studies joined their colleagues in the School of Art and Architecture to consider how Americans could redesign their lawns. The resulting book details the history of lawns and charts a plan for those who wish to follow the first commandment. Lawn owners can increase bird use of their turf by reducing its extent, bordering it with shrubs, shading it with trees, mowing it with hand- or electric-powered machines, and skipping the fertilizers and pesticides. Doing this produces what the students and faculty refer to as a "Freedom Lawn." The plant composition of such lawns diversifies into a rich mix of grasses, forbs, and flowers pollinated and grazed by native, beneficial insects, which in turn are eaten by birds and other animals.

The less often a lawn is mowed, the more likely it is to be used by an array of animals. A less-disturbed lawn will attract goldfinches to ripe dandelion seeds, provide nest sites under tussocks for juncos and sparrows, and harbor frogs, turtles, and small mammals such as moles and voles.

Those who adopt Freedom Lawns buck a multinational industry heavily invested in producing seed, sod, fertilizer, pesticide, irrigation and lawn equipment, and service for those twenty-six million American homes that contract out their lawn care. But the pressure to conform is often more immediate. Neighbors who tolerate shaggy lawns are often thought of as laggards, negligent of their civic duty. As Michael Pollan, author of The Omnivore's Dilemma, notes: "That subtle yet unmistakable frontier, where the crew-cut lawn rubs up against a shaggy one, is a scar on the face of suburbia—an intolerable hint of trouble in paradise."`
    },
    {
        id: 'act7',
        type: 'NATURAL SCIENCE',
        title: 'Spiders: Web of Intrigue',
        attribution: 'This passage is adapted from the article "Spiders: Web of Intrigue" by Katherine Bourzac (©2015 by Springer Nature). The graphic is adapted from the article "Spider Silk–Inspired Artificial Fibers" by Jiatian Li et al. (©2021 The Authors, Wiley-VCG GmbH).',
        text: `A Madagascan bark spider releases a silk dragline into the air. The wind carries the thin threads to the other side of a river, where they land on foliage on the opposite bank 25 metres away. The bark spider (Caerostris darwini) then stretches the bridgeline to establish tension, reinforces it, and draws on a palette of other silks, stretchier or stickier as needed, to fashion a web to capture the bugs flying over the water.

C. darwini's bridging silk is the world's toughest known biomaterial—it is even tougher than steel fibre. But C. darwini's versatility in producing different kinds of silk is not unique. Many spiders can spin several silks: stiff, structural strands to stabilize their webs; gooey, stretchy spirals to capture flying insects; adhesive pads to anchor their homes in place; and extraordinarily robust draglines from which to hang.

The remarkable mechanical properties of these natural fibres have attracted the attention of materials scientists. Researchers are looking to arachnids and other silk makers for ideas about how to make new structural materials for bridges and vehicles, dirt-resistant adhesives for climbing robots and sturdy polymers for biomedical devices. Many silks bring together properties that are not readily present in man-made materials—the extreme toughness and elasticity seen in spider threads is one example. Silk proteins can be moulded like plastic or perform optical functions like silicon. Yet because they're organic, biological materials, silks are environmentally friendly and biocompatible. Silk proteins can be fashioned into films that can be implanted in the body, releasing drugs as they dissolve. This combination of features is unavailable in polyester or collagen or anything else, says David Kaplan, an early proponent of high-tech biomedical silk at Tufts University in Medford, Massachusetts. "There's clearly a need for new biomaterials," he says. For Kaplan and others, silk is the best way to meet that need.

Silk evolved independently in many invertebrates, including spiders, honeybees and silkworms. Individual spiders can make as many as six different kinds of silk proteins (and two glue proteins), each of which has evolved over the creatures' 400 million years of natural history. Each spider species uses its own variations of these proteins to make many different types of thread.

"We think that a primordial spider had one kind of silk, and then there were multiple events when the gene duplicated and evolved," says Cheryl Hayashi, a spider specialist at the University of California, Riverside. The species that are more closely related to these ancestors, such as tarantulas and trapdoor spiders, make silks of simple designs—messy tangles to trap walking insects, for example, using fewer types of silk. Other spiders evolved to make more complex spiralling orb webs, in which different regions are composed of different kinds of silk—some optimized for capturing prey, others for structural support of large web designs.

This evolutionary bounty has happy implications for engineers looking to put spider silk into human service. If a design calls for a fibre with a particular ratio of strength to stretchiness, "it's probably already been invented" by one of the tens of thousands of types of spider, says Hayashi.

Most research has centred on taking advantage of the toughness of spider silk—in materials science, toughness is a measure of how much energy it takes to break something. Materials such as spider silk are both strong and elastic. A large insect that flies into a spiderweb at top speed stretches the superfine fibres in the web but does not break them.

The toughest silks are found in spider draglines, which researchers are studying intensely. Spiders use draglines to dangle safely, to make the frames of their webs, and for situations in which resistance to breakage is paramount. In a scene from the 2004 movie Spider-Man 2, the eponymous superhero stops a runaway New York City subway train with his webbing, which is not too far of a stretch from reality.

Mechanical Properties of Natural and Synthetic Fibers.
Bark spider MA silk* — Strength (GPa): 1.6, Elasticity (%): 52, Toughness (MJ/m3): 354.
Silver garden spider flag silk† — Strength (GPa): 0.095, Elasticity (%): 465, Toughness (MJ/m3): 75.
Domestic silkworm silk — Strength (GPa): 0.6, Elasticity (%): 18, Toughness (MJ/m3): 70.
Nylon fiber — Strength (GPa): 0.95, Elasticity (%): 18, Toughness (MJ/m3): 80.
Kevlar 49 fiber — Strength (GPa): 3.6, Elasticity (%): 2.7, Toughness (MJ/m3): 50.
Carbon fiber — Strength (GPa): 4, Elasticity (%): 1.3, Toughness (MJ/m3): 25.
High-tensile steel fiber — Strength (GPa): 1.5, Elasticity (%): 0.8, Toughness (MJ/m3): 6.
*MA silk: non-sticky; used to make draglines and bridgelines and to anchor webs
†flag silk: sticky; used to capture prey in webs`
    },
    {
        id: 'act8',
        type: 'INFORMATIONAL',
        title: 'Native American Film outside the Margins of Filmmaking',
        attribution: 'This passage is from the article "Native American Film outside the Margins of Filmmaking" by Beverly R. Singer, reproduced from Great Plains Quarterly with permission from the University of Nebraska Press (©2014 by University of Nebraska Press).',
        text: `To manifest oneself as a filmmaker evokes such traditional professional titles as lawyer, doctor, engineer, writer, teacher, and plumber, where established institutional access is built on hierarchy and where acceptance into the profession opens opportunities for employment. One of those doors of access to filmmaking was opened to Native Americans in an exchange that took place at the Sundance Film Festival in 1997. Along with other Native filmmakers, including actor and producer Gary Farmer (Cayuga), I was invited that year to the festival to screen our productions. While there, we were invited to a consultation with the Sundance Institute executive staff to discuss how to enhance and improve the production of Native-made films to make them competitive with any film in the program. Robert Redford, founder of the Sundance Institute and Sundance Film Festival, was not present at that meeting, but we were told he was aware of it. When asked how the Sundance Institute could help improve the participation of Native American films at the Sundance Festival, we found the conversation wavering from helping to fund filmmakers, to the need for professional training and support for distribution of films.

Of most interest to me during the meeting was the discussion of the quality of films produced by Native American filmmakers. In evidence was a demonstration of the power held by the Sundance Festival to promote films that fit specific aesthetic preferences and expectations by festival audiences comprised of film critics, entrepreneurs, and Hollywood "types." To that end, Native American films had not yet achieved that appeal, but executive staff members thought it was possible. Hearing the familiar phrase "We really do want Native American participation," I instinctively sensed that little progress would be made toward "improving" Native filmmaking efforts if we did not become part of the system that made decisions. Maybe it was the timing, the place, or a release of the spirit of true collaboration that led me to say, "If we are to be taken seriously and respected, we need to be at the table helping to make decisions at the Sundance Institute's headquarters where you plan programs and decide policy." I suggested that the Sundance Institute hire a Native American as a key staff member to help identify and promote Native filmmaking, someone who could work from the inside and be at the table where decisions were made. The first Native American staff member, Heather Rae (Cherokee), was hired in that capacity by the Sundance Institute, which led to her own successful film production work.

Progress on behalf of Native filmmaking by the Sundance Institute through its production labs provided initial support for the production of Smoke Signals (1998), as noted by Joanna Hearne in her critical study of Smoke Signals: Native Cinema Rising. Hearne endorses Smoke Signals as a major event:

The film can be seen as a landmark "first" in American film history—although it is important to remember the long history of Native filmmaking that came before Smoke Signals—and it can also be seen as a self-positioned first introduction to Native perspectives and Native filmmaking for many of its viewers. . . . As an intervention, Smoke Signals challenges widely accepted misconceptions about Native Americans. Its "firsts" can be seen in different ways as inaugurating a new generation of Native film production; as an important but also problematic industry marketing category; as part of a critical paradigm based on sovereignty; and as a strategic creation of politicized space for Indigenous identity in the public mediascape. (xv–xvi).

Hearne's extensive review and close readings of the film's production and major players, including the film's scriptwriter, Sherman Alexie, and film director, Chris Eyre, revives the energy surrounding the theatrical release of Smoke Signals. I endorse Hearne's willingness to take up the study years after the film's release, but I have to ask, "What is the second act for Native cinema?" Hearne's full attention to Smoke Signals is a combination of personal stories about the scripting and directorial decision-making processes and the actors' contributions; moreover, her critical discussion carefully articulates what cultural elements, including pop and Native culture, produced the film's crossover appeal to audiences on multiple levels.

Although the film's glow has receded somewhat, the direction of Native American filmmaking has led to measurable success and growth internationally.`
    },
];

export const quizzes = {
    act1: [
        {
            question: 'The point of view from which the passage is told is best described as that of a:',
            options: [
                'first person narrator, present in the action, who relates events as they happen.',
                'first person narrator, not present in the action, who relates events that happened in the past.',
                'third person narrator, present in the action, who relates the thoughts and feelings of many characters.',
                'third person narrator, not present in the action, who relates the thoughts and feelings of primarily one character.',
            ],
            correctIndex: null
        },
        {
            question: 'The passage as a whole can best be described as an exploration of the:',
            options: [
                'career of a real estate agent and the agent\'s typically mundane transactions with clients.',
                'special glaze on a bowl and why the glaze makes the bowl both subtle and noticeable.',
                'perceived perfection of an object and that object\'s effect on people.',
                'problems that can result from a person\'s unyielding focus on obtaining material goods.',
            ],
            correctIndex: null
        },
        {
            question: 'The passage most strongly suggests that a useful characteristic of the bowl, in terms of Andrea\'s purpose for the object, is the bowl\'s:',
            options: [
                'universal appeal.',
                'famous designer.',
                'ostentatious look.',
                'commercial availability.',
            ],
            correctIndex: null
        },
        {
            question: 'In the highlighted text, Andrea responds to an inquiry about her bowl and explains why her bowl was placed in a client\'s home with statements that can best be described as (“The bowl, Andrea explained—she had purchased a bowl and set it on the chest for safekeeping while she toured the house with the prospective buyers, and she . . .”):',
            options: [
                'vague generalizations.',
                'absolute truths.',
                'half-truths.',
                'lies.',
            ],
            correctIndex: null
        },
        {
            question: 'In the passage, Andrea is characterized as believing that compared to most tricks used by real estate agents to impress potential buyers, her trick of placing the bowl in a home is:',
            options: [
                'more humorous to potential buyers.',
                'more obvious to potential buyers.',
                'less familiar to potential buyers.',
                'less enticing to potential buyers.',
            ],
            correctIndex: null
        },
        {
            question: 'According to the passage, the random placement of colors in the bowl\'s glaze creates a surface that:',
            options: [
                'acts as a mirror.',
                'seems to move.',
                'appears cracked in the sunlight.',
                'scatters prisms on the walls of a room.',
            ],
            correctIndex: null
        },
        {
            question: 'One main point of the highlighted paragraph is that (“Once, Andrea got a call from a woman who had not put in an offer on a house she had shown her. That bowl, she said—would it be possible to find out where the owners had bought that beautiful bowl? Andrea pretended that she did not know what the woman was referring to. A bowl, somewhere in the house? Oh, on a table under the window. Yes, she would ask, of course. She let a couple of days pass, then called back to say that the bowl had been a present and the people did not know where it had been purchased.”):',
            options: [
                'Andrea\'s bowl sometimes attracts more interest than does the house itself.',
                'Andrea\'s bowl does not actually belong to her, but she hopes to find its owner.',
                'Andrea is often asked about the bowl when a client puts in an offer on a house.',
                'Andrea sometimes forgets where in a house she has placed the bowl.',
            ],
            correctIndex: null
        },
        {
            question: 'In the passage, the admiration the bowl receives is directly compared to the admiration received by:',
            options: [
                'a mutt.',
                'a plastic frog.',
                'a cherry table.',
                'the aroma of spring.',
            ],
            correctIndex: null
        },
        {
            question: 'The passage suggests that one reason prospective home buyers have difficulty sharing their thoughts about the bowl is that they realize:',
            options: [
                'they are not visiting the home for the purpose of noticing decorative objects.',
                'they do not want to reveal that they have the financial means to buy the bowl.',
                'Andrea might start talking about the bowl instead of discussing the home that is for sale.',
                'Andrea might find the bowl even more intriguing than they do.',
            ],
            correctIndex: null
        },
    ],
    act2: [
        {
            question: 'The main purpose of the passage is to:',
            options: [
                'highlight changes in the flower industry from the seventeenth century through today.',
                'examine the way certain plants have been represented in art over the centuries.',
                'provide an overview of plant viruses and the way they affect the flower market.',
                'explain a particular flower variation and how it has been perceived historically.',
            ],
            correctIndex: null
        },
        {
            question: 'The main point of the highlighted paragraph is that (“The closest we have to a broken tulip today is the group known as the Rembrandts—so named because Rembrandt painted some of the most admired breaks of his time. But these latter-day tulips, with their heavy patterning of one or more contrasting colors, look clumsy by comparison, as if painted in haste with a thick brush. To judge from the paintings we have of the originals, the petals of broken tulips could be as fine and intricate as marbleized papers, the extravagant swirls of color somehow managing to seem both bold and delicate at once. In the most striking examples—such as the fiery carmine that Semper Augustus splashed on its pure white ground—the outbreak of color juxtaposed with the orderly, linear form of the tulip could be breathtaking, with the leaping, wayward patterns just barely contained by the petal\'s edge.”):',
            options: [
                'modern Rembrandt tulips have been painted by many of today\'s most famous artists.',
                'compared to seventeenth-century broken tulips, today\'s multicolored tulips are less visually appealing.',
                'the tulip break known as Semper Augustus was a striking example of the seventeenth-century broken tulip.',
                'Rembrandt was responsible for painting the most famous tulip breaks of his time.',
            ],
            correctIndex: null
        },
        {
            question: 'It can reasonably be inferred from the passage that some seventeenth-century tulip growers believed tulip breaks were mainly caused by:',
            options: [
                'suppliers\' storage conditions.',
                'diseased tulip bulbs.',
                'certain growing techniques.',
                'certain weather patterns.',
            ],
            correctIndex: null
        },
        {
            question: 'The information in the highlighted text primarily functions to (“The color of a tulip actually consists of two pigments working in concert—a base color that is always yellow or white and a second, laid-on color called an anthocyanin; the mix of these two hues determines the unitary color we see. The virus works by partially and irregularly suppressing the anthocyanin, thereby allowing a portion of the underlying color to show through.”):',
            options: [
                'describe the range of potential tulip colors.',
                'explain how the color variation in a broken tulip occurs.',
                'argue that yellow and white are the only natural tulip colors.',
                'indicate why broken tulips contain no anthocyanin.',
            ],
            correctIndex: null
        },
        {
            question: 'The highlighted paragraph differs from the rest of the passage in that it (“I can\'t help thinking that the virus was supplying something the tulip needed, just the touch of abandon the flower\'s chilly formality called for. Maybe that\'s why the broken tulip became such a treasure in seventeenth-century Holland: the wayward color loosed on a tulip by a good break perfected the flower, even as the virus responsible set about destroying it.”):',
            options: [
                'questions whether the virus that caused broken tulips was harmful to bulbs.',
                'argues that growers should have dealt with broken tulips differently.',
                'challenges the idea that broken tulips were beautiful.',
                'presents a personal meditation on broken tulips.',
            ],
            correctIndex: null
        },
        {
            question: 'According to the passage, in the seventeenth century, the fact that broken tulip bulbs tended to produce fewer and smaller offsets compared to typical tulip bulbs resulted in:',
            options: [
                'a decrease in the demand for broken tulips.',
                'a fear among growers that broken tulips were diseased.',
                'an increase in prices for broken tulips.',
                'a desire among growers to plant a wider variety of crops.',
            ],
            correctIndex: null
        },
        {
            question: 'In the passage, the author compares broken tulips as they are represented in Rembrandt\'s paintings to:',
            options: [
                'peach-tree blossoms.',
                'paint powders sprinkled on the ground.',
                'a painting hastily done with a thick brush.',
                'intricately marbleized papers.',
            ],
            correctIndex: null
        },
        {
            question: 'The passage author most likely mentions that peach trees were a staple of seventeenth-century gardens to:',
            options: [
                'highlight a crop favored by growers who did not cultivate tulips.',
                'emphasize that peach trees are not as popular in gardens today.',
                'explain how peach potato aphids spread the tulip virus.',
                'compare tulips to another popular seventeenth-century crop.',
            ],
            correctIndex: null
        },
        {
            question: 'As it is used in the passage, the highlighted word "abandon" most nearly means (“just the touch of abandon the flower\'s chilly formality called for”):',
            options: [
                'uninhibitedness.',
                'relinquishment.',
                'retreat.',
                'denial.',
            ],
            correctIndex: null
        },
    ],
    act3: [
        {
            question: 'According to Passage A, one reason elements of hip-hop culture such as b-boying are rarely represented in mass media is that these art forms:',
            options: [
                'have never been brought to the public\'s attention.',
                'are not bought and sold as products.',
                'do not appeal to young people.',
                'declined in popularity after the 1970s.',
            ],
            correctIndex: null
        },
        {
            question: 'As it is used in the passage, the highlighted word "sensibilities" most nearly means (“this hip-hop features elements of both sensibilities”):',
            options: [
                'emotions.',
                'sensitivities.',
                'perspectives.',
                'feelings of gratitude.',
            ],
            correctIndex: null
        },
        {
            question: 'Based on Passage A, which statement best captures the relationship between Tin Pan Alley pop music and rap music?',
            options: [
                'Rap artists have rejected every aspect of Tin Pan Alley pop.',
                'Rap artists have been aware of Tin Pan Alley pop but not influenced by it.',
                'Tin Pan Alley pop developed at the same time as rap.',
                'Tin Pan Alley pop has influenced many rap artists.',
            ],
            correctIndex: null
        },
        {
            question: 'Which of the following details does the author of Passage B highlight as one that caused "Rapper\'s Delight" to stand out as different compared to other songs he knew?',
            options: [
                'The song\'s intro',
                'The female vocals',
                'The length of the song',
                'The fact that the song was on a vinyl record',
            ],
            correctIndex: null
        },
        {
            question: 'In the context of Passage B, the main point of the highlighted paragraph is that the author was (“But as the intro plays to what I recognize as "Good Times" by the group Chic and I\'m drawn into the living room because it\'s a familiar hit song from the previous summer, I encounter a record on the turntable that defies categorization. Instead of the sweet female lead vocals of that disco smash, I hear something totally different and spot a baby-blue label on the black vinyl record I\'ve never seen before.”):',
            options: [
                'struck by the combination of new and established musical elements in the music he was hearing.',
                'uncomfortable with what he viewed as an unwelcome change to a favorite song.',
                'more interested in an unfamiliar album label than in the new music that was playing.',
                'convinced that the new form of music he was hearing would become more popular than disco.',
            ],
            correctIndex: null
        },
        {
            question: 'Based on Passage B, it can reasonably be inferred that the author views his first exposure to rap music as:',
            options: [
                'memorable but ultimately not very important.',
                'significant for his childhood but less so for his adulthood.',
                'a transformative experience.',
                'a disappointing experience.',
            ],
            correctIndex: null
        },
        {
            question: 'Compared to Passage A, Passage B focuses more on:',
            options: [
                'early hip-hop\'s interaction with the marketplace.',
                'attempts to move hip-hop art into galleries.',
                'the mass media.',
                'the author\'s personal experience.',
            ],
            correctIndex: null
        },
        {
            question: 'Which of the following elements of Passage B is not included in Passage A?',
            options: [
                'A story involving a particular rap song',
                'A discussion of the early days of hip-hop',
                'A mention of the New York City area in the context of hip-hop',
                'An acknowledgment of rap\'s interaction with other musical forms',
            ],
            correctIndex: null
        },
        {
            question: 'The authors of both passages would most likely agree with the idea that early rap music:',
            options: [
                'represented artists\' rejection of the music industry and its practices.',
                'represented a significant development in American popular culture.',
                'was more popular than today\'s rap music.',
                'was slow to find an audience.',
            ],
            correctIndex: null
        },
    ],
    act4: [
        {
            question: 'In the context of the passage, how does the analysis of crocodilian immune system molecules relate to the living fossil theory of crocodilian evolution?',
            options: [
                'The analysis confirms the living fossil theory.',
                'The analysis suggests the living fossil theory is accurate.',
                'The analysis supports the living fossil theory in some ways and does not support the theory in other ways.',
                'The analysis does not support the living fossil theory.',
            ],
            correctIndex: null
        },
        {
            question: 'Which of the following statements best summarizes Oaks\'s analysis of Nile crocodiles\' DNA as it is presented in the highlighted paragraph? (“Oaks also noticed something odd about the DNA samples he had acquired from the iconic Nile crocodiles (Crocodylus niloticus): they did not match up with each other. In fact, the variation between them was great enough to suggest that he was looking at two distinct species. If so, then not only were modern crocodiles much too young to be living fossils, but they had also continued to speciate after diverging from their basal ancestor—something living fossils are not supposed to do. On its own, Oaks\' study was intriguing, but not enough to convince the larger scientific community to cleave the Nile crocodile into two species.”):',
            options: [
                'It suggested that Nile crocodiles are older than what was previously believed, which does not support the living fossil theory of crocodiles.',
                'It suggested that different species of crocodiles do not share a basal ancestor, which the scientific community has confirmed.',
                'It suggested that the analysis was hastily done, which prompted the scientific community to ignore it.',
                'It suggested that the DNA came from two species, which did not support the living fossil theory of crocodiles.',
            ],
            correctIndex: null
        },
        {
            question: 'The main purpose of the highlighted paragraph is to (“DNA analysis of 123 African crocodiles—as well as 57 separate samples from museum specimens, including crocodiles mummified in ancient Egypt—confirmed her suspicion. In a few sections of their respective genomes, all the mild-mannered crocs would have one DNA sequence, and all the typical Nile crocs another. They even had different numbers of chromosomes.”):',
            options: [
                'describe the DNA analysis that confirmed Crocodylus niloticus and Crocodylus suchus were two distinct species.',
                'provide information on the mummification of crocodiles that was pertinent to Hekkala\'s analysis.',
                'explain how Hekkala revolutionized DNA analysis by comparing the DNA of 123 different African crocodiles.',
                'introduce the behavioral differences between Crocodylus niloticus and Crocodylus suchus.',
            ],
            correctIndex: null
        },
        {
            question: 'According to the passage, molecular analysis revealed that immune system molecules from living crocodilian species were similar in:',
            options: [
                'structure and behavior.',
                'color and size.',
                'density and age.',
                'shape and weight.',
            ],
            correctIndex: null
        },
        {
            question: 'In the context of the passage, the highlighted statement mainly serves to (“They were so docile that he and his companions could swim beside them without concern.”):',
            options: [
                'indicate that Klemens and his companions believed that the crocodiles were diseased.',
                'establish the tameness of the crocodiles in the desert oasis.',
                'suggest that Klemens and his companions suspected they were swimming with Crocodylus niloticus.',
                'indicate that the crocodiles in the desert oasis had not yet fully matured.',
            ],
            correctIndex: null
        },
        {
            question: 'According to the passage, after Klemens sent a tissue sample of a perished crocodile to Hekkala, Hekkala then:',
            options: [
                'estimated the crocodile\'s age.',
                'studied the crocodile\'s immune system.',
                'sequenced the crocodile\'s genome.',
                'identified mutations in the crocodile\'s molecular structure.',
            ],
            correctIndex: null
        },
        {
            question: 'In the context of the passage, the detail that Crocodylus niloticus and Crocodylus suchus have different numbers of chromosomes provides support for the claim that the two species:',
            options: [
                'diverged during the Cretaceous.',
                'had similar diets.',
                'did not evolve from the same ancestor.',
                'were not mixing their DNA.',
            ],
            correctIndex: null
        },
        {
            question: 'According to the passage, Crocodylus niloticus and Crocodylus suchus diverged between:',
            options: [
                '1 and 2 million years ago.',
                '3 and 6 million years ago.',
                '8 and 13 million years ago.',
                '66 and 145 million years ago.',
            ],
            correctIndex: null
        },
        {
            question: 'Based on the passage, the phrase "redraw the map" (highlighted text) is most likely meant to be read (“redraw the map”):',
            options: [
                'literally; scientists no longer believed crocodiles originated in Africa.',
                'literally; scientists no longer believed crocodiles once lived in a band of tropics.',
                'figuratively; scientists amended the narrative of the natural history of crocodiles.',
                'figuratively; scientists believed their findings would have broader implications on archaeology.',
            ],
            correctIndex: null
        },
    ],
    act5: [
        {
            question: 'In the context of Passage A, the event described in the highlighted paragraph most nearly serves to (“Six years ago, I was with my son, who was ten at the time, and we were on our way to his school when I saw an entire stack of newspapers go up into the air, a trashy celebration!”):',
            options: [
                'provide an anecdote that illustrates the power of the wind in Brooklyn.',
                'describe the newspaper seller\'s amusement as the papers were tossed about by the wind.',
                'recount an experience that left the narrator wary of the wind in Brooklyn.',
                'suggest that there are areas of Brooklyn that are intolerable because of the wind.',
            ],
            correctIndex: null
        },
        {
            question: 'Which of the following statements best captures how the narrator of Passage A feels about the way his children might perceive the Brooklyn wind?',
            options: [
                'He suspects the wind annoys them and assumes they take measures to avoid it.',
                'He hopes they share his interest in the wind and seek it out themselves.',
                'He feels they don\'t appreciate the wind or other facets of nature as much as they should.',
                'He hopes they notice how calm Brooklyn can be when the wind is not blowing.',
            ],
            correctIndex: null
        },
        {
            question: 'According to the narrator of Passage A, the branches of the London plane tree near the Court-Montague Building are notable for:',
            options: [
                'their exceptional length and graceful shape.',
                'the fact that they don\'t have plastic shopping bags clinging to them.',
                'the sound they make when the wind whips through them.',
                'their ability to provide shade for the nearby farmer\'s market.',
            ],
            correctIndex: null
        },
        {
            question: 'According to the narrator of Passage B, some manhole covers she encountered as a child were rubbed smooth partly because of:',
            options: [
                'the metal-wheeled vehicles of Brooklyn\'s past.',
                'urban renewal projects over many decades.',
                'road resurfacing methods that were unduly destructive.',
                'centuries of foot traffic at Brooklyn\'s intersections.',
            ],
            correctIndex: null
        },
        {
            question: 'It can reasonably be inferred from Passage B that one result of the excursions the narrator took around Brooklyn with her mother was the narrator\'s:',
            options: [
                'lifelong commitment to urban renewal and preservation.',
                'increased appreciation for the history of other American cities.',
                'fuller notion of what her city was like during different eras.',
                'decision to expose her own children to art museums.',
            ],
            correctIndex: null
        },
        {
            question: 'Both passages are told from the point of view of narrators who:',
            options: [
                'grew up learning about Brooklyn from their parents.',
                'try to imagine how Brooklyn might be perceived by tourists.',
                'illustrate their relationship with Brooklyn through family experiences.',
                'were raised in Brooklyn but have since gone on to live in other cities.',
            ],
            correctIndex: null
        },
        {
            question: 'The tone of both passages can best be described as a combination of:',
            options: [
                'humor and relief.',
                'doubt and hesitancy.',
                'introspection and regret.',
                'wonder and nostalgia.',
            ],
            correctIndex: null
        },
        {
            question: 'Which of the following quotations from Passage B is most closely related to the themes in Passage A?',
            options: [
                '"My parents, as artists, were eager to have their children out discovering beauty in the pedestrian, complexity in the mundane" (highlighted text).',
                '"We didn\'t have to behave" (highlighted text).',
                '"My parents believed that embedding beautiful designs in the asphalt and the sidewalks was a quintessentially democratic, political act" (highlighted text).',
                '"To me, the very idea of street furniture was thrilling" (highlighted text).',
            ],
            correctIndex: null
        },
        {
            question: 'The reference to Cranberry Street in Passage A and the reference to streets paved with Belgian blocks in Passage B both serve to:',
            options: [
                'evoke historical details in order to provide a better understanding of Brooklyn.',
                'argue that history tends to be more appealing to adults than to children.',
                'illustrate how difficult it is to unearth details about Brooklyn\'s past.',
                'suggest that living in Brooklyn was more rewarding in certain historical eras than it is now.',
            ],
            correctIndex: null
        },
    ],
    act6: [
        {
            question: 'The highlighted paragraph marks a shift in the passage from (“Concern about lawns has sparked a great deal of debate, creative thought, and neighbor-to-neighbor strife. In 1991, a savvy group of graduate students and faculty from Yale University\'s School of Forestry and Environmental Studies joined their colleagues in the School of Art and Architecture to consider how Americans could redesign their lawns.”):',
            options: [
                'an argument that condemns the modern lawn to a counterargument that focuses on its benefits.',
                'an explanation of the drawbacks of the modern lawn to a description of a more environmentally friendly alternative to it.',
                'a history of the popularity of lawns to a description of typical features of the modern lawn.',
                'an overview of a debate between homeowners and environmentalists about the purpose of lawns to a plea for homeowners to stop mowing.',
            ],
            correctIndex: null
        },
        {
            question: 'Based on the passage, who would most fully endorse the claim that lawns are particularly valuable for creating wide-open areas of green space that foster a feeling of community?',
            options: [
                'The Yale graduate students and faculty mentioned in the passage',
                'The passage author',
                'Olmsted',
                'Pollan',
            ],
            correctIndex: null
        },
        {
            question: 'What reason does the passage author give to bolster his claim that "domination of suburbia by lawn constrains the diversity of birds that could be supported" (highlighted text)?',
            options: [
                'Robins, starlings, crows, wagtails, and oystercatchers make use of lawns.',
                'The ubiquity of the lawn has outstripped its benefits.',
                'Birds don\'t carry out any life functions in the modern lawn other than foraging.',
                'Some people see lawns as a way to gain prestige.',
            ],
            correctIndex: null
        },
        {
            question: 'The passage most strongly suggests that the gradual diversification of plant composition in a Freedom Lawn leads to:',
            options: [
                'native, beneficial insects being drawn to the lawn.',
                'native plants spreading to areas several miles away from the lawn.',
                'birds enjoying the nest sites that humans have constructed within the lawn.',
                'one or two plants becoming dominant in the lawn.',
            ],
            correctIndex: null
        },
        {
            question: 'The passage author most strongly suggests that American homeowners who grow shaggy lawns likely feel the most immediate pressure from which of the following circumstances?',
            options: [
                'The awareness that their actions might lead to corporate losses',
                'The wasted expense of the lawn equipment they already own',
                'The need to cancel their lawn care service',
                'The disapproval of their neighbors',
            ],
            correctIndex: null
        },
        {
            question: 'The main point of the highlighted paragraph is that (“Those who adopt Freedom Lawns buck a multinational industry heavily invested in producing seed, sod, fertilizer, pesticide, irrigation and lawn equipment, and service for those twenty-six million American homes that contract out their lawn care.”):',
            options: [
                'adopting a Freedom Lawn can arguably be a bold political and social act.',
                'the biggest benefit of adopting a Freedom Lawn is being able to buck a multinational industry.',
                'a neighborhood takes on a carefree feel when homeowners adopt a Freedom Lawn.',
                'it isn\'t logical to reject civic duty simply for the sake of adopting a Freedom Lawn.',
            ],
            correctIndex: null
        },
        {
            question: 'The passage author includes the quotation by Pollan (highlighted text) mainly to:',
            options: [
                'explain why some neighbors gladly accept other neighbors\' shaggy lawns.',
                'cautiously suggest that suburbanites often refuse to perform their civic duties.',
                'slightly mock the suburban ideals that have led to the proliferation of the modern lawn.',
                'illustrate how appealing a shaggy lawn looks next to a perfectly mowed lawn.',
            ],
            correctIndex: null
        },
        {
            question: 'What evidence, if accurate, would best support the passage author\'s claim that "our love of lawn is rooted in our history as a former British colony" (highlighted text)?',
            options: [
                'Kentucky bluegrass, native to several countries, is a common species of grass for lawns in the United States.',
                'For generations in Britain, a trimmed lawn was a popular status symbol, showing that a homeowner could afford to own land that was not farmed.',
                'Many of the first lawns in Britain were sculpted to include low mounds where people could sit, though these makeshift benches were rarely used.',
                'Front lawns became popular in the United States in the 1930s, when lawn maintenance became easier.',
            ],
            correctIndex: null
        },
        {
            question: 'Which of the following lists captures features of a Freedom Lawn as it is described in the passage?',
            options: [
                'Formed of native and nonnative grasses, shaded by trees, large in size',
                'Treated with pesticides, bordered by trees, limited in size',
                'Unshaded, bordered by short grasses, mowed with a hand-powered mower',
                'Bordered by shrubs, unfertilized, shaded by trees',
            ],
            correctIndex: null
        },
    ],
    act7: [
        {
            question: 'In the context of the passage, the main function of the highlighted paragraph is to (“A Madagascan bark spider releases a silk dragline into the air. The wind carries the thin threads to the other side of a river, where they land on foliage on the opposite bank 25 metres away.”):',
            options: [
                'provide an overview of the internal process that enables spiders to produce different types of silk.',
                'illustrate the strength and versatility of spider silks by describing how one particular spider uses its silks to create a web.',
                'introduce the idea that spiders are resourceful by describing the obstacles they encounter when producing silks for their webs.',
                'point out that the properties of silks made by spiders are similar to those of silks made by other animals.',
            ],
            correctIndex: null
        },
        {
            question: 'According to the passage, how does the bark spider establish tension in its bridgeline?',
            options: [
                'It drops the bridgeline into water.',
                'It reinforces the bridgeline with silk.',
                'It adds dirt to the bridgeline.',
                'It stretches the bridgeline.',
            ],
            correctIndex: null
        },
        {
            question: 'In the context of the passage, the highlighted statement can best be described as (“C. darwini\'s bridging silk is the world\'s toughest known biomaterial—it is even tougher than steel fibre.”):',
            options: [
                'a claim asserted by several researchers but contradicted by the passage author.',
                'a fact the passage author supports by citing the variety of silks other spiders can produce.',
                'a reasoned judgment based on the passage author\'s understanding of how spiders produce silks.',
                'an opinion the passage author presents but offers no support for.',
            ],
            correctIndex: null
        },
        {
            question: 'According to the passage, how many different kinds of silk proteins can an individual spider make?',
            options: [
                'No more than two',
                'As many as six',
                'More than twenty-five',
                'About four hundred',
            ],
            correctIndex: null
        },
        {
            question: 'It can reasonably be inferred from the passage that the author uses the highlighted word "stretch" mainly to (“which is not too far of a stretch from reality”):',
            options: [
                'reinforce an idea in the passage with a humorous play on words.',
                'emphasize the elaborate nature of some spiderwebs.',
                'suggest the passage\'s representation of spiderwebs may be slightly exaggerated.',
                'criticize the movie\'s lack of authenticity.',
            ],
            correctIndex: null
        },
        {
            question: 'Based on the highlighted text and the table, which of the following statements is accurate?',
            options: [
                'High-tensile steel fiber requires much less energy to break than the bark spider\'s silk does.',
                'Only the silver garden spider\'s flag silk requires more energy to break than the domestic silkworm\'s silk does.',
                'Synthetic fibers like Kevlar 49 require much more energy to break than natural fibers like silk do.',
                'Nylon fiber requires the same amount of energy to break as carbon fiber does.',
            ],
            correctIndex: null
        },
        {
            question: 'Based on the passage and the table, does the information in the table support the passage\'s claim about how the bark spider\'s silk compares to steel fiber?',
            options: [
                'Yes, because while the table indicates the bark spider\'s silk is not as strong as steel fiber, the bark spider\'s silk is slightly tougher.',
                'Yes, because the table indicates the toughness of the bark spider\'s silk far exceeds the toughness of steel fiber.',
                'No, because the table indicates the toughness of steel fiber is approximately the same as the toughness of the bark spider\'s silk.',
                'No, because the table indicates steel fiber is tougher than the bark spider\'s silk.',
            ],
            correctIndex: null
        },
        {
            question: 'Based on the table, which of the following pairs of materials are most different in terms of elasticity?',
            options: [
                'Silver garden spider flag silk and high-tensile steel fiber',
                'Silver garden spider flag silk and Kevlar 49 fiber',
                'Domestic silkworm silk and nylon fiber',
                'Kevlar 49 fiber and carbon fiber',
            ],
            correctIndex: null
        },
        {
            question: 'According to the table, compared to the silver garden spider\'s flag silk, the domestic silkworm\'s silk has:',
            options: [
                'less strength and less elasticity.',
                'greater toughness and greater strength.',
                'greater strength but less toughness.',
                'less strength but greater elasticity.',
            ],
            correctIndex: null
        },
    ],
    act8: [
        {
            question: 'It can reasonably be inferred that the passage author viewed the Sundance executives\' claim in the highlighted text as (“We really do want Native American participation”):',
            options: [
                'a signal that the meeting would be productive.',
                'a long-overdue promise that would result in more support for Native films.',
                'evidence that the executives favored Native films over conventional "Hollywood" films.',
                'an assurance that, while well-meaning, felt hollow.',
            ],
            correctIndex: null
        },
        {
            question: 'The passage author indicates that in order to become more active participants in the Sundance Festival, Native filmmakers were most in need of:',
            options: [
                'greater funding for the production of big-budget Native films.',
                'a decision-making voice within the Sundance Institute.',
                'training in the Sundance Institute\'s film promotional practices.',
                'an opportunity to screen Native films internationally.',
            ],
            correctIndex: null
        },
        {
            question: 'Which of the following statements best summarizes the excerpt from Hearne in the highlighted text? (“The film can be seen as a landmark "first" in American film history—although it is important to remember the long history of Native filmmaking that came before Smoke Signals—and it can also be seen as a self-positioned first introduction to Native perspectives and Native filmmaking for many of its viewers.”):',
            options: [
                'Smoke Signals grapples with themes of Native identity and was created to reach younger generations of Native Americans.',
                'Native films like Smoke Signals are important because they are marketed in the mainstream film industry.',
                'Smoke Signals is one film in a long line of Native films but was revolutionary in its presentation of Native Americans and advancement of Native filmmaking.',
                'Those who view Smoke Signals as a landmark Native film in American film history often forget Native films\' long history and impact on American cinema.',
            ],
            correctIndex: null
        },
        {
            question: 'Based on the passage, the passage author would most likely agree that Hearne\'s review of Smoke Signals:',
            options: [
                'helped promote the film during its first release.',
                'tried to cover too many aspects of the film.',
                'came too late to be meaningful.',
                'is both thorough and insightful.',
            ],
            correctIndex: null
        },
        {
            question: 'According to the passage, in their 1997 meeting with Native filmmakers, Sundance executives were primarily interested in making Native films:',
            options: [
                'competitive with other films promoted by the Sundance Institute.',
                'more artistically inventive than films featured at other festivals.',
                'an integral part of the Sundance Institute\'s initiative to reinvent its brand.',
                'adaptable to various formats to allow for easy distribution.',
            ],
            correctIndex: null
        },
        {
            question: 'The passage author describes the conversation between Native filmmakers and Sundance executives as "wavering" (highlighted text) primarily to make clear that, up to that point, the meeting had:',
            options: [
                'been poorly managed and was behind schedule.',
                'inspired deliberation and debate among the filmmakers.',
                'become awkward due to the executives\' reluctance to include more Native films in the festival.',
                'meandered in topic and somewhat lacked focus.',
            ],
            correctIndex: null
        },
        {
            question: 'As it is used in the passage, the highlighted phrase "held by" most nearly means (“the power held by the Sundance Festival”):',
            options: [
                'wielded by.',
                'within reach of.',
                'perceived of.',
                'supported by.',
            ],
            correctIndex: null
        },
        {
            question: 'It can reasonably be inferred from the passage that the Sundance Institute\'s decision to hire someone like Rae was the result of a suggestion from:',
            options: [
                'Farmer.',
                'Alexie.',
                'the passage author.',
                'a Sundance executive.',
            ],
            correctIndex: null
        },
        {
            question: 'In the context of the passage, the main purpose of the highlighted paragraph is to (“Although the film\'s glow has receded somewhat, the direction of Native American filmmaking has led to measurable success and growth internationally.”):',
            options: [
                'revisit the success Smoke Signals experienced at its release.',
                'note the success within Native American filmmaking since the release of Smoke Signals.',
                'illustrate the measurable growth of international films similar to Smoke Signals.',
                'highlight the powerful role the Sundance Festival played in producing Smoke Signals.',
            ],
            correctIndex: null
        },
    ],
};