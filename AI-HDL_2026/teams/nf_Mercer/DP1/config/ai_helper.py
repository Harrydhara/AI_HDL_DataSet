from openai import OpenAI
import json
from datetime import datetime

class AIHDLHelper:
    def __init__(self, api_key=None):
        self.client = OpenAI(api_key=api_key) if api_key else OpenAI()
    
    def log_conversation(self, prompt, response_text, model="gpt-5-nano"):
        log_entry = {
            "timestamp": datetime.now().isoformat(),
            "model": model,
            "prompt": prompt,
            "response": response_text
        }

        with open("ai_log.jsonl", "a") as f:
            f.write(json.dumps(log_entry) + "\n")
    
    def generate_verilog(self, description):
        prompt = f"""
        Generate Verilog code for: {description}

        Requirements:
        - Include proper module declaration
        - Add comprehensive comments
        - Follow good coding practices
        - Include basic testbench if appropriate
        """

        response = self.client.responses.create(
            model="gpt-5-nano",
            input=prompt
        )

        # Extract the text response
        verilog_text = response.output_text

        # Log the interaction
        self.log_conversation(prompt, verilog_text)

        return verilog_text
