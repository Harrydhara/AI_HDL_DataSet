# AI Strategy and Usage Plan

## Tool Selection
- **Primary AI Tool**: Opus 4.5
- **Reason**: Strong reasoning capabilities for hardware design and SystemVerilog
- **Backup Tools**: ChatGPT 5.2 Thinking AND Gemini Pro 3.0 for alternative perspectives when needed

## Logging Approach
- All AI prompts and responses saved in `prompt_logs/`
- Markdown format for readability and version control

## Integration Strategy
### What AI Will Help With:
- Initial design generation and module structure
- Debugging synthesis and simulation errors
- Code optimization suggestions
- Testbench development
- Documentation assistance
- Give us some bash commands when we got error

### What We Handle Manually:
- Final design decisions and trade-offs
- Code review and verification
- Custom modifications for our specific requirements
- Using developed testbenchs to testing RTL's
- Yosys synthesize and verification

## Prompting Techniques
1. **Clear specifications**: Provide exact requirements upfront
2. **Draw a line**: State your request and add: "Don't change anything else"
3. **Ask for explanations**: Request reasoning behind design choices
4. **Feedback and step by step focus**: Request to change just one module which we was working on the moment
5. **Validation focus**: After creating all RTLs, request a test environment for each one individually
6. **Iterative refinement**: Create, test; recreate if faulty

## Learning Goals
- Understand HDL design patterns, not just copy code
- Learn synthesis implications of design choices
- Develop debugging skills with AI assistance
- Build confidence in hardware design methodology
