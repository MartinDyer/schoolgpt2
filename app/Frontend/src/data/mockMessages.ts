import { Message } from "@/components/ChatMessage";

export const mockMessages: Message[] = [
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
];