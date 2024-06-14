--!Type(Module)

local questions = {
    -- Ice Breakers (Simple, fun questions to start the conversation.)
    "What is your real name?",
    "What is your age?",
    "Where do you live?",
    "How is the weather where you live?",
    -- General , experiences, preferences, hobbies, interests, values, beliefs , habits and growth
    "How do you de-stress?",
    "Do you prefer to drive or sit in the passenger seat?",
    "What do you do typically on a weekend?",
    "What's your biggest pet peeve",
    "What can easily make you angry?",
    "Have you ever met anyone famous?",
    "What is the most difficult task you have ever completed?",
    "What habit would you most like to change?",
    "If you could eliminate one thing from your daily routine forever, what would it be?",
    "What's one life hack you've discovered that helped you a lot",
    "What's the weirdest thing you've seen happened to someone or yourself?",
    "What's your favorite way to spend a weekend?",
    "What is one thing on your bucket list?",
    "Can you share an interesting quote or saying?",
    "Do you prefer mornings or evenings?",
    "What's your favorite childhood cartoon?",
    "What's your favorite thing to do with friends?",
    "What's something you've always wanted to learn or try?",
    -- Books and Literature ( Questions about favorite books, authors, and reading habits.)
    "What is your all time favorite book",
    "What book are you reading at the moment?",
    "What is your favorite book genre?",
    -- Movies
    "What is your all time favorite movie?",
    "What is your favorite movie genre?",
    -- Movies and TV Shows
    "What is your all time favourite TV Show?",
    "Which is the last Netflix series you watched?",
    -- Music
    "What kind of music do you like?",
    "Give me your top three music artists",
    -- Infotaintment 
    "Do you enjoy listening to podcasts? If yes, which ones?",
    -- Technology and Gadgets (Questions about their favorite tech, gadgets they can't live without, and views on future tech trends.)
    "What is your current favorite app on your phone?",
    -- Games
    "What is your favorite tabletop game?",
    "What is your favorite mobile game?",
    "What is your favorite pc game?",
    -- Travel and Adventure (Questions about places they've been, places they want to go, and travel experiences.)
    "Where did you last travel to?",
    "If you have to choose a vactation destination, where would you like to travel to?",
    "What's the most adventurous thing you've ever done?",
    "If you could live in any city in the world, where would you live?",
    "What's the most reckless thing you've ever done?",
    "What's the most interesting place you've visited?",
    -- What if
    "If you could be any fictional character, who would you be?",
    "If you were a superhero, what would your superpower be?",
    "If you could be any person for a day, who would you choose and why?",
    "If you won the lottery how would you spend it?",
    "If I come to your house, what would you cook for me?",
    "If you had the chance to be on the first human mission to mars, would you go?",
    "Who would you want to be stuck with on an island?",
    "If you could meet any celebrity, who would it be?",
    "If you could have a superpower for a day, what would it be?",
    "If you could visit any planet safely, which one would you choose?",
    "If you could invent a holiday, what would it be?",
    "If you could be an expert in any field, what would it be?",
    "If you could visit any fictional world, where would you go?",
    "What if you could meet any historical figure, who would you choose?",
    "What if you could change one thing about the world, what would it be?",
    "If you could buy one thing, no matter the price, what would you buy?",
    -- Would you rather
    "Would you rather go scuba diving or skydiving?",
    "Would you rather time travel to the past or to the future",
    "Would you rather shop online or at the mall?",
    "Which do you prefer mountains or beaches?",
    "Summers or winters?",
    "Do you like to call or text?",
    "Would you rather have a partner with a great sense of humor or a partner who is super attractive?",
    "Would you rather be single or in a relationship",
    "Would you rather be able to breathe underwater or fly?",
    "Would you rather live in a world with no crime or no privacy?",
    "Would you rather lose all your money or your memories",
    "Would you rather be an average person in the present or a king of a large country 2500 years ago?",
    "Would you rather have an easy job working for someone else or work for yourself but work incredibly hard?",
    "Would you rather never be able to eat meat or never be able to eat vegetables?",
    "Would you rather find your true love or a suitcase with five million dollars inside?",
    "Would you rather live without the internet or live without air conditioning and heating?",
    "Would you rather never be stuck in traffic again or never get another cold?",
    -- Food and Drink (Questions about culinary preferences, cooking skills, and favorite cuisines.)
    "What's your favorite type of cuisine?",
    "What's the weirdest food you've ever tried?",
    "What is your favorite food?",
    "Coffee or tea?",
    "Do you prefer vanilla or chocolate?",
    "What's your favorite ice cream flavor?",
    "What's your favorite type of dessert?",
    "What's your favorite thing to cook or bake?",
    "What's the best thing that you can cook?",
    "What's your favorite fruit?",
    -- Funny and Lighthearted (Questions intended to make each other laugh and have a good time.)
    "What's the funniest joke you've heard",
    "Would you rather be forced to dance every time you heard music or be forced to sing along to any song you heard?",
    -- Work and Career (Questions about their job, career goals, and professional experiences.)
    "What is your dream job?",
    -- Sports and Fitness (Questions about favorite sports, fitness routines, and athletic achievements.)
    "Which is your favorite sport?",
    "What's your favorite outdoor activity?",
    -- Health and Wellness (Questions about personal health practices, wellness routines, and mental health.)
    -- Art and Creativity (Questions about artistic interests, creative projects, and favorite artists or works of art.)
    "Do you play any musical instrument?",
    -- History (Questions about historical interests, favorite historical periods, and influential figures.)
    -- Politics and social issues (Questions about their views on current events, social issues, and societal trends)
    "Do you follow politics?",
    -- Science
    --  Pick-up lines
    -- Relationship and love (Questions about past relationships, views on love, and what they look for in a partner,family dynamics, friendships.)
    "What's the most important lesson you've learned from a past relationship?",
    "Do you believe in love at first sight?",
    "Do you believe in a long-term relationship or short-term flings?",
    "What interests you most in a person?",
    -- Pets
    "Do you prefer cats or dogs?",
    "Do you have any pets?",
    -- Psychology
    -- Spirituality (Questions about their spiritual beliefs, religious practices, and personal faith.)
    -- Horror and supernatural ( Questions about superstitions, paranormal experiences, and unique beliefs.)
    -- Philosophy (Questions that delve into deeper philosophical discussions and existential topics.)
    -- Fashion and Style (Questions about fashion preferences, personal style, and fashion trends.)
    -- Languages and Cultures (Questions about languages they speak or want to learn, and cultural interests.)
    "How many languages do you speak?",
}

function GetQuestions()
    return questions
end