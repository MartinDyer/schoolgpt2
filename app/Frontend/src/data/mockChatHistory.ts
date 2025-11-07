import { Message } from "@/components/ChatMessage";

export interface ChatHistory {
  id: string;
  title: string;
  preview: string;
  updatedAt: Date;
  messageCount: number;
  messages: Message[];
}

export const mockChatHistory: ChatHistory[] = [
  {
    id: "chat-1",
    title: "Python Programming Basics",
    preview: "Tell me the basics about python development",
    updatedAt: new Date("2024-01-15T10:32:30Z"),
    messageCount: 4,
    messages: [
      {
        id: "1",
        content: "Tell me the basics about python development",
        role: "user",
        timestamp: new Date("2024-01-15T10:30:00Z")
      },
      {
        id: "2",
        content: `Python is a high-level, interpreted programming language known for its simplicity and readability. Here are some basics about Python development:

1. **Syntax**: Python uses a clean and easy-to-read syntax, making it a great choice for beginners and experienced developers alike.

2. **Interpreted**: Python code is executed line by line by the Python interpreter, which makes it easier to test and debug code.

3. **Versatile**: Python can be used for a wide range of applications, including web development, data analysis, machine learning, automation, and more.

4. **Libraries**: Python has a vast ecosystem of libraries and frameworks that make it easy to build complex applications quickly. Some popular libraries include NumPy, pandas, and TensorFlow.

5. **Community**: Python has a large and active community of developers who contribute to its growth and provide support through forums, conferences, and online resources.

These features make Python an excellent choice for students learning programming and for building various types of projects.`,
        role: "assistant",
        timestamp: new Date("2024-01-15T10:30:15Z")
      },
      {
        id: "3",
        content: "What are some good beginner projects I can build with Python?",
        role: "user",
        timestamp: new Date("2024-01-15T10:32:00Z")
      },
      {
        id: "4",
        content: `Here are some great beginner Python projects that will help you practice and learn:

**Simple Console Programs:**
- Calculator with basic operations
- Number guessing game
- To-do list manager
- Password generator
- Rock, Paper, Scissors game

**Data Projects:**
- Grade calculator for your classes
- Simple expense tracker
- Weather data analyzer
- Basic quiz application

**Fun Projects:**
- Hangman word game
- Simple chatbot
- Dice rolling simulator
- Basic text-based adventure game

**Practical Tools:**
- File organizer (sorts files by type)
- Simple timer or stopwatch
- Basic unit converter

Start with the console programs as they help you understand Python basics like variables, loops, and functions. Once you're comfortable, move on to the data projects to learn about working with files and user input.

Remember to break each project into small steps and don't worry if your first attempts aren't perfect - that's how you learn!`,
        role: "assistant",
        timestamp: new Date("2024-01-15T10:32:30Z")
      }
    ]
  },
  {
    id: "chat-2",
    title: "Mathematics Help - Algebra",
    preview: "Can you help me understand quadratic equations?",
    updatedAt: new Date("2024-01-14T15:45:00Z"),
    messageCount: 6,
    messages: [
      {
        id: "1",
        content: "Can you help me understand quadratic equations?",
        role: "user",
        timestamp: new Date("2024-01-14T15:40:00Z")
      },
      {
        id: "2",
        content: `Absolutely! Quadratic equations are polynomial equations of degree 2. They have the general form:

**ax² + bx + c = 0**

Where:
- a, b, and c are constants (a ≠ 0)
- x is the variable we're solving for

Key characteristics:
- The graph of a quadratic equation is a parabola
- They can have 0, 1, or 2 real solutions
- The highest power of the variable is 2

Would you like me to show you how to solve them using different methods?`,
        role: "assistant",
        timestamp: new Date("2024-01-14T15:40:30Z")
      }
    ]
  },
  {
    id: "chat-3",
    title: "Science Project Ideas",
    preview: "I need ideas for my science fair project",
    updatedAt: new Date("2024-01-13T09:20:00Z"),
    messageCount: 8,
    messages: [
      {
        id: "1",
        content: "I need ideas for my science fair project",
        role: "user",
        timestamp: new Date("2024-01-13T09:15:00Z")
      },
      {
        id: "2",
        content: `Great! Science fair projects are exciting opportunities to explore your interests. Here are some engaging ideas across different fields:

**Physics Projects:**
- Build a simple electric motor
- Test how different materials affect sound absorption
- Investigate the relationship between pendulum length and period

**Chemistry Projects:**
- Test the pH of household items
- Create natural indicators using red cabbage
- Compare the effectiveness of different cleaning agents

**Biology Projects:**
- Study plant growth under different light conditions
- Test how temperature affects enzyme activity
- Investigate which environments grow the most bacteria

**Environmental Science:**
- Test water quality from different sources
- Study the effect of pollution on plant growth
- Compare renewable vs non-renewable energy efficiency

What subject interests you most? I can provide more specific guidance based on your preferences!`,
        role: "assistant",
        timestamp: new Date("2024-01-13T09:15:45Z")
      }
    ]
  },
  {
    id: "chat-4",
    title: "History Essay Help",
    preview: "How do I structure an essay about World War II?",
    updatedAt: new Date("2024-01-12T14:30:00Z"),
    messageCount: 5,
    messages: [
      {
        id: "1",
        content: "How do I structure an essay about World War II?",
        role: "user",
        timestamp: new Date("2024-01-12T14:25:00Z")
      },
      {
        id: "2",
        content: `Excellent question! A well-structured World War II essay should have a clear organization. Here's a suggested structure:

**Introduction (1 paragraph):**
- Hook: Start with an interesting fact or question
- Background: Brief context about the war
- Thesis statement: Your main argument or focus

**Body Paragraphs (3-4 paragraphs):**
- Topic sentence for each main point
- Evidence from reliable sources
- Analysis of how this supports your thesis
- Transition to the next point

**Possible topics to focus on:**
- Causes of the war
- Major battles or turning points
- Home front experiences
- Technological developments
- Impact on specific groups or countries

**Conclusion (1 paragraph):**
- Restate your thesis
- Summarize key points
- Discuss the war's lasting impact

What specific aspect of WWII are you planning to focus on? This will help me give you more targeted advice!`,
        role: "assistant",
        timestamp: new Date("2024-01-12T14:25:30Z")
      }
    ]
  },
  {
    id: "chat-5",
    title: "Literature Analysis",
    preview: "Can you help me analyze themes in To Kill a Mockingbird?",
    updatedAt: new Date("2024-01-11T16:15:00Z"),
    messageCount: 7,
    messages: [
      {
        id: "1",
        content: "Can you help me analyze themes in To Kill a Mockingbird?",
        role: "user",
        timestamp: new Date("2024-01-11T16:10:00Z")
      },
      {
        id: "2",
        content: `Certainly! "To Kill a Mockingbird" by Harper Lee contains several important themes that are still relevant today. Here are the major ones:

**1. Prejudice and Racism**
- The trial of Tom Robinson illustrates systemic racism
- Shows how prejudice affects judgment and justice
- Explores both explicit and subtle forms of discrimination

**2. Moral Courage**
- Atticus defending Tom Robinson despite social pressure
- Mrs. Dubose overcoming her addiction
- Boo Radley protecting the children

**3. Loss of Innocence**
- Scout and Jem's growing understanding of their community's flaws
- The children's evolving perception of Boo Radley
- Witnessing injustice firsthand

**4. Social Class and Inequality**
- The Cunninghams vs. the Ewells
- Different social expectations and opportunities
- How economic status affects treatment in society

Which theme would you like to explore in more depth for your analysis?`,
        role: "assistant",
        timestamp: new Date("2024-01-11T16:10:45Z")
      }
    ]
  }
];